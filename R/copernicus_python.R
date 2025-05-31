#' Buscar e inicializar Python en cualquier sistema operativo (uso interno)
#'
#' Busca el ejecutable de Python en rutas comunes y en el PATH del sistema.
#' Si lo encuentra, lo inicializa mediante reticulate.
#'
#' @return La configuración de Python detectada (objeto py_config).
#' @keywords internal
copernicus_configure_python <- function() {
  if (!requireNamespace("reticulate", quietly = TRUE)) install.packages("reticulate")
  library(reticulate)
  python_paths <- c(
    suppressWarnings(system("where python", intern = TRUE, ignore.stderr = TRUE)),
    suppressWarnings(system("which python3", intern = TRUE, ignore.stderr = TRUE)),
    suppressWarnings(system("which python", intern = TRUE, ignore.stderr = TRUE)),
    "C:/Python311/python.exe", "C:/Python312/python.exe", "C:/Python310/python.exe",
    "/usr/local/bin/python3", "/usr/bin/python3"
  )
  python_paths <- unique(na.omit(python_paths))
  python_found <- NULL
  for (path in python_paths) {
    if (!is.na(path) && file.exists(path) && !grepl("WindowsApps", path, ignore.case = TRUE)) {
      python_found <- path
      break
    }
  }
  if (!is.null(python_found)) {
    use_python(python_found, required = TRUE)
    cat("✅ Usando Python en:", python_found, "\n")
  } else {
    py_config <- py_discover_config()
    viable_pythons <- py_config$python_versions[!grepl("WindowsApps", py_config$python_versions)]
    if (length(viable_pythons) > 0) {
      use_python(viable_pythons[1], required = TRUE)
      cat("✅ Usando Python detectado automáticamente:", viable_pythons[1], "\n")
    } else {
      stop("❌ No se encontró Python fuera de WindowsApps. Instala Python desde https://www.python.org/downloads/ y agrega a PATH.")
    }
  }
  return(py_config())
}

#' Instalar el paquete Python copernicusmarine (uso interno)
#'
#' @param py Objeto de configuración Python.
#' @return Invisible TRUE si la instalación es exitosa.
#' @keywords internal
copernicus_install_package <- function(py) {
  tryCatch({
    reticulate::py_install("copernicusmarine", pip = TRUE)
    cat("   ✅ copernicusmarine instalado\n")
  }, error = function(e) {
    cat("   ⚠️  Error instalando copernicusmarine, intentando manualmente con pip...\n")
    system("pip install copernicusmarine")
  })
  invisible(TRUE)
}

#' Importar el módulo copernicusmarine de Python (uso interno)
#'
#' @param py Objeto de configuración Python.
#' @return Módulo copernicusmarine importado.
#' @keywords internal
copernicus_import_module <- function(py) {
  tryCatch({
    reticulate::import("copernicusmarine")
  }, error = function(e) {
    stop("❌ No se pudo importar copernicusmarine. Ejecuta: copernicus_reinstall_package()")
  })
}
