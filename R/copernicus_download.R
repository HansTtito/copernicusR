#' @title Descargar datos desde Copernicus Marine
#'
#' @description
#' Descarga archivos .nc desde el catálogo de Copernicus Marine. Permite especificar todas las opciones de la función Python.
#'
#' @param dataset_id ID del dataset (exacto).
#' @param variables Vector o lista de variables a descargar.
#' @param fecha_inicio Fecha de inicio de descarga (YYYY-MM-DD).
#' @param fecha_fin Fecha de fin de descarga (YYYY-MM-DD).
#' @param bbox Vector de 4 valores (xmin, xmax, ymin, ymax) para la región.
#' @param profundidad Vector de 2 valores: profundidad mínima y máxima.
#' @param dataset_version Versión del dataset.
#' @param output_file Archivo de salida. Por defecto genera uno basado en fechas.
#' @param username Usuario Copernicus Marine (opcional, si no se usa archivo config).
#' @param password Contraseña Copernicus Marine (opcional).
#' @param verbose_download Mostrar mensajes detallados.
#' @param ... Otros argumentos extra pasados a la función Python.
#' @return Ruta absoluta del archivo descargado, o NULL si falla.
#' @examples
#' \dontrun{
#' copernicus_download(
#'   dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
#'   variables = "zos",
#'   fecha_inicio = "2025-06-01",
#'   fecha_fin = "2025-06-09",
#'   username = "mi_usuario", password = "mi_contrasena"
#' )
#' }
#' @export
copernicus_download <- function(dataset_id, variables, fecha_inicio, fecha_fin,
                                bbox = c(-180, 179.92, -80, 90),
                                profundidad = c(0.494, 0.494),
                                dataset_version = "202406",
                                output_file = NULL,
                                username = NULL,
                                password = NULL,
                                verbose_download = TRUE,
                                ...) {

  # Verificar que el entorno esté configurado
  copernicus_env <- .copernicus_env()
  if (!exists("cm", envir = copernicus_env)) {
    stop("❌ Copernicus Marine no está configurado. Ejecuta setup_copernicus() primero.")
  }

  cm <- get("cm", envir = copernicus_env)
  variables_py <- reticulate::r_to_py(as.list(variables))

  # Generar nombre de archivo automáticamente si no se especifica
  if (is.null(output_file)) {
    fecha_clean_inicio <- gsub("-", "", fecha_inicio)
    fecha_clean_fin <- gsub("-", "", fecha_fin)
    output_file <- paste0("copernicus_", fecha_clean_inicio, "-", fecha_clean_fin, ".nc")
  }

  # Crear directorio de salida si no existe
  output_dir <- dirname(output_file)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  if (verbose_download) {
    cat("🌊 Descargando:", dataset_id, "\n")
    cat("📅 Periodo:", fecha_inicio, "a", fecha_fin, "\n")
    cat("📊 Variables:", paste(variables, collapse = ", "), "\n")
    cat("🗺️  Región: lon[", bbox[1], ",", bbox[2], "] lat[", bbox[3], ",", bbox[4], "]\n")
    if (!all(profundidad == c(0.494, 0.494))) {
      cat("🌊 Profundidad:", profundidad[1], "a", profundidad[2], "m\n")
    }
    cat("📁 Archivo:", output_file, "\n")
    cat("⏳ Iniciando descarga...\n\n")
  }

  start_time <- Sys.time()

  tryCatch({
    args_py <- list(
      dataset_id = dataset_id,
      dataset_version = dataset_version,
      variables = variables_py,
      start_datetime = paste0(fecha_inicio, "T00:00:00"),
      end_datetime = paste0(fecha_fin, "T00:00:00"),
      minimum_longitude = bbox[1],
      maximum_longitude = bbox[2],
      minimum_latitude = bbox[3],
      maximum_latitude = bbox[4],
      minimum_depth = profundidad[1],
      maximum_depth = profundidad[2],
      coordinates_selection_method = "strict-inside",
      output_filename = output_file
    )

    # Agregar credenciales si se proporcionan
    if (!is.null(username)) args_py$username <- username
    if (!is.null(password)) args_py$password <- password

    # Agregar argumentos adicionales
    dots <- list(...)
    if (length(dots) > 0) args_py <- c(args_py, dots)

    # Ejecutar descarga
    result <- do.call(cm$subset, args_py)
    end_time <- Sys.time()

    # Verificar éxito de descarga
    if (file.exists(output_file)) {
      size_mb <- round(file.size(output_file) / 1024 / 1024, 2)
      time_mins <- round(difftime(end_time, start_time, units = "mins"), 2)

      if (verbose_download) {
        cat("✅ ¡Descarga exitosa!\n")
        cat("📊 Tamaño:", size_mb, "MB\n")
        cat("⏱️  Tiempo:", time_mins, "minutos\n")
        cat("📂 Ubicación:", normalizePath(output_file), "\n")
      }

      return(normalizePath(output_file))
    } else {
      cat("❌ Error: Archivo no fue creado\n")
      return(NULL)
    }

  }, error = function(e) {
    cat("❌ Error en descarga:", e$message, "\n")

    # Mensajes de ayuda específicos
    if (grepl("date|time", e$message, ignore.case = TRUE)) {
      cat("💡 Las fechas pueden no estar disponibles. Verifica:\n")
      cat("   • Que las fechas estén en formato YYYY-MM-DD\n")
      cat("   • Que estén dentro del rango temporal del dataset\n")
      cat("   • Prueba con fechas más recientes\n")
    } else if (grepl("variable", e$message, ignore.case = TRUE)) {
      cat("💡 Problema con variables. Verifica:\n")
      cat("   • Que las variables existan en este dataset\n")
      cat("   • Usa copernicus_describe() para ver variables disponibles\n")
    } else if (grepl("credential|auth|login", e$message, ignore.case = TRUE)) {
      cat("💡 Problema de autenticación. Verifica:\n")
      cat("   • Usuario y contraseña correctos\n")
      cat("   • Archivo de configuración ~/.copernicusmarine/configuration_file.txt\n")
      cat("   • Que tu cuenta esté activa en Copernicus Marine\n")
    } else if (grepl("longitude|latitude|bbox|coordinates", e$message, ignore.case = TRUE)) {
      cat("💡 Problema con coordenadas. Verifica:\n")
      cat("   • bbox en formato [xmin, xmax, ymin, ymax]\n")
      cat("   • Que las coordenadas estén dentro del rango del dataset\n")
      cat("   • Longitud: -180 a 180, Latitud: -90 a 90\n")
    } else if (grepl("depth", e$message, ignore.case = TRUE)) {
      cat("💡 Problema con profundidad. Verifica:\n")
      cat("   • Que el dataset tenga datos de profundidad\n")
      cat("   • Que los valores estén en el rango disponible\n")
    } else if (grepl("network|connection|timeout", e$message, ignore.case = TRUE)) {
      cat("💡 Problema de conexión. Intenta:\n")
      cat("   • Verificar tu conexión a internet\n")
      cat("   • Reintentar la descarga más tarde\n")
      cat("   • Reducir el tamaño de la descarga\n")
    }

    return(NULL)
  })
}

