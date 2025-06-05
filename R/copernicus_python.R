#' Search and initialize Python on any operating system (internal use)
#'
#' Searches for the Python executable in common paths and the system PATH.
#' If found, it initializes it via reticulate.
#'
#' @return The detected Python configuration (py_config object).
#' @keywords internal
copernicus_configure_python <- function() {
  if (!requireNamespace("reticulate", quietly = TRUE)) install.packages("reticulate")
  library(reticulate)
  python_paths <- c(
    suppressWarnings(system("where python", intern = TRUE, ignore.stderr = TRUE)),
    suppressWarnings(system("which python3", intern = TRUE, ignore.stderr = TRUE)),
    suppressWarnings(system("which python", intern = TRUE, ignore.stderr = TRUE)),
    "C:/Python311/python.exe", "C:/Python312/python.exe", "C:/Python310/python.exe",
    "/usr/local/bin/python3", "/usr/bin/python3"
  )
  python_paths <- unique(na.omit(python_paths))
  python_found <- NULL
  for (path in python_paths) {
    if (!is.na(path) && file.exists(path) && !grepl("WindowsApps", path, ignore.case = TRUE)) {
      python_found <- path
      break
    }
  }
  if (!is.null(python_found)) {
    use_python(python_found, required = TRUE)
    cat("✅ Using Python at:", python_found, "\n")
  } else {
    py_config <- py_discover_config()
    viable_pythons <- py_config$python_versions[!grepl("WindowsApps", py_config$python_versions)]
    if (length(viable_pythons) > 0) {
      use_python(viable_pythons[1], required = TRUE)
      cat("✅ Automatically detected Python:", viable_pythons[1], "\n")
    } else {
      stop("❌ No Python found outside of WindowsApps. Please install Python from https://www.python.org/downloads/ and add it to PATH.")
    }
  }
  return(py_config())
}

#' Install the Python package copernicusmarine (internal use)
#'
#' @param py Python configuration object.
#' @return Invisible TRUE if the installation is successful.
#' @keywords internal
copernicus_install_package <- function(py) {
  tryCatch({
    reticulate::py_install("copernicusmarine", pip = TRUE)
    cat("   ✅ copernicusmarine installed\n")
  }, error = function(e) {
    cat("   ⚠️  Error installing copernicusmarine, attempting manual pip install...\n")
    system("pip install copernicusmarine")
  })
  invisible(TRUE)
}

#' Import the copernicusmarine Python module (internal use)
#'
#' @param py Python configuration object.
#' @return Imported copernicusmarine module.
#' @keywords internal
copernicus_import_module <- function(py) {
  tryCatch({
    reticulate::import("copernicusmarine")
  }, error = function(e) {
    stop("❌ Could not import copernicusmarine. Run: copernicus_reinstall_package()")
  })
}
