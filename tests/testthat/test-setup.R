test_that(".copernicus_env creates and returns environment", {
  # Get environment (should create it)
  env1 <- copernicusR:::.copernicus_env()
  expect_true(is.environment(env1))

  # Get it again (should return same environment)
  env2 <- copernicusR:::.copernicus_env()
  expect_identical(env1, env2)

  # Verify environment works by storing and retrieving a value
  test_key <- "test_key"
  test_value <- "test_value"
  assign(test_key, test_value, envir = env1)
  expect_equal(get(test_key, envir = env2), test_value)

  # Clean up test value
  rm(list = test_key, envir = env1)
})

test_that("copernicus_is_ready checks module availability", {
  # Clear environment first
  copernicus_env <- .copernicus_env()
  if (exists("cm", envir = copernicus_env)) {
    rm("cm", envir = copernicus_env)
  }

  # Clear credentials
  suppressMessages(copernicus_clear_credentials())

  # Should return FALSE when module not available and no credentials
  expect_output(
    result <- copernicus_is_ready(verbose = TRUE),
    "Python module copernicusmarine: NOT AVAILABLE"
  )
  expect_false(result)
})

# CORRECCIÓN: Test con estado limpio aislado
test_with_clean_state("copernicus_is_ready checks credentials", {
  # Mock module availability but clear credentials
  copernicus_env <- .copernicus_env()
  assign("cm", "mock_module", envir = copernicus_env)

  # Should return FALSE when credentials not available
  expect_output(
    result <- copernicus_is_ready(verbose = TRUE),
    "Credentials: NOT CONFIGURED"
  )
  expect_false(result)
})

test_that("copernicus_is_ready returns TRUE when everything is ready", {
  # Mock module availability
  copernicus_env <- .copernicus_env()
  assign("cm", "mock_module", envir = copernicus_env)

  # Set credentials
  options(copernicus.username = "test_user")
  options(copernicus.password = "test_pass")

  # Should return TRUE
  expect_output(
    result <- copernicus_is_ready(verbose = TRUE),
    "Ready to use Copernicus Marine"
  )
  expect_true(result)

  # Clean up
  suppressMessages(copernicus_clear_credentials())
})

test_that("copernicus_is_ready works with verbose = FALSE", {
  # Clear everything
  copernicus_env <- .copernicus_env()
  if (exists("cm", envir = copernicus_env)) {
    rm("cm", envir = copernicus_env)
  }
  suppressMessages(copernicus_clear_credentials())

  # Should return FALSE without messages
  result <- copernicus_is_ready(verbose = FALSE)
  expect_false(result)
})

test_that("copernicus_configure_python handles reticulate dependency", {
  # Test that reticulate is available (should be, since it's a dependency)
  expect_true(requireNamespace("reticulate", quietly = TRUE))
})

test_that("setup_copernicus handles credentials parameter", {
  skip("Requires actual Python environment - integration test")
})
