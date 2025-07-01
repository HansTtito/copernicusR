#' Copernicus private environment (internal use)
#'
#' This function creates and manages the internal environment where the package
#' stores persistent objects (e.g., Python module references, configurations, etc.).
#' Uses the package namespace to avoid global environment pollution while
#' providing robust handling for different execution contexts (normal use, testing, etc.).
#'
#' @return An environment object for internal package state management.
#' @keywords internal
.copernicus_env <- function() {
  # Get the package namespace environment
  ns <- getNamespace("copernicusR")

  # Check if our internal environment already exists in the namespace
  if (!exists(".copernicus_internal_env", envir = ns, inherits = FALSE)) {
    tryCatch({
      # Try to create the environment in the namespace
      assign(".copernicus_internal_env",
             new.env(parent = emptyenv()),
             envir = ns)
    }, error = function(e) {
      # If namespace is locked (e.g., during R CMD check),
      # fall back to a session-specific approach using options
      if (is.null(getOption("copernicusR.session.env"))) {
        session_env <- new.env(parent = emptyenv())
        options(copernicusR.session.env = session_env)
      }
    })
  }

  # Return the environment (prefer namespace, fallback to options)
  if (exists(".copernicus_internal_env", envir = ns, inherits = FALSE)) {
    return(get(".copernicus_internal_env", envir = ns))
  } else {
    # Fallback for locked namespace scenarios
    session_env <- getOption("copernicusR.session.env")
    if (is.null(session_env)) {
      session_env <- new.env(parent = emptyenv())
      options(copernicusR.session.env = session_env)
    }
    return(session_env)
  }
}

#' Reset internal environment (for testing and cleanup)
#' @keywords internal
.reset_copernicus_env <- function() {
  ns <- getNamespace("copernicusR")

  # Clear from namespace if possible
  if (exists(".copernicus_internal_env", envir = ns, inherits = FALSE)) {
    tryCatch({
      rm(".copernicus_internal_env", envir = ns)
    }, error = function(e) {
      # If can't remove from namespace, clear the environment contents
      env <- get(".copernicus_internal_env", envir = ns)
      rm(list = ls(envir = env), envir = env)
    })
  }

  # Clear session fallback
  options(copernicusR.session.env = NULL)

  invisible(TRUE)
}

.onLoad <- function(libname, pkgname) {
  # Initialize the internal environment when package loads
  # This ensures it's available before any functions are called
  .copernicus_env()

  invisible(TRUE)
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "copernicusR loaded. To get started:\n",
    "1. Ensure Python 3.7+ is installed\n",
    "2. Run setup_copernicus() to configure\n",
    "3. Get free account at: https://data.marine.copernicus.eu/register\n",
    "Use copernicus_is_ready() to check configuration."
  )
}

.onDetach <- function(libname) {
  # Clean up session-specific resources
  options(copernicusR.session.env = NULL)
  invisible(TRUE)
}

.onUnload <- function(libname) {
  # Comprehensive cleanup on package unload
  tryCatch({
    .reset_copernicus_env()
  }, error = function(e) {
    # Silently handle any cleanup errors
  })

  invisible(TRUE)
}
