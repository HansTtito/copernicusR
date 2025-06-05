# copernicusR

Package to download marine data from Copernicus Marine directly in R using Python and the official [`copernicusmarine`](https://pypi.org/project/copernicusmarine/) library.

---

## 🚀 Description

`copernicusR` allows you to set up the Python environment, explore the dataset catalog, and download NetCDF (.nc) files from Copernicus Marine directly from R, integrating the official Python API with the R ecosystem through `reticulate`.

---

## 📦 Installation

**Prerequisites:**

* Have **Python 3** installed (ideally from [python.org](https://www.python.org/downloads/)).
* Have internet access.
* Have a Copernicus Marine account (free, [register here](https://data.marine.copernicus.eu/register)).

### 1. Install the package from GitHub

```r
# Install remotes if you don't have it
install.packages("remotes")

# Install copernicusR from GitHub
remotes::install_github("HansTtito/copernicusR")
```

## ⚙️ Basic usage

```r
library(copernicusR)

# 1. Set up the Python environment and module (run once per session)
setup_copernicus()

# 2. Check if everything is ready
copernicus_is_ready()

# 3. Perform a quick test download
copernicus_test()

# 4. Read a NetCDF file from Copernicus Marine
data_set <- copernicus_open_dataset(
  dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
  variables = "zos",
  start_date = "2025-05-12",
  username = "your_username",
  password = "your_password"
)

# 5. Download a NetCDF file from Copernicus Marine
copernicus_download(
  dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
  variables = "zos",
  start_date = "2025-05-12",
  end_date = "2025-05-12",
  username = "your_username",
  password = "your_password"
)



```
