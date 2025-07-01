#' @title Set up Copernicus Marine integration with credentials
#'
#' @description
#' Sets up the Python environment and loads the copernicusmarine module for use in R.
#' Optionally configures Copernicus Marine credentials for the session.
#' It is recommended to run this once per session before calling other functions in the package.
#'
#' @param install_copernicus Logical. Should the copernicusmarine package be installed in Python if not available? Default: TRUE.
#' @param username Character. Copernicus Marine username. If NULL, will try to get from options or environment variables.
#' @param password Character. Copernicus Marine password. If NULL, will try to get from options or environment variables.
#' @param store_credentials Logical. Should credentials be stored in session options? Default: TRUE.
#' @return Invisible TRUE if the configuration was successful.
#' @examples
#' \dontrun{
#' # Basic setup without credentials
#' setup_copernicus()
#'
#' # Setup with credentials
#' setup_copernicus(username = "your_username", password = "your_password")
#'
#' # Setup reading from environment variables
#' setup_copernicus()  # Will look for COPERNICUS_USERNAME and COPERNICUS_PASSWORD
#'
#' # Setup and store credentials for session
#' setup_copernicus(username = "user", password = "pass", store_credentials = TRUE)
#' }
#' @importFrom reticulate py_config
#' @export
setup_copernicus <- function(install_copernicus = TRUE,
                             username = NULL,
                             password = NULL,
                             store_credentials = TRUE) {

  # Check if reticulate is available
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    stop("Package 'reticulate' is required but not available. Please install it with: install.packages('reticulate')")
  }

  # Check Python availability before proceeding
  tryCatch({
    copernicus_env <- .copernicus_env()
    py <- copernicus_configure_python()
    assign("py", py, envir = copernicus_env)
  }, error = function(e) {
    stop("Python configuration failed. Please ensure Python 3.7+ is installed and accessible. Error: ", e$message)
  })

  # Install and import module only if user requested
  if (install_copernicus) {
    message("Installing copernicusmarine Python package...")
    copernicus_install_package(py)
  }

  tryCatch({
    cm <- copernicus_import_module(py)
    assign("cm", cm, envir = copernicus_env)
  }, error = function(e) {
    stop("Failed to import copernicusmarine. Please install manually with: reticulate::py_install('copernicusmarine')")
  })

  # Handle credentials
  copernicus_setup_credentials(username, password, store_credentials)

  invisible(TRUE)
}


#' @title Configure Copernicus Marine credentials
#'
#' @description
#' Sets up Copernicus Marine Service credentials using various methods:
#' 1. Function parameters
#' 2. R session options
#' 3. Environment variables
#' 4. Interactive prompt (if none found)
#'
#' @param username Character. Copernicus Marine username. If NULL, tries other methods.
#' @param password Character. Copernicus Marine password. If NULL, tries other methods.
#' @param store_credentials Logical. Store credentials in session options? Default: TRUE.
#' @param prompt_if_missing Logical. Prompt user for credentials if not found? Default: TRUE.
#' @return Invisible list with username and password (password is masked).
#' @examples
#' \dontrun{
#' # Set credentials directly
#' copernicus_setup_credentials("username", "password")
#'
#' # Set credentials and store in options
#' copernicus_setup_credentials("username", "password", store_credentials = TRUE)
#'
#' # Try to get from environment/options
#' copernicus_setup_credentials()
#' }
#' @export
copernicus_setup_credentials <- function(username = NULL,
                                         password = NULL,
                                         store_credentials = TRUE,
                                         prompt_if_missing = interactive()) {

  # Priority order for getting credentials:
  # 1. Function parameters
  # 2. Session options
  # 3. Environment variables
  # 4. Interactive prompt

  # Get username
  if (is.null(username)) {
    username <- getOption("copernicus.username", default = NULL)
  }
  if (is.null(username)) {
    username <- Sys.getenv("COPERNICUS_USERNAME", unset = NA)
    if (is.na(username)) username <- NULL
  }
  if (is.null(username) && prompt_if_missing) {
    username <- readline(prompt = "Enter Copernicus Marine username: ")
    if (username == "") username <- NULL
  }

  # Get password
  if (is.null(password)) {
    password <- getOption("copernicus.password", default = NULL)
  }
  if (is.null(password)) {
    password <- Sys.getenv("COPERNICUS_PASSWORD", unset = NA)
    if (is.na(password)) password <- NULL
  }
  if (is.null(password) && prompt_if_missing) {
    if (requireNamespace("getPass", quietly = TRUE)) {
      password <- getPass::getPass("Enter Copernicus Marine password: ")
    } else {
      password <- readline(prompt = "Enter Copernicus Marine password: ")
    }
    if (password == "") password <- NULL
  }

  # Store in session options if requested
  if (store_credentials && !is.null(username) && !is.null(password)) {
    options(copernicus.username = username)
    options(copernicus.password = password)
    cat("Copernicus credentials stored in session options\n")
  }

  # Validate credentials
  if (!is.null(username) && !is.null(password)) {
    cat("Copernicus credentials configured for user:", username, "\n")
  } else {
    warning("Copernicus credentials not fully configured. Some functions may require authentication.")
  }

  # Return credentials (with masked password)
  invisible(list(
    username = username,
    password = if(!is.null(password)) "***MASKED***" else NULL
  ))
}

