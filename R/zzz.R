# zzz.R
# Entorno interno del paquete (sin cambios)

#' Copernicus private environment (internal use)
#'
#' This function creates (if it doesn't already exist) and returns the internal environment
#' where the package stores persistent objects (e.g., the Python module, configurations, etc.).
#' It is used to avoid polluting the user's global environment and to maintain
#' references between the package's internal functions.
#'
#' @return A private environment in the global R space.
#' @keywords internal
.copernicus_env <- function() {
  if (!exists(".copernicus_internal_env", envir = .GlobalEnv)) {
    assign(".copernicus_internal_env", new.env(parent = emptyenv()), envir = .GlobalEnv)
  }
  get(".copernicus_internal_env", envir = .GlobalEnv)
}
