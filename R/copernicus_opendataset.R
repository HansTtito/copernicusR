#' @title Open dataset from Copernicus Marine without download
#'
#' @description
#' Opens a dataset directly from Copernicus Marine using open_dataset.
#' Returns a Python xarray.Dataset object that can be processed in R.
#' Useful for exploring data without downloading full files.
#' Uses stored credentials from options/environment variables if available.
#'
#' @param dataset_id ID of the dataset (exact).
#' @param variables Vector or list of variables to open. If NULL, opens all.
#' @param start_date Start date (YYYY-MM-DD). Optional.
#' @param end_date End date (YYYY-MM-DD). Optional.
#' @param bbox Vector of 4 values (xmin, xmax, ymin, ymax) for the region. Optional.
#' @param depth Vector of 2 values: minimum and maximum depth. Optional.
#' @param dataset_version Dataset version. Optional.
#' @param username Copernicus Marine username (optional, will try to get from stored credentials).
#' @param password Copernicus Marine password (optional, will try to get from stored credentials).
#' @param verbose_open Show detailed messages.
#' @param ... Other extra arguments passed to the Python function.
#' @return Python xarray.Dataset object, or NULL if it fails.
#' @export
copernicus_open_dataset <- function(dataset_id,
                                    variables = NULL,
                                    start_date = NULL,
                                    end_date = NULL,
                                    bbox = NULL,
                                    depth = NULL,
                                    dataset_version = NULL,
                                    username = NULL,
                                    password = NULL,
                                    verbose_open = TRUE,
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

  # Convert variables to Python format if specified
  variables_py <- NULL
  if (!is.null(variables)) {
    variables_py <- reticulate::r_to_py(as.list(variables))
  }

  if (verbose_open) {
    cat("Opening dataset:", dataset_id, "\n")
    if (!is.null(variables)) {
      cat("Variables:", paste(variables, collapse = ", "), "\n")
    } else {
      cat("Variables: all available\n")
    }
    if (!is.null(start_date) || !is.null(end_date)) {
      cat("Period:", start_date, "to", end_date, "\n")
    }
    if (!is.null(bbox)) {
      cat("Region: lon[", bbox[1], ",", bbox[2], "] lat[", bbox[3], ",", bbox[4], "]\n")
    }
    if (!is.null(depth)) {
      cat("Depth:", depth[1], "to", depth[2], "m\n")
    }
    cat("Connecting to Copernicus Marine...\n\n")
  }

  start_time <- Sys.time()

  tryCatch({
    # Build arguments for open_dataset
    args_py <- list(dataset_id = dataset_id)

    # Add optional arguments only if specified
    if (!is.null(variables_py)) args_py$variables <- variables_py
    if (!is.null(dataset_version)) args_py$dataset_version <- dataset_version

    # Temporal filters
    if (!is.null(start_date)) args_py$start_datetime <- paste0(start_date, "T00:00:00")
    if (!is.null(end_date)) args_py$end_datetime <- paste0(end_date, "T00:00:00")

    # Spatial filters
    if (!is.null(bbox)) {
      args_py$minimum_longitude <- bbox[1]
      args_py$maximum_longitude <- bbox[2]
      args_py$minimum_latitude <- bbox[3]
      args_py$maximum_latitude <- bbox[4]
    }

    # Depth filters
    if (!is.null(depth)) {
      args_py$minimum_depth <- depth[1]
      args_py$maximum_depth <- depth[2]
    }

    # Credentials
    args_py$username <- username
    args_py$password <- password

    # Additional arguments
    dots <- list(...)
    if (length(dots) > 0) args_py <- c(args_py, dots)

    # Call open_dataset
    dataset <- do.call(cm$open_dataset, args_py)

    end_time <- Sys.time()
    time_secs <- round(difftime(end_time, start_time, units = "secs"), 2)

    if (verbose_open) {
      cat("Dataset successfully opened!\n")
      cat("Connection time:", time_secs, "seconds\n")
      cat("Use reticulate::py_to_r() to convert to R if needed\n")
    }

    return(dataset)

  }, error = function(e) {
    cat("Error opening dataset:", e$message, "\n")

    # Specific help messages
    if (grepl("date|time", e$message, ignore.case = TRUE)) {
      cat("Dates may not be available. Check the dataset's temporal range.\n")
    } else if (grepl("variable", e$message, ignore.case = TRUE)) {
      cat("Some variable may not exist in this dataset. Use copernicus_describe() to see available variables.\n")
    } else if (grepl("credential|auth", e$message, ignore.case = TRUE)) {
      cat("Authentication issue. Check your username/password.\n")
    } else if (grepl("longitude|latitude|bbox", e$message, ignore.case = TRUE)) {
      cat("Check that the bbox coordinates are within the dataset's range.\n")
    } else if (grepl("depth", e$message, ignore.case = TRUE)) {
      cat("Depth issue. Check:\n")
      cat("That the dataset has depth data\n")
      cat("That the values are within the available range\n")
    } else if (grepl("network|connection|timeout", e$message, ignore.case = TRUE)) {
      cat("Connection issue. Try:\n")
      cat("Checking your internet connection\n")
      cat("Retrying the connection later\n")
    }

    return(NULL)
  })
}

#' @title Test opening of Copernicus dataset
#'
#' @description
#' Performs a test dataset opening to validate that the open_dataset function works.
#' Uses stored credentials if available.
#'
#' @param username Copernicus Marine username (optional, will try to get from stored credentials first).
#' @param password Copernicus Marine password (optional, will try to get from stored credentials first).
#' @return TRUE if the test was successful.
#' @export
copernicus_test_open <- function(username = NULL, password = NULL) {

  cat("Testing dataset opening...\n")

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

  dataset <- copernicus_open_dataset(
    dataset_id = "cmems_mod_glo_phy_anfc_0.083deg_P1D-m",
    variables = "zos",
    bbox = c(0, 1, 40, 41),
    username = username,
    password = password,
    verbose_open = FALSE
  )

  if (!is.null(dataset)) {
    cat("open_dataset working perfectly!\n")
    cat("Dataset connected successfully\n")
    return(TRUE)
  } else {
    cat("Error in open_dataset test\n")
    return(FALSE)
  }
}
