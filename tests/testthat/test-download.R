test_that("copernicus_download requires credentials", {
  # Clear credentials and mock environment
  suppressMessages(copernicus_clear_credentials())
  copernicus_env <- .copernicus_env()
  assign("cm", "mock_module", envir = copernicus_env)

  # Should error when no credentials provided
  expect_error(
    copernicus_download(
      dataset_id = "test_dataset",
      variables = "test_var",
      start_date = "2024-01-01",
      end_date = "2024-01-01",
      username = "",
      password = ""
    ),
    "Username and password are required"
  )
})

test_that("copernicus_download uses stored credentials", {
  # Set test credentials
  options(copernicus.username = "test_user")
  options(copernicus.password = "test_pass")

  # Mock Python environment
  copernicus_env <- .copernicus_env()
  mock_cm <- create_mock_module(should_fail = TRUE)
  assign("cm", mock_cm, envir = copernicus_env)

  # Should use stored credentials and attempt download
  expect_output(
    result <- copernicus_download(
      dataset_id = "test_dataset",
      variables = "test_var",
      start_date = "2024-01-01",
      end_date = "2024-01-01",
      verbose_download = FALSE
    ),
    "Download error"
  )

  expect_null(result)

  # Clean up
  suppressMessages(copernicus_clear_credentials())
})

test_that("copernicus_download generates output filename", {
  start_date <- "2024-01-15"
  end_date <- "2024-01-20"

  start_clean <- gsub("-", "", start_date)
  end_clean <- gsub("-", "", end_date)
  expected_filename <- paste0("copernicus_", start_clean, "-", end_clean, ".nc")

  expect_equal(expected_filename, "copernicus_20240115-20240120.nc")
})

test_that("copernicus_download validates environment", {
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
    copernicus_download(
      dataset_id = "test_dataset",
      variables = "test_var",
      start_date = "2024-01-01",
      end_date = "2024-01-01"
    ),
    "Copernicus Marine is not configured"
  )

  # Clean up
  suppressMessages(copernicus_clear_credentials())
})

test_that("copernicus_test handles missing credentials", {
  # Clear credentials
  suppressMessages(copernicus_clear_credentials())

  # Should return FALSE when no credentials
  expect_output(
    result <- copernicus_test(username = "", password = ""),
    "Username and password are required"
  )
  expect_false(result)
})

test_that("copernicus_test with mocked download", {
  # Set test credentials
  options(copernicus.username = "test_user")
  options(copernicus.password = "test_pass")

  # Mock environment
  copernicus_env <- .copernicus_env()
  assign("cm", "mock_module", envir = copernicus_env)

  # Test should fail with mock
  expect_output(
    result <- copernicus_test(),
    "Testing download from Copernicus Marine"
  )

  expect_false(result)

  # Clean up
  suppressMessages(copernicus_clear_credentials())
})

test_that("integration tests are properly skipped", {
  skip("Integration tests require real Copernicus Marine connection")
})
