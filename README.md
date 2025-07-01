# copernicusR

[![R](https://img.shields.io/badge/R-%3E%3D4.0-blue)](https://www.r-project.org/)
[![Python](https://img.shields.io/badge/Python-%3E%3D3.7-green)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> R package to download marine data from Copernicus Marine directly in R using Python and the official [`copernicusmarine`](https://pypi.org/project/copernicusmarine/) library.

---

## 🚀 Description

`copernicusR` provides a seamless R interface to the Copernicus Marine Service, allowing you to download and access marine data directly from R. The package handles Python environment setup, credential management, and data access through the official Copernicus Marine API.

**Key Features:**
- 🐍 **Automatic Python setup** - No manual Python configuration needed
- 🔐 **Secure credential management** - Multiple secure storage options
- 📊 **Direct dataset access** - Explore data without downloading (`open_dataset`)
- 🌊 **Full NetCDF downloads** - Download complete files with filtering
- 🗺️ **Advanced filtering** - Spatial, temporal, and depth filtering
- ✅ **Built-in validation** - Test functions to ensure everything works

---

## 📦 Installation

### Prerequisites
- **R 4.0+**
- **Python 3.7+** installed from [python.org](https://www.python.org/downloads/)
- **Copernicus Marine account** - Free registration at [data.marine.copernicus.eu](https://data.marine.copernicus.eu/register)

### Install from GitHub

```r
# Install if you don't have remotes
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

# Install copernicusR
remotes::install_github("HansTtito/copernicusR")

# Load the package
library(copernicusR)
```

---

## ⚙️ Quick Start

### 1. Basic Setup

```r
# One-time setup per session
setup_copernicus(username = "your_username", password = "your_password")

# Verify everything is working
copernicus_is_ready()
#> Checking Copernicus Marine environment:
#> ✓ Python module copernicusmarine: OK
#> ✓ Credentials configured for user: your_username
#> Ready to use Copernicus Marine!

# Test with a small download
copernicus_test()
#> Testing download from Copernicus Marine...
#> ✓ Test download successful!
```

### 2. Alternative Setup (Recommended for Security)

```r
# Method 1: Environment variables (.Renviron)
copernicus_set_env_credentials("your_username", "your_password")
# Restart R, then:
setup_copernicus()

# Method 2: Interactive setup
setup_copernicus()  # Will prompt for credentials

# Method 3: Manual environment variables
Sys.setenv(COPERNICUS_USERNAME = "your_username")
Sys.setenv(COPERNICUS_PASSWORD = "your_password")
setup_copernicus()
```

---

## 📊 Usage Examples

### Open Dataset (Explore Without Downloading)

Perfect for data exploration and small extractions:

```r
# Open dataset for exploration
dataset <- copernicus_open_dataset(
  dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
  variables = "thetao",           # Sea water temperature
  start_date = "2024-01-01",
  end_date = "2024-01-03",
  bbox = c(-75, -73, -41, -38),   # Chilean coast [xmin, xmax, ymin, ymax]
  depth = c(0, 50)                # Surface to 50m
)

# Convert to R data structures if needed
data_r <- reticulate::py_to_r(dataset)
```

### Download NetCDF Files

For full data downloads and local processing:

```r
# Download sea temperature and salinity
file_path <- copernicus_download(
  dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
  variables = c("thetao", "so"),  # Temperature and salinity
  start_date = "2024-01-01",
  end_date = "2024-01-31",
  bbox = c(-75, -70, -45, -17),   # Chilean coast
  depth = c(0, 100),
  output_file = "chile_coast_jan2024.nc"
)

# Process with R packages
library(terra)
temperature <- rast(file_path, lyrs = "thetao")
plot(temperature[[1]])  # Plot first time step
```

### Advanced Examples

```r
# Multiple variables with custom output location
copernicus_download(
  dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
  variables = c("thetao", "so", "uo", "vo"),  # Temp, salinity, currents
  start_date = "2024-06-01",
  end_date = "2024-06-30",
  bbox = c(-80, -70, -45, -35),
  depth = c(0, 200),
  output_file = "data/summer_ocean_data.nc"
)

# Surface data only (no depth filtering)
surface_data <- copernicus_download(
  dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
  variables = "zos",              # Sea surface height
  start_date = "2024-01-15",
  end_date = "2024-01-15",
  bbox = c(-180, 180, -90, 90)    # Global
)
```

---

## 🔐 Credential Management

### Secure Storage (Recommended)

```r
# Store in .Renviron (persists across R sessions)
copernicus_set_env_credentials("your_username", "your_password")
# Restart R, credentials automatically loaded

# Check what's stored
copernicus_get_credentials()
#> $username
#> [1] "your_username"
#> $password
#> [1] "***MASKED***"
```

### Session Management

```r
# Set for current session only
copernicus_setup_credentials("username", "password")

# Clear when done
copernicus_clear_credentials()

# Validate credentials work
copernicus_validate_credentials()
```

---

## 📋 Function Reference

### Setup and Configuration
| Function | Description |
|----------|-------------|
| `setup_copernicus()` | Main setup function (Python + credentials) |
| `copernicus_is_ready()` | Check if everything is configured |
| `copernicus_setup_credentials()` | Configure credentials only |

### Data Access
| Function | Description |
|----------|-------------|
| `copernicus_download()` | Download NetCDF files |
| `copernicus_open_dataset()` | Open datasets without downloading |
| `copernicus_test()` | Test download functionality |
| `copernicus_test_open()` | Test dataset opening |

### Credential Management
| Function | Description |
|----------|-------------|
| `copernicus_get_credentials()` | View stored credentials |
| `copernicus_clear_credentials()` | Clear session credentials |
| `copernicus_set_env_credentials()` | Store in .Renviron |
| `copernicus_validate_credentials()` | Test credentials |

---

## 🗺️ Common Dataset IDs

```r
# Global Ocean Physics (0.083° resolution, daily)
"cmems_mod_glo_phy_anfc_0.083deg_P1D-m"

# Mediterranean Sea Physics (4.2km resolution)
"cmems_mod_med_phy_anfc_4.2km_P1D-m"

# Baltic Sea Physics
"cmems_mod_bal_phy_anfc_P1D-m"

# North West Shelf Physics
"cmems_mod_nws_phy_anfc_0.027deg_P1D-m"
```

> 💡 **Find more datasets**: Browse the full catalog at [data.marine.copernicus.eu](https://data.marine.copernicus.eu)

---

## 📊 Variable Reference

### Physical Variables
| Code | Description | Units |
|------|-------------|-------|
| `"thetao"` | Sea water potential temperature | °C |
| `"so"` | Sea water salinity | PSU |
| `"uo", "vo"` | Sea water velocity (x, y) | m/s |
| `"zos"` | Sea surface height above geoid | m |
| `"mlotst"` | Mixed layer thickness | m |

### Biogeochemical Variables
| Code | Description | Units |
|------|-------------|-------|
| `"chl"` | Chlorophyll-a concentration | mg/m³ |
| `"no3"` | Nitrate concentration | mmol/m³ |
| `"po4"` | Phosphate concentration | mmol/m³ |
| `"ph"` | pH | - |

---

## 🗺️ Example Regions

```r
# Predefined bounding boxes [xmin, xmax, ymin, ymax]
global    <- c(-180, 180, -90, 90)
chile     <- c(-75, -70, -45, -17)
med_sea   <- c(-6, 37, 30, 46)
north_sea <- c(-4, 9, 51, 62)
caribbean <- c(-87, -58, 9, 27)
```

---

## ⚠️ Troubleshooting

### Common Issues

**Python not found:**
```r
# Check Python configuration
reticulate::py_config()

# Manual Python setup
reticulate::use_python("/path/to/python")
setup_copernicus()
```

**Authentication errors:**
```r
# Reset and reconfigure credentials
copernicus_clear_credentials()
copernicus_setup_credentials("username", "password")
copernicus_validate_credentials()
```

**Download failures:**
```r
# Check system status
copernicus_is_ready()

# Try a test download
copernicus_test()

# Reduce data size (smaller bbox, fewer days)
```

**Module import errors:**
```r
# Reinstall Python package
reticulate::py_install("copernicusmarine", pip = TRUE)
```

### Getting Help

1. **Check function documentation**: `?copernicus_download`
2. **Validate your setup**: `copernicus_is_ready()`
3. **Test with small requests** before large downloads
4. **Check Copernicus Marine status**: [status.marine.copernicus.eu](https://status.marine.copernicus.eu)

---

## 📚 Dependencies

### R Packages
- **reticulate** - Python integration
- **getPass** - Secure password input (optional)

### Python Packages
- **copernicusmarine** - Official Copernicus Marine library (auto-installed)

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Report bugs** by opening an issue
2. **Suggest features** through discussions
3. **Submit pull requests** with improvements
4. **Improve documentation** and examples

### Development Setup

```r
# Clone and install development version
git clone https://github.com/HansTtito/copernicusR.git
devtools::install("copernicusR")

# Run tests
devtools::test()

# Check package
devtools::check()
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **[Copernicus Marine Service](https://marine.copernicus.eu/)** - For providing free access to marine data
- **[copernicusmarine](https://pypi.org/project/copernicusmarine/)** - Official Python library developers  
- **[reticulate](https://rstudio.github.io/reticulate/)** - Enabling seamless R-Python integration
- **R Community** - For continuous support and feedback

---

## 📈 Citation

If you use this package in your research, please cite:

```
[Hans Ttito] (2025). copernicusR: R Interface to Copernicus Marine Service. 
R package version [version]. https://github.com/HansTtito/copernicusR
```
