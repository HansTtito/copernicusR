#' Copernicus private environment (internal use)
#'
#' This function creates (if it doesn't already exist) and returns the internal environment
#' where the package stores persistent objects (e.g., the Python module, configurations, etc.).
#' It is used to avoid polluting the user's global environment and to maintain
#' references between the package's internal functions.
#'
#' @return A private environment in the package namespace.
#' @keywords internal
.copernicus_env <- function() {
  pkg_env <- parent.env(environment())
  if (!exists(".copernicus_internal_env", envir = pkg_env)) {
    assign(".copernicus_internal_env", new.env(parent = emptyenv()), envir = pkg_env)
  }
  get(".copernicus_internal_env", envir = pkg_env)
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "copernicusR loaded. To get started:\n",
    "1. Ensure Python 3.7+ is installed\n",
    "2. Run setup_copernicus() to configure\n",
    "3. Get free account at: https://data.marine.copernicus.eu/register\n",
    "Use copernicus_is_ready() to check configuration."
  )
}
