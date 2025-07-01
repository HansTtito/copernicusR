#' Search and initialize Python on any operating system (internal use)
#'
#' Searches for the Python executable in common paths and the system PATH.
#' If found, it initializes it via reticulate.
#'
#' @return The detected Python configuration (py_config object).
#' @importFrom reticulate use_python py_discover_config py_config import py_install
#' @importFrom utils install.packages
#' @importFrom stats na.omit
#' @keywords internal
copernicus_configure_python <- function() {
  # Check reticulate availability first
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    stop(
      "The 'reticulate' package is required but not available.\n",
      "Install it with: install.packages('reticulate')"
    )
  }

  # Search for Python in common locations
  python_paths <- c(
    suppressWarnings(system("where python", intern = TRUE, ignore.stderr = TRUE)),
    suppressWarnings(system("which python3", intern = TRUE, ignore.stderr = TRUE)),
    suppressWarnings(system("which python", intern = TRUE, ignore.stderr = TRUE)),
    "C:/Python311/python.exe", "C:/Python312/python.exe", "C:/Python310/python.exe",
    "C:/Python39/python.exe", "C:/Python38/python.exe",
    "/usr/local/bin/python3", "/usr/bin/python3", "/opt/python/bin/python3"
  )

  # Clean and filter paths
  python_paths <- unique(stats::na.omit(python_paths))
  python_found <- NULL

  # Find first viable Python
  for (path in python_paths) {
    if (!is.na(path) &&
        nzchar(path) &&
        file.exists(path) &&
        !grepl("WindowsApps", path, ignore.case = TRUE)) {

      # Test if this Python version is adequate
      tryCatch({
        # Try to get version
        version_cmd <- paste0('"', path, '" --version')
        version_output <- system(version_cmd, intern = TRUE, ignore.stderr = TRUE)

        if (length(version_output) > 0 && grepl("Python [3-9]\\.[7-9]", version_output)) {
          python_found <- path
          break
        }
      }, error = function(e) {
        # Continue to next Python if this one fails
        NULL
      })
    }
  }

  # Configure Python
  tryCatch({
    if (!is.null(python_found)) {
      reticulate::use_python(python_found, required = TRUE)
      cat("Using Python at:", python_found, "\n")
    } else {
      # Fallback to reticulate's discovery
      cat("Searching for Python automatically...\n")
      py_config <- reticulate::py_discover_config()

      viable_pythons <- py_config$python_versions[
        !grepl("WindowsApps", py_config$python_versions, ignore.case = TRUE)
      ]

      if (length(viable_pythons) > 0) {
        reticulate::use_python(viable_pythons[1], required = TRUE)
        cat("Automatically detected Python:", viable_pythons[1], "\n")
      } else {
        stop(
          "No suitable Python installation found. Please ensure:\n",
          "1. Python 3.7+ is installed from https://www.python.org/downloads/\n",
          "2. Python is added to your system PATH\n",
          "3. Python is not from Microsoft Store (WindowsApps)\n\n",
          "After installing Python, restart R/RStudio and try again."
        )
      }
    }

    # Return configuration
    config <- reticulate::py_config()

    # Verify Python version is adequate
    if (!is.null(config$version_string)) {
      cat("Python version:", config$version_string, "\n")
    }

    return(config)

  }, error = function(e) {
    stop(
      "Python configuration failed. Please ensure:\n",
      "1. Python 3.7+ is installed from https://www.python.org/downloads/\n",
      "2. Python is added to your system PATH\n",
      "3. Try restarting R/RStudio\n\n",
      "Original error: ", e$message
    )
  })
}

#' Install the Python package copernicusmarine (internal use)
#'
#' @param py Python configuration object.
#' @return Invisible TRUE if the installation is successful.
#' @importFrom reticulate py_install
#' @keywords internal
copernicus_install_package <- function(py) {
  tryCatch({
    reticulate::py_install("copernicusmarine", pip = TRUE)
    cat("   copernicusmarine installed\n")
  }, error = function(e) {
    cat("   Error installing copernicusmarine, attempting manual pip install...\n")
    system("pip install copernicusmarine")
  })
  invisible(TRUE)
}

#' Import the copernicusmarine Python module (internal use)
#'
#' @param py Python configuration object.
#' @return Imported copernicusmarine module.
#' @importFrom reticulate import
#' @keywords internal
copernicus_import_module <- function(py) {
  tryCatch({
    reticulate::import("copernicusmarine")
  }, error = function(e) {
    stop("Could not import copernicusmarine. Run: copernicus_reinstall_package()")
  })
}