#' @title Probar integración Copernicus
#'
#' @description
#' Realiza una descarga de prueba pequeña para validar que todo el sistema funcione.
#'
#' @param username Usuario Copernicus Marine (opcional).
#' @param password Contraseña Copernicus Marine (opcional).
#' @return TRUE si la prueba fue exitosa.
#' @export
copernicus_test <- function(username = NULL, password = NULL) {

  cat("🧪 Probando descarga desde Copernicus Marine...\n")

  # Usar fecha de hace 3 días para mayor probabilidad de éxito
  fecha_prueba <- as.character(Sys.Date() - 3)

  archivo <- copernicus_download(
    dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
    variables = "zos",
    fecha_inicio = fecha_prueba,
    fecha_fin = fecha_prueba,
    bbox = c(0, 1, 40, 41),
    output_file = "test_copernicus_download.nc",
    username = username,
    password = password,
    verbose_download = FALSE
  )

  if (!is.null(archivo) && file.exists(archivo)) {
    file_size_kb <- round(file.size(archivo) / 1024, 1)
    cat("✅ ¡Descarga de prueba exitosa!\n")
    cat("📊 Archivo creado:", basename(archivo), "(", file_size_kb, "KB)\n")
    cat("🧹 Limpiando archivo de prueba...\n")
    file.remove(archivo)
    return(TRUE)
  } else {
    cat("❌ Error en prueba de descarga\n")
    cat("💡 Verifica tu configuración con copernicus_is_ready()\n")
    return(FALSE)
  }
}

#' @title Verificar si Copernicus Marine está listo
#'
#' @description
#' Verifica si el entorno está correctamente configurado para usar Copernicus Marine.
#' Retorna TRUE si el módulo Python y archivo de configuración existen.
#'
#' @param verbose Mostrar información detallada del estado.
#' @return TRUE si el entorno está listo para descargar.
#' @export
copernicus_is_ready <- function(verbose = TRUE) {

  copernicus_env <- .copernicus_env()
  config_path <- file.path(path.expand("~"), ".copernicusmarine", "configuration_file.txt")

  # Verificar módulo Python
  module_ok <- exists("cm", envir = copernicus_env) && !is.null(get("cm", envir = copernicus_env))

  # Verificar archivo de configuración
  config_ok <- file.exists(config_path)

  if (verbose) {
    cat("🔍 Verificando configuración de Copernicus Marine:\n\n")

    if (module_ok) {
      cat("✅ Módulo Python copernicusmarine: OK\n")
    } else {
      cat("❌ Módulo Python copernicusmarine: NO DISPONIBLE\n")
      cat("💡 Ejecuta setup_copernicus() para configurar\n")
    }

    if (config_ok) {
      cat("✅ Archivo de configuración: OK\n")
      cat("📁 Ubicación:", config_path, "\n")
    } else {
      cat("❌ Archivo de configuración: NO ENCONTRADO\n")
      cat("💡 Configura tus credenciales primero\n")
      cat("📁 Esperado en:", config_path, "\n")
    }

    cat("\n")

    if (module_ok && config_ok) {
      cat("🎉 ¡Todo listo para usar Copernicus Marine!\n")
      cat("🧪 Ejecuta copernicus_test() para hacer una prueba\n")
    } else {
      cat("⚠️  Configuración incompleta\n")
      if (!module_ok) {
        cat("1️⃣  Ejecuta: setup_copernicus()\n")
      }
      if (!config_ok) {
        cat("2️⃣  Configura tus credenciales de Copernicus Marine\n")
      }
    }
  }

  return(module_ok && config_ok)
}
