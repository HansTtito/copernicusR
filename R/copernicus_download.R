#' @title Descargar datos desde Copernicus Marine
#'
#' @description
#' Descarga archivos .nc desde el catálogo de Copernicus Marine. Permite especificar todas las opciones de la función Python.
#'
#' @param dataset_id ID del dataset (exacto).
#' @param variables Vector o lista de variables a descargar.
#' @param fecha Fecha de descarga (YYYY-MM-DD).
#' @param bbox Vector de 4 valores (xmin, xmax, ymin, ymax) para la región.
#' @param profundidad Vector de 2 valores: profundidad mínima y máxima.
#' @param dataset_version Versión del dataset.
#' @param output_file Archivo de salida. Por defecto genera uno basado en fecha.
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
#'   fecha = "2025-06-09",
#'   username = "mi_usuario", password = "mi_contrasena"
#' )
#' }
#' @export
copernicus_download <- function(dataset_id, variables, fecha,
                                bbox = c(-180, 179.92, -80, 90),
                                profundidad = c(0.494, 0.494),
                                dataset_version = "202406",
                                output_file = NULL,
                                username = NULL,
                                password = NULL,
                                verbose_download = TRUE,
                                ...) {
  copernicus_env <- .copernicus_env()
  cm <- get("cm", envir = copernicus_env)
  variables_py <- reticulate::r_to_py(as.list(variables))
  if (is.null(output_file)) {
    fecha_clean <- gsub("-", "", fecha)
    output_file <- paste0("copernicus_", fecha_clean, ".nc")
  }
  if (verbose_download) {
    cat("🌊 Descargando:", dataset_id, "\n")
    cat("📅 Fecha:", fecha, "\n")
    cat("📊 Variables:", paste(variables, collapse = ", "), "\n")
    cat("📁 Archivo:", output_file, "\n")
    cat("⏳ Iniciando descarga...\n\n")
  }
  start_time <- Sys.time()
  tryCatch({
    args_py <- list(
      dataset_id = dataset_id,
      dataset_version = dataset_version,
      variables = variables_py,
      start_datetime = paste0(fecha, "T00:00:00"),
      end_datetime = paste0(fecha, "T00:00:00"),
      minimum_longitude = bbox[1],
      maximum_longitude = bbox[2],
      minimum_latitude = bbox[3],
      maximum_latitude = bbox[4],
      minimum_depth = profundidad[1],
      maximum_depth = profundidad[2],
      coordinates_selection_method = "strict-inside",
      output_filename = output_file
    )
    if (!is.null(username)) args_py$username <- username
    if (!is.null(password)) args_py$password <- password
    dots <- list(...)
    if (length(dots) > 0) args_py <- c(args_py, dots)
    result <- do.call(cm$subset, args_py)
    end_time <- Sys.time()
    if (file.exists(output_file)) {
      size_mb <- round(file.size(output_file) / 1024 / 1024, 2)
      time_mins <- round(difftime(end_time, start_time, units = "mins"), 2)
      if (verbose_download) {
        cat("✅ ¡Descarga exitosa!\n")
        cat("📊 Tamaño:", size_mb, "MB\n")
        cat("⏱️  Tiempo:", time_mins, "minutos\n")
      }
      return(normalizePath(output_file))
    } else {
      cat("❌ Archivo no creado\n")
      return(NULL)
    }
  }, error = function(e) {
    cat("❌ Error en descarga:", e$message, "\n")
    if (grepl("date|time", e$message, ignore.case = TRUE)) {
      cat("💡 La fecha puede no estar disponible. Prueba con fecha más reciente.\n")
    } else if (grepl("variable", e$message, ignore.case = TRUE)) {
      cat("💡 Alguna variable puede no existir en este dataset.\n")
    } else if (grepl("credential|auth", e$message, ignore.case = TRUE)) {
      cat("💡 Problema de autenticación. Verifica usuario/contraseña.\n")
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
  fecha_prueba <- as.character(Sys.Date() - 2)
  archivo <- copernicus_download(
    dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
    variables = "zos",
    fecha = fecha_prueba,
    bbox = c(0, 1, 40, 41),
    output_file = "test_reticulate.nc",
    username = username,
    password = password,
    verbose_download = FALSE
  )
  if (!is.null(archivo) && file.exists(archivo)) {
    cat("✅ ¡Reticulate y Copernicus funcionando perfectamente!\n")
    file.remove(archivo)
    return(TRUE)
  } else {
    cat("❌ Error en prueba Copernicus\n")
    return(FALSE)
  }
}

#' @title Verificar si Copernicus Marine está listo
#'
#' @description
#' Retorna TRUE si el módulo Python y archivo de configuración existen.
#'
#' @return TRUE si el entorno está listo para descargar.
#' @export
copernicus_is_ready <- function() {
  copernicus_env <- .copernicus_env()
  exists("cm", envir = copernicus_env) &&
    !is.null(get("cm", envir = copernicus_env)) &&
    file.exists(file.path(path.expand("~"), ".copernicusmarine", "configuration_file.txt"))
}
