#' @title Set up Copernicus Marine integration (Python)
#'
#' @description
#' Sets up the Python environment and loads the copernicusmarine module for use in R.
#' It is recommended to run this once per session before calling other functions in the package.
#'
#' @param install_copernicus Logical. Should the copernicusmarine package be installed in Python if not available? Default: TRUE.
#' @return Invisible TRUE if the configuration was successful.
#' @examples
#' setup_copernicus()
#' @export
setup_copernicus <- function(install_copernicus = TRUE) {
  copernicus_env <- .copernicus_env()
  py <- copernicus_configure_python()
  assign("py", py, envir = copernicus_env)
  if (install_copernicus) copernicus_install_package(py)
  cm <- copernicus_import_module(py)
  assign("cm", cm, envir = copernicus_env)
  invisible(TRUE)
}

#' @title Reinstall the Python package copernicusmarine
#'
#' @description
#' Reinstalls the copernicusmarine module in the detected Python environment.
#' @return Invisible TRUE if successfully installed.
#' @export
copernicus_reinstall_package <- function() {
  py <- copernicus_configure_python()
  reticulate::py_install("copernicusmarine", pip = TRUE, force = TRUE)
  cat("✅ copernicusmarine reinstalled\n")
  invisible(TRUE)
}
