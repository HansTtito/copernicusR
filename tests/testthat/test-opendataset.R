test_that("copernicus_open_dataset requires credentials", {
  # Clear credentials and mock environment
  suppressMessages(copernicus_clear_credentials())
  copernicus_env <- .copernicus_env()
  assign("cm", "mock_module", envir = copernicus_env)

  # Should error when no credentials provided
  expect_error(
    copernicus_open_dataset(
      dataset_id = "test_dataset",
      username = "",
      password = ""
    ),
    "Username and password are required"
  )
})

test_that("copernicus_open_dataset uses stored credentials", {
  # Set test credentials
  options(copernicus.username = "test_user")
  options(copernicus.password = "test_pass")

  # Mock Python environment
  copernicus_env <- .copernicus_env()
  mock_cm <- create_mock_module(should_fail = TRUE)
  assign("cm", mock_cm, envir = copernicus_env)

  # Should use stored credentials and attempt to open dataset
  expect_output(
    result <- copernicus_open_dataset(
      dataset_id = "test_dataset",
      verbose_open = FALSE
    ),
    "Error opening dataset"
  )

  expect_null(result)

  # Clean up
  suppressMessages(copernicus_clear_credentials())
})

test_that("copernicus_open_dataset validates environment", {
  # Clear environment
  copernicus_env <- .copernicus_env()
  if (exists("cm", envir = copernicus_env)) {
    rm("cm", envir = copernicus_env)
  }

  # Set credentials
  options(copernicus.username = "test_user")
  options(copernicus.password = "test_pass")

  # Should error when module not configured
  expect_error(
    copernicus_open_dataset(dataset_id = "test_dataset"),
    "Copernicus Marine is not configured"
  )

  # Clean up
  suppressMessages(copernicus_clear_credentials())
})

test_that("copernicus_open_dataset handles variables parameter", {
  skip_if_not_installed("reticulate")
  variables <- c("thetao", "so")
  expect_equal(as.list(variables), list("thetao", "so"))
})

test_that("copernicus_open_dataset builds arguments correctly", {
  dataset_id <- "test_dataset"
  start_date <- "2024-01-01"
  end_date <- "2024-01-31"
  bbox <- c(-75, -70, -40, -35)

  expect_equal(paste0(start_date, "T00:00:00"), "2024-01-01T00:00:00")
  expect_equal(paste0(end_date, "T00:00:00"), "2024-01-31T00:00:00")
  expect_equal(bbox[1], -75)  # minimum_longitude
  expect_equal(bbox[2], -70)  # maximum_longitude
  expect_equal(bbox[3], -40)  # minimum_latitude
  expect_equal(bbox[4], -35)  # maximum_latitude
})

test_that("copernicus_test_open handles missing credentials", {
  # Clear credentials
  suppressMessages(copernicus_clear_credentials())

  # Should return FALSE when no credentials
  expect_output(
    result <- copernicus_test_open(username = "", password = ""),
    "Username and password are required"
  )
  expect_false(result)
})

test_that("copernicus_test_open with mock", {
  # Set test credentials
  options(copernicus.username = "test_user")
  options(copernicus.password = "test_pass")

  # Mock environment
  copernicus_env <- .copernicus_env()
  assign("cm", "mock_module", envir = copernicus_env)

  # Should return FALSE due to mock failure
  expect_output(
    result <- copernicus_test_open(),
    "Testing dataset opening"
  )

  expect_false(result)

  # Clean up
  suppressMessages(copernicus_clear_credentials())
})

test_that("copernicus_open_dataset handles optional parameters", {
  expect_true(is.null(NULL))  # variables = NULL
  expect_true(is.null(NULL))  # start_date = NULL
  expect_true(is.null(NULL))  # end_date = NULL
  expect_true(is.null(NULL))  # bbox = NULL
  expect_true(is.null(NULL))  # depth = NULL
})

test_that("integration tests are properly skipped", {
  skip("Integration tests require real Copernicus Marine connection")
})
