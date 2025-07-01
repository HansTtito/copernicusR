#' @title Download data from Copernicus Marine
#'
#' @description
#' Downloads .nc files from the Copernicus Marine catalog. Allows specifying all options of the Python function.
#' Uses stored credentials from options/environment variables if available.
#'
#' @param dataset_id ID of the dataset (exact).
#' @param variables Vector or list of variables to download.
#' @param start_date Download start date (YYYY-MM-DD).
#' @param end_date Download end date (YYYY-MM-DD).
#' @param bbox Vector of 4 values (xmin, xmax, ymin, ymax) for the region.
#' @param depth Vector of 2 values: minimum and maximum depth.
#' @param dataset_version Dataset version.
#' @param output_file Output file. By default, generates one based on dates.
#' @param username Copernicus Marine username (optional, will try to get from stored credentials).
#' @param password Copernicus Marine password (optional, will try to get from stored credentials).
#' @param verbose_download Show detailed messages.
#' @param ... Other extra arguments passed to the Python function.
#' @return Absolute path to the downloaded file, or NULL if it fails.
#' @importFrom reticulate r_to_py
#' @export
copernicus_download <- function(dataset_id, variables, start_date, end_date,
                                bbox = c(-180, 179.92, -80, 90),
                                depth = c(0.494, 0.494),
                                dataset_version = "202406",
                                output_file = NULL,
                                username = NULL,
                                password = NULL,
                                verbose_download = TRUE,
                                ...) {

  # Get credentials using the centralized system
  credentials <- copernicus_get_credentials(mask_password = FALSE)

  # Use provided parameters or fall back to stored credentials
  if (is.null(username)) {
    username <- credentials$username
  }
  if (is.null(password)) {
    password <- credentials$password
  }

  # If still no credentials, prompt interactively
  if (is.null(username)) {
    cat("No username found in stored credentials.\n")
    username <- readline(prompt = "Enter your Copernicus Marine username: ")
  }
  if (is.null(password)) {
    cat("No password found in stored credentials.\n")
    if (requireNamespace("getPass", quietly = TRUE)) {
      password <- getPass::getPass("Enter your Copernicus Marine password: ")
    } else {
      password <- readline(prompt = "Enter your Copernicus Marine password: ")
    }
  }

  # Validate we have both credentials
  if (is.null(username) || is.null(password) || username == "" || password == "") {
    stop("Username and password are required. Use copernicus_setup_credentials() to store them.")
  }

  # Check that the environment is configured
  copernicus_env <- .copernicus_env()
  if (!exists("cm", envir = copernicus_env)) {
    stop("Copernicus Marine is not configured. Run setup_copernicus() first.")
  }

  cm <- get("cm", envir = copernicus_env)
  variables_py <- reticulate::r_to_py(as.list(variables))

  # Automatically generate output file name if not specified
  if (is.null(output_file)) {
    start_clean <- gsub("-", "", start_date)
    end_clean <- gsub("-", "", end_date)
    output_file <- paste0("copernicus_", start_clean, "-", end_clean, ".nc")
  }

  # Create output directory if it doesn't exist
  output_dir <- dirname(output_file)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  if (verbose_download) {
    cat("Downloading:", dataset_id, "\n")
    cat("Period:", start_date, "to", end_date, "\n")
    cat("Variables:", paste(variables, collapse = ", "), "\n")
    cat("Region: lon[", bbox[1], ",", bbox[2], "] lat[", bbox[3], ",", bbox[4], "]\n")
    if (!all(depth == c(0.494, 0.494))) {
      cat("Depth:", depth[1], "to", depth[2], "m\n")
    }
    cat("File:", output_file, "\n")
    cat("Starting download...\n\n")
  }

  start_time <- Sys.time()

  tryCatch({
    args_py <- list(
      dataset_id = dataset_id,
      dataset_version = dataset_version,
      variables = variables_py,
      start_datetime = paste0(start_date, "T00:00:00"),
      end_datetime = paste0(end_date, "T00:00:00"),
      minimum_longitude = bbox[1],
      maximum_longitude = bbox[2],
      minimum_latitude = bbox[3],
      maximum_latitude = bbox[4],
      minimum_depth = depth[1],
      maximum_depth = depth[2],
      coordinates_selection_method = "strict-inside",
      output_filename = output_file,
      username = username,
      password = password
    )

    # Add additional arguments
    dots <- list(...)
    if (length(dots) > 0) args_py <- c(args_py, dots)

    # Execute download
    result <- do.call(cm$subset, args_py)
    end_time <- Sys.time()

    # Check if download was successful
    if (file.exists(output_file)) {
      size_mb <- round(file.size(output_file) / 1024 / 1024, 2)
      time_mins <- round(difftime(end_time, start_time, units = "mins"), 2)

      if (verbose_download) {
        cat("Download successful!\n")
        cat("Size:", size_mb, "MB\n")
        cat("Time:", time_mins, "minutes\n")
        cat("Location:", normalizePath(output_file), "\n")
      }

      return(normalizePath(output_file))
    } else {
      cat("Error: File was not created\n")
      return(NULL)
    }

  }, error = function(e) {
    cat("Download error:", e$message, "\n")

    # Specific help messages
    if (grepl("date|time", e$message, ignore.case = TRUE)) {
      cat("Dates may not be available. Check:\n")
      cat("   \u2022 That the dates are in YYYY-MM-DD format\n")
      cat("   \u2022 That they fall within the dataset's temporal range\n")
      cat("   \u2022 Try more recent dates\n")
    } else if (grepl("variable", e$message, ignore.case = TRUE)) {
      cat("Variable issue. Check:\n")
      cat("   \u2022 That the variables exist in this dataset\n")
      cat("   \u2022 Use copernicus_describe() to see available variables\n")
    } else if (grepl("credential|auth|login", e$message, ignore.case = TRUE)) {
      cat("Authentication issue. Check your username/password.\n")
    } else if (grepl("longitude|latitude|bbox|coordinates", e$message, ignore.case = TRUE)) {
      cat("Coordinate issue. Check:\n")
      cat("   \u2022 That bbox is in [xmin, xmax, ymin, ymax] format\n")
      cat("   \u2022 That the coordinates are within the dataset's range\n")
      cat("   \u2022 Longitude: -180 to 180, Latitude: -90 to 90\n")
    } else if (grepl("depth", e$message, ignore.case = TRUE)) {
      cat("Depth issue. Check:\n")
      cat("   \u2022 That the dataset has depth data\n")
      cat("   \u2022 That the values are within the available range\n")
    } else if (grepl("network|connection|timeout", e$message, ignore.case = TRUE)) {
      cat("Connection issue. Try:\n")
      cat("   \u2022 Checking your internet connection\n")
      cat("   \u2022 Retrying the download later\n")
      cat("   \u2022 Reducing the download size\n")
    }

    return(NULL)
  })
}

