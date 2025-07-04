% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/zzz.R
\name{.copernicus_env}
\alias{.copernicus_env}
\title{Copernicus private environment (internal use)}
\usage{
.copernicus_env()
}
\value{
An environment object for internal package state management.
}
\description{
This function creates and manages the internal environment where the package
stores persistent objects (e.g., Python module references, configurations, etc.).
Uses the package namespace to avoid global environment pollution while
providing robust handling for different execution contexts (normal use, testing, etc.).
}
\keyword{internal}
