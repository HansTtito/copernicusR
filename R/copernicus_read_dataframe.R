#' @title Leer datos de Copernicus Marine como DataFrame
#'
#' @description
#' Lee datos directamente desde Copernicus Marine y los retorna como un DataFrame de pandas
#' que puede ser convertido fácilmente a data.frame de R. Ideal para análisis de datos
#' sin necesidad de descargar archivos.
#'
#' @param dataset_id ID del dataset (exacto).
#' @param variables Vector o lista de variables a leer. Si es NULL, lee todas.
#' @param fecha_inicio Fecha de inicio (YYYY-MM-DD). Opcional.
#' @param fecha_fin Fecha de fin (YYYY-MM-DD). Opcional.
#' @param bbox Vector de 4 valores (xmin, xmax, ymin, ymax) para la región. Opcional.
#' @param profundidad Vector de 2 valores: profundidad mínima y máxima. Opcional.
#' @param dataset_version Versión del dataset. Opcional.
#' @param username Usuario Copernicus Marine (opcional, si no se usa archivo config).
#' @param password Contraseña Copernicus Marine (opcional).
#' @param convert_to_r Convertir automáticamente a data.frame de R. Default: TRUE.
#' @param verbose_read Mostrar mensajes detallados.
#' @param ... Otros argumentos extra pasados a la función Python.
#' @return DataFrame de pandas o data.frame de R (según convert_to_r), o NULL si falla.
#' @examples
#' \dontrun{
#' # Leer datos como data.frame de R
#' df <- copernicus_read_dataframe(
#'   dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
#'   variables = c("zos", "uo", "vo"),
#'   fecha_inicio = "2025-06-01",
#'   fecha_fin = "2025-06-05",
#'   bbox = c(-10, 5, 35, 50)
#' )
#'
#' # Leer manteniendo formato pandas
#' df_pandas <- copernicus_read_dataframe(
#'   dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
#'   variables = "zos",
#'   bbox = c(0, 1, 40, 41),
#'   convert_to_r = FALSE
#' )
#'
#' # Leer datos de una sola fecha
#' df_diario <- copernicus_read_dataframe(
#'   dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
#'   variables = "zos",
#'   fecha_inicio = "2025-06-01",
#'   fecha_fin = "2025-06-01",
#'   username = "mi_usuario",
#'   password = "mi_contrasena"
#' )
#' }
#' @export
copernicus_read_dataframe <- function(dataset_id,
                                      variables = NULL,
                                      fecha_inicio = NULL,
                                      fecha_fin = NULL,
                                      bbox = NULL,
                                      profundidad = NULL,
                                      dataset_version = NULL,
                                      username = NULL,
                                      password = NULL,
                                      convert_to_r = TRUE,
                                      verbose_read = TRUE,
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

  if (verbose_read) {
    cat("📊 Leyendo datos como DataFrame desde:", dataset_id, "\n")
    if (!is.null(variables)) {
      cat("📋 Variables:", paste(variables, collapse = ", "), "\n")
    } else {
      cat("📋 Variables: todas disponibles\n")
    }
    if (!is.null(fecha_inicio) || !is.null(fecha_fin)) {
      cat("📅 Periodo:", fecha_inicio, "a", fecha_fin, "\n")
    }
    if (!is.null(bbox)) {
      cat("🗺️  Región: lon[", bbox[1], ",", bbox[2], "] lat[", bbox[3], ",", bbox[4], "]\n")
    }
    if (!is.null(profundidad)) {
      cat("🌊 Profundidad:", profundidad[1], "a", profundidad[2], "m\n")
    }
    cat("⏳ Cargando datos en memoria...\n\n")
  }

  start_time <- Sys.time()

  tryCatch({
    # Construir argumentos para read_dataframe
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

    # Llamar a read_dataframe
    dataframe_pandas <- do.call(cm$read_dataframe, args_py)

    end_time <- Sys.time()
    time_secs <- round(difftime(end_time, start_time, units = "secs"), 2)

    if (verbose_read) {
      cat("✅ ¡DataFrame cargado exitosamente!\n")
      cat("⏱️  Tiempo de carga:", time_secs, "segundos\n")

      # Obtener información del DataFrame usando Python
      tryCatch({
        shape_info <- dataframe_pandas$shape
        n_rows <- shape_info[[1]]
        n_cols <- shape_info[[2]]
        cat("📊 Dimensiones:", n_rows, "filas x", n_cols, "columnas\n")

        # Mostrar nombres de columnas
        columns <- dataframe_pandas$columns$tolist()
        cat("📋 Columnas:", paste(reticulate::py_to_r(columns), collapse = ", "), "\n")

      }, error = function(e) {
        cat("📊 DataFrame pandas creado\n")
      })
    }

    # Convertir a R si se solicita
    if (convert_to_r) {
      if (verbose_read) {
        cat("🔄 Convirtiendo a data.frame de R...\n")
      }

      tryCatch({
        df_r <- reticulate::py_to_r(dataframe_pandas)

        if (verbose_read) {
          cat("✅ Conversión completada\n")
          cat("📈 Usa head(), summary(), str() para explorar los datos\n")
        }

        return(df_r)

      }, error = function(e) {
        cat("⚠️  Error en conversión a R:", e$message, "\n")
        cat("📊 Retornando DataFrame de pandas original\n")
        cat("💡 Usa reticulate::py_to_r() manualmente si es necesario\n")
        return(dataframe_pandas)
      })
    } else {
      if (verbose_read) {
        cat("📊 DataFrame de pandas listo para usar\n")
        cat("💡 Usa reticulate::py_to_r() para convertir a R si es necesario\n")
      }
      return(dataframe_pandas)
    }

  }, error = function(e) {
    cat("❌ Error al leer DataFrame:", e$message, "\n")

    # Mensajes de ayuda específicos
    if (grepl("date|time", e$message, ignore.case = TRUE)) {
      cat("💡 Problema con fechas. Verifica:\n")
      cat("   • Formato YYYY-MM-DD correcto\n")
      cat("   • Que las fechas estén dentro del rango del dataset\n")
      # cat("   • Usa copernicus_describe() para ver rango temporal disponible\n")
    } else if (grepl("variable", e$message, ignore.case = TRUE)) {
      cat("💡 Problema con variables. Verifica:\n")
      cat("   • Que las variables existan en este dataset\n")
      # cat("   • Usa copernicus_describe() para ver variables disponibles\n")
      cat("   • Nombres exactos (sensibles a mayúsculas)\n")
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
      # cat("   • Usa copernicus_describe() para ver rangos de profundidad\n")
    } else if (grepl("memory|size|large", e$message, ignore.case = TRUE)) {
      cat("💡 Problema de memoria. Intenta:\n")
      cat("   • Reducir el rango temporal\n")
      cat("   • Reducir la región geográfica\n")
      cat("   • Seleccionar menos variables\n")
      cat("   • Usar copernicus_download() para archivos muy grandes\n")
    } else if (grepl("network|connection|timeout", e$message, ignore.case = TRUE)) {
      cat("💡 Problema de conexión. Intenta:\n")
      cat("   • Verificar tu conexión a internet\n")
      cat("   • Reintentar más tarde\n")
      cat("   • Reducir el tamaño de los datos solicitados\n")
    }

    return(NULL)
  })
}

