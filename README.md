# copernicusR

[![R](https://img.shields.io/badge/R-%3E%3D4.0-blue)](https://www.r-project.org/)
[![Python](https://img.shields.io/badge/Python-%3E%3D3.7-green)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Package to download marine data from Copernicus Marine directly in R using Python and the official [`copernicusmarine`](https://pypi.org/project/copernicusmarine/) library.

---

## 🚀 Description

`copernicusR` allows you to set up the Python environment, explore the dataset catalog, and download NetCDF (.nc) files from Copernicus Marine directly from R, integrating the official Python API with the R ecosystem through `reticulate`.

**Key Features:**
- 🐍 Automatic Python environment setup
- 🔐 Secure credential management (session options, environment variables, .Renviron)
- 📊 Direct dataset access without full downloads (`open_dataset`)
- 🌊 Full NetCDF file downloads with filtering options
- 🗺️ Spatial, temporal, and depth filtering
- ✅ Built-in validation and testing functions

---

## 📦 Installation

**Prerequisites:**
* Have **Python 3.7+** installed (ideally from [python.org](https://www.python.org/downloads/))
* Have internet access
* Have a Copernicus Marine account (free, [register here](https://data.marine.copernicus.eu/register))

### 1. Install the package from GitHub

```r
# Install remotes if you don't have it
install.packages("remotes")

# Install copernicusR from GitHub
remotes::install_github("HansTtito/copernicusR")
```

### 2. Load the library

```r
library(copernicusR)
```

---

## ⚙️ Quick Start

### Basic Setup

```r
# 1. Set up the Python environment and credentials (run once per session)
setup_copernicus(username = "your_username", password = "your_password")

# 2. Check if everything is ready
copernicus_is_ready()

# 3. Perform a quick test download
copernicus_test()
```

### Alternative Setup Methods

```r
# Method 1: Interactive setup (will prompt for credentials)
setup_copernicus()
copernicus_setup_credentials()

# Method 2: Environment variables (recommended for security)
# Add to your .Renviron file:
# COPERNICUS_USERNAME=your_username
# COPERNICUS_PASSWORD=your_password
setup_copernicus()

# Method 3: Set credentials in .Renviron permanently
copernicus_set_env_credentials("your_username", "your_password")
```

---

## 📊 Usage Examples

### 1. Open Dataset (No Download)

Perfect for exploring data structure and small extractions:

```r
# Open a dataset to explore without downloading
dataset <- copernicus_open_dataset(
  dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
  variables = "thetao",
  start_date = "2024-01-01",
  end_date = "2024-01-03",
  bbox = c(-75, -73, -41, -38),  # [xmin, xmax, ymin, ymax]
  depth = c(0, 50)               # [min_depth, max_depth]
)

# Convert to R if needed
data_r <- reticulate::py_to_r(dataset)
```

### 2. Download NetCDF Files

For full data downloads:

```r
# Download temperature data for a specific region
file_path <- copernicus_download(
  dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
  variables = c("thetao", "so"),  # Temperature and salinity
  start_date = "2024-01-01",
  end_date = "2024-01-31",
  bbox = c(-75, -73, -41, -38),   # Chilean coast
  depth = c(0, 100),
  output_file = "chile_coast_jan2024.nc"
)

# Load with terra or other R packages
library(terra)
raster_data <- rast(file_path)
```

### 3. Advanced Filtering

```r
# Download with specific depth layers
copernicus_download(
  dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
  variables = "thetao",
  start_date = "2024-06-01",
  end_date = "2024-06-30",
  bbox = c(-80, -70, -45, -35),
  depth = c(20, 40),              # Only 20-40m depth
  dataset_version = "202406",
  output_file = "summer_temps.nc"
)
```

---

## 🔐 Credential Management

### Secure Options (Recommended)

```r
# Option 1: Store in .Renviron (persists across sessions)
copernicus_set_env_credentials("username", "password")

# Option 2: Use environment variables
Sys.setenv(COPERNICUS_USERNAME = "your_username")
Sys.setenv(COPERNICUS_PASSWORD = "your_password")
```

### Session Options

```r
# Store for current session only
copernicus_setup_credentials("username", "password", store_credentials = TRUE)

# Check current credentials
copernicus_get_credentials()

# Clear credentials when done
copernicus_clear_credentials()
```

---

## 🛠️ Available Functions

### Setup and Configuration
- `setup_copernicus()` - Main setup function with credential support
- `copernicus_setup_credentials()` - Configure credentials only
- `copernicus_is_ready()` - Check if everything is configured
- `copernicus_reinstall_package()` - Reinstall Python package

### Data Access
- `copernicus_download()` - Download NetCDF files
- `copernicus_open_dataset()` - Open datasets without downloading
- `copernicus_test()` - Test download functionality
- `copernicus_test_open()` - Test dataset opening

### Credential Management
- `copernicus_get_credentials()` - View stored credentials
- `copernicus_clear_credentials()` - Clear session credentials
- `copernicus_set_env_credentials()` - Store in .Renviron
- `copernicus_validate_credentials()` - Test if credentials work

---

## 🗺️ Common Dataset IDs

```r
# Global Ocean Physics Analysis and Forecast
"cmems_mod_glo_phy_anfc_0.083deg_P1D-m"

# Mediterranean Sea Physics Analysis and Forecast
"cmems_mod_med_phy_anfc_4.2km_P1D-m"

# Baltic Sea Physics Analysis and Forecast
"cmems_mod_bal_phy_anfc_P1D-m"

# Check Copernicus Marine website for complete catalog
```

---

## 📋 Common Parameters

### Variables
- `"thetao"` - Sea water potential temperature
- `"so"` - Sea water salinity  
- `"uo"`, `"vo"` - Sea water velocity (x, y components)
- `"zos"` - Sea surface height
- `"mlotst"` - Mixed layer thickness

### Regions (bbox format: [xmin, xmax, ymin, ymax])
- Global: `c(-180, 180, -90, 90)`
- Chilean coast: `c(-75, -70, -45, -17)`
- Mediterranean: `c(-6, 37, 30, 46)`

---

## ⚠️ Troubleshooting

### Python Issues
```r
# If Python is not detected correctly
copernicus_reinstall_package()

# Check Python configuration
reticulate::py_config()
```

### Credential Issues
```r
# Validate credentials
copernicus_validate_credentials()

# Reset credentials
copernicus_clear_credentials()
copernicus_setup_credentials()
```

### Download Issues
```r
# Check system status
copernicus_is_ready()

# Try test download
copernicus_test()
```

---

## 📚 Dependencies

**R packages:**
- `reticulate` (for Python integration)
- `getPass` (optional, for secure password input)

**Python packages:**
- `copernicusmarine` (automatically installed)

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License

This project is licensed under the MIT License.

---

## 🙏 Acknowledgments

- [Copernicus Marine Service](https://marine.copernicus.eu/) for providing the data
- [copernicusmarine Python library](https://pypi.org/project/copernicusmarine/) developers
- R community and `reticulate` package maintainers
