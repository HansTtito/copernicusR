#' Ambiente privado de Copernicus (uso interno)
#'
#' Esta función crea (si no existe) y retorna el ambiente interno donde el paquete
#' guarda objetos persistentes (por ejemplo, el módulo Python, configuraciones, etc.).
#' Se utiliza para evitar contaminación en el espacio global del usuario y mantener
#' las referencias entre funciones internas del paquete.
#'
#' @return Un environment privado en el espacio global de R.
#' @keywords internal
.copernicus_env <- function() {
  if (!exists(".copernicus_internal_env", envir = .GlobalEnv)) {
    assign(".copernicus_internal_env", new.env(parent = emptyenv()), envir = .GlobalEnv)
  }
  get(".copernicus_internal_env", envir = .GlobalEnv)
}
