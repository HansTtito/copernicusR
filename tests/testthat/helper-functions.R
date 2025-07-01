# Función para limpiar completamente el estado de credenciales
complete_cleanup <- function() {
  # Limpiar opciones de sesión
  options(copernicus.username = NULL)
  options(copernicus.password = NULL)

  # Limpiar variables de entorno
  Sys.unsetenv("COPERNICUS_USERNAME")
  Sys.unsetenv("COPERNICUS_PASSWORD")

  # Limpiar ambiente interno del paquete
  tryCatch({
    copernicus_env <- .copernicus_env()
    if (exists("cm", envir = copernicus_env)) {
      rm("cm", envir = copernicus_env)
    }
    if (exists("credentials", envir = copernicus_env)) {
      rm("credentials", envir = copernicus_env)
    }
  }, error = function(e) {
    # Silently ignore if environment doesn't exist
  })

  invisible(NULL)
}

# Función de diagnóstico para encontrar dónde persisten las credenciales
debug_persistent_credentials <- function() {
  cat("\n=== DEBUGGING PERSISTENT CREDENTIALS ===\n")

  # 1. Opciones de sesión
  cat("1. Session options:\n")
  cat("   copernicus.username:", getOption("copernicus.username", "NULL"), "\n")
  cat("   copernicus.password:", if(is.null(getOption("copernicus.password"))) "NULL" else "***SET***", "\n")

  # 2. Variables de entorno
  cat("2. Environment variables:\n")
  cat("   COPERNICUS_USERNAME:", Sys.getenv("COPERNICUS_USERNAME", "NOT_SET"), "\n")
  cat("   COPERNICUS_PASSWORD:", if(nzchar(Sys.getenv("COPERNICUS_PASSWORD"))) "***SET***" else "NOT_SET", "\n")

  # 3. Todas las opciones que contengan "copernicus"
  cat("3. All copernicus options:\n")
  all_opts <- options()
  copernicus_opts <- all_opts[grepl("copernicus", names(all_opts), ignore.case = TRUE)]
  if (length(copernicus_opts) > 0) {
    for (name in names(copernicus_opts)) {
      cat("   ", name, ":", copernicus_opts[[name]], "\n")
    }
  } else {
    cat("   No copernicus options found\n")
  }

  # 4. Variables de entorno que contengan "COPERNICUS"
  cat("4. All COPERNICUS environment variables:\n")
  all_env <- Sys.getenv()
  copernicus_env_vars <- all_env[grepl("COPERNICUS", names(all_env), ignore.case = TRUE)]
  if (length(copernicus_env_vars) > 0) {
    for (name in names(copernicus_env_vars)) {
      value <- if(nzchar(copernicus_env_vars[[name]])) "***SET***" else "EMPTY"
      cat("   ", name, ":", value, "\n")
    }
  } else {
    cat("   No COPERNICUS environment variables found\n")
  }

  # 5. Resultado de copernicus_get_credentials
  cat("5. copernicus_get_credentials result:\n")
  tryCatch({
    creds <- copernicus_get_credentials(mask_password = FALSE)
    cat("   username:", creds$username %||% "NULL", "\n")
    cat("   password:", if(is.null(creds$password)) "NULL" else "***SET***", "\n")
  }, error = function(e) {
    cat("   ERROR:", e$message, "\n")
  })

  # 6. Ambiente interno del paquete
  cat("6. Internal package environment:\n")
  tryCatch({
    copernicus_env <- .copernicus_env()
    objects_in_env <- ls(envir = copernicus_env)
    cat("   Objects in copernicus env:", paste(objects_in_env, collapse = ", "), "\n")

    # Buscar credenciales almacenadas
    if ("credentials" %in% objects_in_env) {
      cat("   Found 'credentials' object in internal env\n")
    }
  }, error = function(e) {
    cat("   ERROR accessing internal env:", e$message, "\n")
  })

  # 7. Verificar si hay archivo .Renviron en el directorio del proyecto
  cat("7. Local .Renviron files:\n")
  if (file.exists(".Renviron")) {
    cat("   Found .Renviron in current directory\n")
    # No leer el contenido por seguridad, solo reportar que existe
  } else {
    cat("   No .Renviron in current directory\n")
  }

  home_renviron <- file.path(Sys.getenv("HOME"), ".Renviron")
  if (file.exists(home_renviron)) {
    cat("   Found .Renviron in home directory\n")
  } else {
    cat("   No .Renviron in home directory\n")
  }

  cat("=========================================\n\n")
}

# Wrapper para tests que requieren estado absolutamente limpio
test_with_clean_state <- function(desc, code) {
  test_that(desc, {
    # Múltiples niveles de limpieza
    complete_cleanup()

    # Usar withr para máximo aislamiento
    withr::with_options(
      list(copernicus.username = NULL, copernicus.password = NULL),
      withr::with_envvar(
        c(
          COPERNICUS_USERNAME = NA,
          COPERNICUS_PASSWORD = NA
        ),
        {
          # Verificar que realmente está limpio
          expect_null(getOption("copernicus.username"))
          expect_null(getOption("copernicus.password"))
          expect_equal(Sys.getenv("COPERNICUS_USERNAME", unset = ""), "")
          expect_equal(Sys.getenv("COPERNICUS_PASSWORD", unset = ""), "")

          # Ejecutar el test
          force(code)
        }
      )
    )

    # Limpieza final
    complete_cleanup()
  })
}

# Función para crear credenciales de prueba de forma consistente
create_test_credentials <- function(username = "test_user", password = "test_pass") {
  options(copernicus.username = username)
  options(copernicus.password = password)
  invisible(list(username = username, password = password))
}

# Función para limpiar archivos de test
cleanup_test_files <- function(pattern = "^test_.*\\.nc$") {
  test_files <- list.files(pattern = pattern)
  if (length(test_files) > 0) {
    file.remove(test_files)
  }
  invisible(NULL)
}

# Mock para el módulo de Python cuando no queremos conexión real
create_mock_module <- function(should_fail = TRUE) {
  if (should_fail) {
    list(
      subset = function(...) stop("Mock download - no real connection"),
      open_dataset = function(...) stop("Mock open_dataset - no real connection")
    )
  } else {
    list(
      subset = function(...) list(status = "success", file = "mock_file.nc"),
      open_dataset = function(...) list(status = "success", dataset = "mock_dataset")
    )
  }
}
