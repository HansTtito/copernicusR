#' @title Abrir dataset desde Copernicus Marine sin descarga
#'
#' @description
#' Abre un dataset directamente desde Copernicus Marine usando open_dataset.
#' Retorna un objeto xarray.Dataset que puede ser procesado en R.
#' Útil para explorar datos sin descargar archivos completos.
#'
#' @param dataset_id ID del dataset (exacto).
#' @param variables Vector o lista de variables a abrir. Si es NULL, abre todas.
#' @param fecha_inicio Fecha de inicio (YYYY-MM-DD). Opcional.
#' @param fecha_fin Fecha de fin (YYYY-MM-DD). Opcional.
#' @param bbox Vector de 4 valores (xmin, xmax, ymin, ymax) para la región. Opcional.
#' @param profundidad Vector de 2 valores: profundidad mínima y máxima. Opcional.
#' @param dataset_version Versión del dataset. Opcional.
#' @param username Usuario Copernicus Marine (opcional, si no se usa archivo config).
#' @param password Contraseña Copernicus Marine (opcional).
#' @param verbose_open Mostrar mensajes detallados.
#' @param ... Otros argumentos extra pasados a la función Python.
#' @return Objeto xarray.Dataset de Python, o NULL si falla.
#' @examples
#' \dontrun{
#' # Abrir dataset completo
#' ds <- copernicus_open_dataset(
#'   dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
#'   variables = c("zos", "uo", "vo")
#' )
#'
#' # Abrir con filtros temporales y espaciales
#' ds <- copernicus_open_dataset(
#'   dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
#'   variables = "zos",
#'   fecha_inicio = "2025-06-01",
#'   fecha_fin = "2025-06-10",
#'   bbox = c(-10, 5, 35, 50),
#'   username = "mi_usuario",
#'   password = "mi_contrasena"
#' )
#' }
#' @export
copernicus_open_dataset <- function(dataset_id,
                                    variables = NULL,
                                    fecha_inicio = NULL,
                                    fecha_fin = NULL,
                                    bbox = NULL,
                                    profundidad = NULL,
                                    dataset_version = NULL,
                                    username = NULL,
                                    password = NULL,
                                    verbose_open = TRUE,
                                    ...) {

  # Verificar que el entorno esté configurado
  copernicus_env <- .copernicus_env()
  if (!exists("cm", envir = copernicus_env)) {
    stop("❌ Copernicus Marine no está configurado. Ejecuta setup_copernicus() primero.")
  }

  cm <- get("cm", envir = copernicus_env)

  # Convertir variables a formato Python si se especifican
  variables_py <- NULL
  if (!is.null(variables)) {
    variables_py <- reticulate::r_to_py(as.list(variables))
  }

  if (verbose_open) {
    cat("🌊 Abriendo dataset:", dataset_id, "\n")
    if (!is.null(variables)) {
      cat("📊 Variables:", paste(variables, collapse = ", "), "\n")
    } else {
      cat("📊 Variables: todas disponibles\n")
    }
    if (!is.null(fecha_inicio) || !is.null(fecha_fin)) {
      cat("📅 Periodo:", fecha_inicio, "a", fecha_fin, "\n")
    }
    if (!is.null(bbox)) {
      cat("🗺️  Región: lon[", bbox[1], ",", bbox[2], "] lat[", bbox[3], ",", bbox[4], "]\n")
    }
    cat("⏳ Conectando con Copernicus Marine...\n\n")
  }

  start_time <- Sys.time()

  tryCatch({
    # Construir argumentos para open_dataset
    args_py <- list(dataset_id = dataset_id)

    # Agregar argumentos opcionales solo si se especifican
    if (!is.null(variables_py)) args_py$variables <- variables_py
    if (!is.null(dataset_version)) args_py$dataset_version <- dataset_version

    # Filtros temporales
    if (!is.null(fecha_inicio)) {
      args_py$start_datetime <- paste0(fecha_inicio, "T00:00:00")
    }
    if (!is.null(fecha_fin)) {
      args_py$end_datetime <- paste0(fecha_fin, "T00:00:00")
    }

    # Filtros espaciales
    if (!is.null(bbox)) {
      args_py$minimum_longitude <- bbox[1]
      args_py$maximum_longitude <- bbox[2]
      args_py$minimum_latitude <- bbox[3]
      args_py$maximum_latitude <- bbox[4]
    }

    # Filtros de profundidad
    if (!is.null(profundidad)) {
      args_py$minimum_depth <- profundidad[1]
      args_py$maximum_depth <- profundidad[2]
    }

    # Credenciales
    if (!is.null(username)) args_py$username <- username
    if (!is.null(password)) args_py$password <- password

    # Argumentos adicionales
    dots <- list(...)
    if (length(dots) > 0) args_py <- c(args_py, dots)

    # Llamar a open_dataset
    dataset <- do.call(cm$open_dataset, args_py)

    end_time <- Sys.time()
    time_secs <- round(difftime(end_time, start_time, units = "secs"), 2)

    if (verbose_open) {
      cat("✅ ¡Dataset abierto exitosamente!\n")
      cat("⏱️  Tiempo de conexión:", time_secs, "segundos\n")
      cat("📋 Usa reticulate::py_to_r() para convertir a R si es necesario\n")
    }

    return(dataset)

  }, error = function(e) {
    cat("❌ Error al abrir dataset:", e$message, "\n")

    # Mensajes de ayuda específicos
    if (grepl("date|time", e$message, ignore.case = TRUE)) {
      cat("💡 Las fechas pueden no estar disponibles. Verifica el rango temporal del dataset.\n")
    } else if (grepl("variable", e$message, ignore.case = TRUE)) {
      cat("💡 Alguna variable puede no existir en este dataset. Usa copernicus_describe() para ver variables disponibles.\n")
    } else if (grepl("credential|auth", e$message, ignore.case = TRUE)) {
      cat("💡 Problema de autenticación. Verifica usuario/contraseña o archivo de configuración.\n")
    } else if (grepl("longitude|latitude|bbox", e$message, ignore.case = TRUE)) {
      cat("💡 Verifica que las coordenadas del bbox estén dentro del rango del dataset.\n")
    }

    return(NULL)
  })
}

#' @title Probar apertura de dataset Copernicus
#'
#' @description
#' Realiza una prueba de apertura de dataset para validar que la función open_dataset funcione.
#'
#' @param username Usuario Copernicus Marine (opcional).
#' @param password Contraseña Copernicus Marine (opcional).
#' @return TRUE si la prueba fue exitosa.
#' @export
copernicus_test_open <- function(username = NULL, password = NULL) {

  cat("🧪 Probando apertura de dataset...\n")

  dataset <- copernicus_open_dataset(
    dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
    variables = "zos",
    bbox = c(0, 1, 40, 41),
    username = username,
    password = password,
    verbose_open = FALSE
  )

  if (!is.null(dataset)) {
    cat("✅ ¡open_dataset funcionando perfectamente!\n")
    cat("📊 Dataset conectado exitosamente\n")
    return(TRUE)
  } else {
    cat("❌ Error en prueba de open_dataset\n")
    return(FALSE)
  }
}