#' @title Probar función read_dataframe de Copernicus
#'
#' @description
#' Realiza una prueba pequeña de la función read_dataframe para validar que funcione.
#'
#' @param username Usuario Copernicus Marine (opcional).
#' @param password Contraseña Copernicus Marine (opcional).
#' @return TRUE si la prueba fue exitosa.
#' @export
copernicus_test_read_dataframe <- function(username = NULL, password = NULL) {

  cat("🧪 Probando lectura de DataFrame...\n")

  # Usar fecha reciente y región pequeña para prueba rápida
  fecha_prueba <- as.character(Sys.Date() - 3)

  df <- copernicus_read_dataframe(
    dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
    variables = "zos",
    fecha_inicio = fecha_prueba,
    fecha_fin = fecha_prueba,
    bbox = c(0, 1, 40, 41),
    username = username,
    password = password,
    verbose_read = FALSE
  )

  if (!is.null(df)) {
    if (is.data.frame(df)) {
      cat("✅ ¡read_dataframe funcionando correctamente!\n")
      cat("📊 DataFrame de R creado:", nrow(df), "filas x", ncol(df), "columnas\n")
      cat("📋 Columnas:", paste(names(df), collapse = ", "), "\n")
    } else {
      cat("✅ ¡read_dataframe funcionando correctamente!\n")
      cat("📊 DataFrame de pandas creado exitosamente\n")
    }
    return(TRUE)
  } else {
    cat("❌ Error en prueba de read_dataframe\n")
    cat("💡 Verifica tu configuración con copernicus_is_ready()\n")
    return(FALSE)
  }
}

#' @title Leer muestra rápida de datos
#'
#' @description
#' Función de conveniencia para obtener una muestra pequeña de datos
#' para exploración rápida.
#'
#' @param dataset_id ID del dataset.
#' @param variables Vector de variables. Por defecto toma la primera disponible.
#' @param dias_atras Número de días hacia atrás desde hoy para la fecha de muestra.
#' @param bbox_size Tamaño del bbox de muestra (grados). Por defecto 1 grado.
#' @param verbose_sample Mostrar mensajes detallados.
#' @return data.frame con muestra de datos.
#' @examples
#' \dontrun{
#' # Muestra rápida del dataset
#' muestra <- copernicus_sample_data(
#'   dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m"
#' )
#' }
#' @export
copernicus_sample_data <- function(dataset_id,
                                   variables = NULL,
                                   dias_atras = 3,
                                   bbox_size = 1,
                                   verbose_sample = TRUE) {

  if (verbose_sample) {
    cat("🎯 Obteniendo muestra rápida de datos...\n")
  }

  # Fecha de muestra
  fecha_muestra <- as.character(Sys.Date() - dias_atras)

  # Región pequeña centrada en 0,0
  bbox_muestra <- c(0, bbox_size, 40, 40 + bbox_size)

  # Si no se especifican variables, intentar con algunas comunes
  if (is.null(variables)) {
    variables <- "zos"  # Variable común en muchos datasets
    if (verbose_sample) {
      cat("📊 Usando variable por defecto: zos\n")
    }
  }

  df <- copernicus_read_dataframe(
    dataset_id = dataset_id,
    variables = variables,
    fecha_inicio = fecha_muestra,
    fecha_fin = fecha_muestra,
    bbox = bbox_muestra,
    verbose_read = verbose_sample
  )

  if (!is.null(df) && verbose_sample) {
    cat("🎉 ¡Muestra obtenida! Úsala para explorar la estructura de datos\n")
  }

  return(df)
}