#' @title Test Copernicus integration
#'
#' @description
#' Performs a small test download to validate that the whole system works.
#' Uses stored credentials if available.
#'
#' @param username Copernicus Marine username (optional). Will try to get from stored credentials first.
#' @param password Copernicus Marine password (optional). Will try to get from stored credentials first.
#' @return TRUE if the test was successful.
#' @export
copernicus_test <- function(username = NULL, password = NULL) {
  cat("Testing download from Copernicus Marine...\n")

  # Get credentials using the centralized system
  credentials <- copernicus_get_credentials(mask_password = FALSE)

  # Use provided parameters or fall back to stored credentials
  if (is.null(username)) {
    username <- credentials$username
  }
  if (is.null(password)) {
    password <- credentials$password
  }

  # If still no credentials, prompt interactively
  if (is.null(username)) {
    cat("No username found in stored credentials.\n")
    username <- readline(prompt = "Enter your Copernicus Marine username: ")
  }
  if (is.null(password)) {
    cat("No password found in stored credentials.\n")
    if (requireNamespace("getPass", quietly = TRUE)) {
      password <- getPass::getPass("Enter your Copernicus Marine password: ")
    } else {
      password <- readline(prompt = "Enter your Copernicus Marine password: ")
    }
  }

  # Validate we have both credentials
  if (is.null(username) || is.null(password) || username == "" || password == "") {
    cat("Username and password are required.\n")
    cat("Use copernicus_setup_credentials() to store them.\n")
    return(FALSE)
  }

  # Use date from 3 days ago for higher chance of success
  test_date <- as.character(Sys.Date() - 3)

  file <- copernicus_download(
    dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
    variables = "zos",
    start_date = test_date,
    end_date = test_date,
    bbox = c(0, 1, 40, 41),
    output_file = "test_copernicus_download.nc",
    username = username,
    password = password,
    verbose_download = FALSE
  )

  if (!is.null(file) && file.exists(file)) {
    file_size_kb <- round(file.size(file) / 1024, 1)
    cat("Test download successful!\n")
    cat("File created:", basename(file), "(", file_size_kb, "KB)\n")
    cat("Cleaning up test file...\n")
    file.remove(file)
    return(TRUE)
  } else {
    cat("Error in test download\n")
    cat("Check your configuration with copernicus_is_ready()\n")
    return(FALSE)
  }
}

#' @title Check if Copernicus Marine Python module is ready
#'
#' @description
#' Checks if the Python module is properly loaded and credentials are configured
#' to use Copernicus Marine. Returns TRUE if everything is ready.
#'
#' @param verbose Show detailed status information.
#' @return TRUE if the Python module is loaded and credentials are available.
#' @export
copernicus_is_ready <- function(verbose = TRUE) {

  copernicus_env <- .copernicus_env()

  # Check Python module
  module_ok <- exists("cm", envir = copernicus_env) && !is.null(get("cm", envir = copernicus_env))

  # Check credentials
  credentials <- copernicus_get_credentials(mask_password = FALSE)
  credentials_ok <- !is.null(credentials$username) && !is.null(credentials$password)

  if (verbose) {
    cat("Checking Copernicus Marine environment:\n\n")

    # Python module status
    if (module_ok) {
      cat("Python module copernicusmarine: OK\n")
    } else {
      cat("Python module copernicusmarine: NOT AVAILABLE\n")
      cat("Run setup_copernicus() to configure\n")
    }

    # Credentials status
    if (credentials_ok) {
      cat("Credentials configured for user:", credentials$username, "\n")
    } else {
      cat("Credentials: NOT CONFIGURED\n")
      cat("Run copernicus_setup_credentials() to configure\n")
    }

    cat("\n")

    if (module_ok && credentials_ok) {
      cat("Ready to use Copernicus Marine!\n")
      cat("Run copernicus_test() for a test download\n")
    } else {
      cat("Setup incomplete:\n")
      if (!module_ok) {
        cat("1. Run: setup_copernicus()\n")
      }
      if (!credentials_ok) {
        cat("2. Run: copernicus_setup_credentials('username', 'password')\n")
      }
    }
  }

  return(module_ok && credentials_ok)
}
