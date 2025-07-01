# tests/testthat/teardown.R
# Se ejecuta después de todos los tests

# Limpiar estado final
if (exists("complete_cleanup")) {
  complete_cleanup()
}
