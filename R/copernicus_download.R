#' @title Download data from Copernicus Marine
#'
#' @description
#' Downloads .nc files from the Copernicus Marine catalog. Allows specifying all options of the Python function.
#'
#' @param dataset_id ID of the dataset (exact).
#' @param variables Vector or list of variables to download.
#' @param start_date Download start date (YYYY-MM-DD).
#' @param end_date Download end date (YYYY-MM-DD).
#' @param bbox Vector of 4 values (xmin, xmax, ymin, ymax) for the region.
#' @param depth Vector of 2 values: minimum and maximum depth.
#' @param dataset_version Dataset version.
#' @param output_file Output file. By default, generates one based on dates.
#' @param username Copernicus Marine username (optional, if no config file is used).
#' @param password Copernicus Marine password (optional).
#' @param verbose_download Show detailed messages.
#' @param ... Other extra arguments passed to the Python function.
#' @return Absolute path to the downloaded file, or NULL if it fails.
#' @examples
#' \dontrun{
#' copernicus_download(
#'   dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
#'   variables = "zos",
#'   start_date = "2025-06-01",
#'   end_date = "2025-06-09",
#'   username = "my_username", password = "my_password"
#' )
#' }
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

  # Check that the environment is configured
  copernicus_env <- .copernicus_env()
  if (!exists("cm", envir = copernicus_env)) {
    stop("❌ Copernicus Marine is not configured. Run setup_copernicus() first.")
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
    cat("🌊 Downloading:", dataset_id, "\n")
    cat("📅 Period:", start_date, "to", end_date, "\n")
    cat("📊 Variables:", paste(variables, collapse = ", "), "\n")
    cat("🗺️  Region: lon[", bbox[1], ",", bbox[2], "] lat[", bbox[3], ",", bbox[4], "]\n")
    if (!all(depth == c(0.494, 0.494))) {
      cat("🌊 Depth:", depth[1], "to", depth[2], "m\n")
    }
    cat("📁 File:", output_file, "\n")
    cat("⏳ Starting download...\n\n")
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
      output_filename = output_file
    )

    # Add credentials if provided
    if (!is.null(username)) args_py$username <- username
    if (!is.null(password)) args_py$password <- password

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
        cat("✅ Download successful!\n")
        cat("📊 Size:", size_mb, "MB\n")
        cat("⏱️  Time:", time_mins, "minutes\n")
        cat("📂 Location:", normalizePath(output_file), "\n")
      }

      return(normalizePath(output_file))
    } else {
      cat("❌ Error: File was not created\n")
      return(NULL)
    }

  }, error = function(e) {
    cat("❌ Download error:", e$message, "\n")

    # Specific help messages
    if (grepl("date|time", e$message, ignore.case = TRUE)) {
      cat("💡 Dates may not be available. Check:\n")
      cat("   • That the dates are in YYYY-MM-DD format\n")
      cat("   • That they fall within the dataset's temporal range\n")
      cat("   • Try more recent dates\n")
    } else if (grepl("variable", e$message, ignore.case = TRUE)) {
      cat("💡 Variable issue. Check:\n")
      cat("   • That the variables exist in this dataset\n")
      cat("   • Use copernicus_describe() to see available variables\n")
    } else if (grepl("credential|auth|login", e$message, ignore.case = TRUE)) {
      cat("💡 Authentication issue. Check:\n")
      cat("   • Your username and password\n")
      cat("   • The config file ~/.copernicusmarine/configuration_file.txt\n")
      cat("   • That your Copernicus Marine account is active\n")
    } else if (grepl("longitude|latitude|bbox|coordinates", e$message, ignore.case = TRUE)) {
      cat("💡 Coordinate issue. Check:\n")
      cat("   • That bbox is in [xmin, xmax, ymin, ymax] format\n")
      cat("   • That the coordinates are within the dataset's range\n")
      cat("   • Longitude: -180 to 180, Latitude: -90 to 90\n")
    } else if (grepl("depth", e$message, ignore.case = TRUE)) {
      cat("💡 Depth issue. Check:\n")
      cat("   • That the dataset has depth data\n")
      cat("   • That the values are within the available range\n")
    } else if (grepl("network|connection|timeout", e$message, ignore.case = TRUE)) {
      cat("💡 Connection issue. Try:\n")
      cat("   • Checking your internet connection\n")
      cat("   • Retrying the download later\n")
      cat("   • Reducing the download size\n")
    }

    return(NULL)
  })
}

#' @title Test Copernicus integration
#'
#' @description
#' Performs a small test download to validate that the whole system works.
#'
#' @param username Copernicus Marine username (optional).
#' @param password Copernicus Marine password (optional).
#' @return TRUE if the test was successful.
#' @export
copernicus_test <- function(username = NULL, password = NULL) {

  cat("🧪 Testing download from Copernicus Marine...\n")

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
    cat("✅ Test download successful!\n")
    cat("📊 File created:", basename(file), "(", file_size_kb, "KB)\n")
    cat("🧹 Cleaning up test file...\n")
    file.remove(file)
    return(TRUE)
  } else {
    cat("❌ Error in test download\n")
    cat("💡 Check your configuration with copernicus_is_ready()\n")
    return(FALSE)
  }
}


#' @title Check if Copernicus Marine Python module is ready
#'
#' @description
#' Checks if the Python module is properly loaded to use Copernicus Marine.
#' Returns TRUE if the module exists.
#'
#' @param verbose Show detailed status information.
#' @return TRUE if the Python module is loaded and ready.
#' @export
copernicus_is_ready <- function(verbose = TRUE) {

  copernicus_env <- .copernicus_env()

  # Check Python module
  module_ok <- exists("cm", envir = copernicus_env) && !is.null(get("cm", envir = copernicus_env))

  if (verbose) {
    cat("🔍 Checking Copernicus Marine environment:\n\n")

    if (module_ok) {
      cat("✅ Python module copernicusmarine: OK\n")
    } else {
      cat("❌ Python module copernicusmarine: NOT AVAILABLE\n")
      cat("💡 Run setup_copernicus() to configure\n")
    }

    cat("\n")

    if (module_ok) {
      cat("🎉 Ready to use Copernicus Marine!\n")
      cat("🧪 Run copernicus_test() for a test download\n")
    } else {
      cat("⚠️  Module not loaded\n")
      cat("1️⃣  Run: setup_copernicus()\n")
    }
  }

  return(module_ok)
}
