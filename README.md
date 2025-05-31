# copernicusR

[![R build status](https://github.com/HansTtito/copernicusR/workflows/R-CMD-check/badge.svg)](https://github.com/HansTtito/copernicusR)

Paquete para descargar datos marinos de Copernicus Marine directamente desde R usando Python y la librería oficial `copernicusmarine`.

## Instalación

```r
# Desde tu repositorio local o GitHub:
# remotes::install_github("tuusuario/copernicusR")

archivo <- copernicus_download(
  dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
  variables = "zos",
  fecha = "2025-05-12",
  username = "tu_usuario",
  password = "tu_password"
)


```
