#' @title Configura la integración con Copernicus Marine (Python)
#'
#' @description
#' Configura el entorno Python y carga el módulo copernicusmarine para su uso en R.
#' Se recomienda ejecutar una sola vez por sesión antes de llamar a otras funciones del paquete.
#'
#' @param install_copernicus Lógico. ¿Instalar el paquete copernicusmarine en Python si no está disponible? Default: TRUE.
#' @return Invisible TRUE si la configuración fue exitosa.
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

#' @title Reinstalar el paquete Python copernicusmarine
#'
#' @description
#' Reinstala el módulo copernicusmarine en el entorno Python detectado.
#' @return Invisible TRUE si se instala correctamente.
#' @export
copernicus_reinstall_package <- function() {
  py <- copernicus_configure_python()
  reticulate::py_install("copernicusmarine", pip = TRUE, force = TRUE)
  cat("✅ copernicusmarine reinstalado\n")
  invisible(TRUE)
}
