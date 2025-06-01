# copernicusR

Paquete para descargar datos marinos de Copernicus Marine directamente desde R usando Python y la librería oficial [`copernicusmarine`](https://github.com/CopernicusMarine/copernicus-marine-client).

---

## 🚀 Descripción

`copernicusR` permite configurar el entorno Python, explorar el catálogo de datasets y descargar archivos NetCDF (.nc) de Copernicus Marine directamente desde R, integrando la API oficial de Python con el ecosistema R a través de `reticulate`.

---

## 📦 Instalación

**Requisitos previos:**  
- Tener instalado **Python 3** (idealmente desde [python.org](https://www.python.org/downloads/)).
- Tener acceso a internet.
- Disponer de una cuenta Copernicus Marine (gratuita, [regístrate aquí](https://data.marine.copernicus.eu/register)).

### 1. Instala el paquete desde GitHub

```r
# Instala remotes si no lo tienes
install.packages("remotes")

# Instala copernicusR desde GitHub
remotes::install_github("HansTtito/copernicusR")
```

## ⚙️ Uso básico

```r

library(copernicusR)

# 1. Configurar entorno Python y módulo (correr una sola vez por sesión)
setup_copernicus()

# 2. Descargar un archivo NetCDF desde Copernicus Marine
archivo <- copernicus_download(
  dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
  variables = "zos",
  fecha = "2025-05-12",
  username = "tu_usuario",
  password = "tu_password"
)


```