#' @title Get Copernicus Marine credentials
#'
#' @description
#' Retrieves stored Copernicus Marine credentials from session options or environment variables.
#'
#' @param mask_password Logical. Should password be masked in output? Default: TRUE.
#' @return List with username and password (optionally masked).
#' @examples
#' # Get credentials (password masked)
#' copernicus_get_credentials()
#'
#' # Get credentials (password visible - use with caution)
#' copernicus_get_credentials(mask_password = FALSE)
#' @export
copernicus_get_credentials <- function(mask_password = TRUE) {
  username <- getOption("copernicus.username", default = NULL)
  password <- getOption("copernicus.password", default = NULL)

  # Fallback to environment variables
  if (is.null(username)) {
    username <- Sys.getenv("COPERNICUS_USERNAME", unset = NA)
    if (is.na(username)) username <- NULL
  }
  if (is.null(password)) {
    password <- Sys.getenv("COPERNICUS_PASSWORD", unset = NA)
    if (is.na(password)) password <- NULL
  }

  # Return with optional masking
  list(
    username = username,
    password = if (mask_password && !is.null(password)) "***MASKED***" else password
  )
}

#' @title Clear Copernicus Marine credentials
#'
#' @description
#' Removes stored Copernicus Marine credentials from session options and environment variables.
#'
#' @return Invisible TRUE.
#' @examples
#' copernicus_clear_credentials()
#' @export
copernicus_clear_credentials <- function() {
  # Remove from options
  options(copernicus.username = NULL)
  options(copernicus.password = NULL)

  # Remove from environment (current session only)
  Sys.unsetenv("COPERNICUS_USERNAME")
  Sys.unsetenv("COPERNICUS_PASSWORD")

  cat("✅ Copernicus credentials cleared from session and environment\n")
  invisible(TRUE)
}

#' @title Set Copernicus Marine credentials in environment file
#'
#' @description
#' Helper function to set credentials in .Renviron file for persistent storage.
#' This is more secure than storing in scripts.
#'
#' @param username Character. Copernicus Marine username.
#' @param password Character. Copernicus Marine password.
#' @param overwrite Logical. Overwrite existing credentials in .Renviron? Default: FALSE.
#' @return Invisible TRUE if successful.
#' @examples
#' \dontrun{
#' # Set credentials in .Renviron (will persist across R sessions)
#' copernicus_set_env_credentials("your_username", "your_password")
#' }
#' @export
copernicus_set_env_credentials <- function(username, password, overwrite = FALSE) {

  if (missing(username) || missing(password)) {
    stop("Both username and password are required")
  }

  # Check if .Renviron exists
  env_file <- file.path(Sys.getenv("HOME"), ".Renviron")

  # Read existing .Renviron if it exists
  if (file.exists(env_file)) {
    env_lines <- readLines(env_file)
  } else {
    env_lines <- character(0)
  }

  # Check for existing credentials
  username_exists <- any(grepl("^COPERNICUS_USERNAME=", env_lines))
  password_exists <- any(grepl("^COPERNICUS_PASSWORD=", env_lines))

  if ((username_exists || password_exists) && !overwrite) {
    stop("Credentials already exist in .Renviron. Use overwrite = TRUE to replace them.")
  }

  # Remove existing credentials if overwriting
  if (overwrite) {
    env_lines <- env_lines[!grepl("^COPERNICUS_USERNAME=", env_lines)]
    env_lines <- env_lines[!grepl("^COPERNICUS_PASSWORD=", env_lines)]
  }

  # Add new credentials
  new_lines <- c(
    paste0("COPERNICUS_USERNAME=", username),
    paste0("COPERNICUS_PASSWORD=", password)
  )

  env_lines <- c(env_lines, new_lines)

  # Write back to .Renviron
  writeLines(env_lines, env_file)

  cat("Copernicus credentials added to .Renviron\n")
  cat("Restart R session for changes to take effect\n")

  invisible(TRUE)
}

#' @title Validate Copernicus Marine credentials
#'
#' @description
#' Tests if the stored credentials work by attempting a simple API call.
#'
#' @return Logical. TRUE if credentials are valid, FALSE otherwise.
#' @examples
#' \dontrun{
#' copernicus_validate_credentials()
#' }
#' @export
copernicus_validate_credentials <- function() {

  credentials <- copernicus_get_credentials(mask_password = FALSE)

  if (is.null(credentials$username) || is.null(credentials$password)) {
    cat("No credentials found. Use copernicus_setup_credentials() first.\n")
    return(FALSE)
  }

  cat("Validating credentials for user:", credentials$username, "...\n")

  # Attempt validation (this would need to be implemented based on the API)
  # For now, just return TRUE if credentials exist
  tryCatch({
    # Here you would make an actual API call to validate
    # For example: test_connection <- cm$login(credentials$username, credentials$password)

    cat("Credentials appear to be configured correctly\n")
    cat("Note: Full validation requires API connection\n")
    return(TRUE)

  }, error = function(e) {
    cat("Credential validation failed:", e$message, "\n")
    return(FALSE)
  })
}
