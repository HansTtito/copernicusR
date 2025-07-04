% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/setup_copernicus.R
\name{copernicus_setup_credentials}
\alias{copernicus_setup_credentials}
\title{Configure Copernicus Marine credentials}
\usage{
copernicus_setup_credentials(
  username = NULL,
  password = NULL,
  store_credentials = TRUE,
  prompt_if_missing = interactive()
)
}
\arguments{
\item{username}{Character. Copernicus Marine username. If NULL, tries other methods.}

\item{password}{Character. Copernicus Marine password. If NULL, tries other methods.}

\item{store_credentials}{Logical. Store credentials in session options? Default: TRUE.}

\item{prompt_if_missing}{Logical. Prompt user for credentials if not found? Default: TRUE.}
}
\value{
Invisible list with username and password (password is masked).
}
\description{
Sets up Copernicus Marine Service credentials using various methods:
\enumerate{
\item Function parameters
\item R session options
\item Environment variables
\item Interactive prompt (if none found)
}
}
\examples{
\dontrun{
# Set credentials directly
copernicus_setup_credentials("username", "password")

# Set credentials and store in options
copernicus_setup_credentials("username", "password", store_credentials = TRUE)

# Try to get from environment/options
copernicus_setup_credentials()
}
}
