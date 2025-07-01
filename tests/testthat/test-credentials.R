
test_that("copernicus_clear_credentials works", {
  # Set some test credentials first
  options(copernicus.username = "test_user")
  options(copernicus.password = "test_pass")

  # Clear credentials
  expect_output(copernicus_clear_credentials(), "Copernicus credentials cleared")

  # Check they're cleared
  expect_null(getOption("copernicus.username"))
  expect_null(getOption("copernicus.password"))
})

test_that("copernicus_get_credentials retrieves stored credentials", {
  # Clear first
  suppressMessages(copernicus_clear_credentials())

  # Set test credentials in options
  options(copernicus.username = "test_user")
  options(copernicus.password = "test_pass")

  # Get credentials (masked)
  creds_masked <- copernicus_get_credentials(mask_password = TRUE)
  expect_equal(creds_masked$username, "test_user")
  expect_equal(creds_masked$password, "***MASKED***")

  # Get credentials (unmasked)
  creds_unmasked <- copernicus_get_credentials(mask_password = FALSE)
  expect_equal(creds_unmasked$username, "test_user")
  expect_equal(creds_unmasked$password, "test_pass")

  # Clean up
  suppressMessages(copernicus_clear_credentials())
})

test_that("copernicus_get_credentials falls back to environment variables", {
  # Clear options
  suppressMessages(copernicus_clear_credentials())

  # Use withr for environment isolation
  withr::with_envvar(
    c(COPERNICUS_USERNAME = "env_user", COPERNICUS_PASSWORD = "env_pass"),
    {
      # Get credentials
      creds <- copernicus_get_credentials(mask_password = FALSE)
      expect_equal(creds$username, "env_user")
      expect_equal(creds$password, "env_pass")
    }
  )
})

test_that("copernicus_setup_credentials stores credentials correctly", {
  # Clear first
  suppressMessages(copernicus_clear_credentials())

  # Setup credentials without prompting
  expect_output(
    copernicus_setup_credentials("test_user", "test_pass",
                                 store_credentials = TRUE,
                                 prompt_if_missing = FALSE),
    "Copernicus credentials configured"
  )

  # Check they're stored
  expect_equal(getOption("copernicus.username"), "test_user")
  expect_equal(getOption("copernicus.password"), "test_pass")

  # Clean up
  suppressMessages(copernicus_clear_credentials())
})

# CORRECCIÓN: Test con estado limpio aislado
test_with_clean_state("copernicus_setup_credentials handles missing credentials", {
  # Setup without credentials and without prompting
  expect_warning(
    copernicus_setup_credentials(prompt_if_missing = FALSE),
    "Copernicus credentials not fully configured"
  )
})

# CORRECCIÓN: Test con estado limpio aislado
test_with_clean_state("copernicus_validate_credentials handles missing credentials", {
  # Should return FALSE with no credentials
  expect_output(
    result <- copernicus_validate_credentials(),
    "No credentials found"
  )
  expect_false(result)
})

test_that("copernicus_validate_credentials works with stored credentials", {
  # Set test credentials
  options(copernicus.username = "test_user")
  options(copernicus.password = "test_pass")

  # Should return TRUE (mock validation)
  expect_output(
    result <- copernicus_validate_credentials(),
    "Credentials appear to be configured correctly"
  )
  expect_true(result)

  # Clean up
  suppressMessages(copernicus_clear_credentials())
})

test_that("copernicus_set_env_credentials validates input", {
  # Should error with missing arguments
  expect_error(
    copernicus_set_env_credentials(),
    "Both username and password are required"
  )

  expect_error(
    copernicus_set_env_credentials("user"),
    "Both username and password are required"
  )
})
