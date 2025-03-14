test_that("test metadata", {
  skip_on_ci()
  g <- get_metadata()
  expect_equal(nrow(g), 3L)
  expect_equal(g$region, c("afsc", "pbs", "nwfsc"))

  g <- get_rawdata()
  expect_equal(nrow(g), 3L)
  expect_equal(g$region, c("afsc", "pbs", "nwfsc"))

  g <- get_shapefiles()
  expect_equal(nrow(g), 3L)
  expect_equal(g$region, c("afsc", "pbs", "nwfsc"))
})
#
# test_that("get itis", {
#   skip_on_ci()
#   g <- get_itis_spp("chinook salmon")
#   expect_equal(g, 161980)
# })

test_that("get species", {
  skip_on_ci()
  g <- get_species()
  expect_equal(nrow(g), 55L)
  expect_equal(names(g), c("common_name", "scientific_name", "itis"))
})

test_that("get surveys", {
  skip_on_ci()
  g <- get_survey_names()
  expect_equal(nrow(g), 14L)
  expect_equal(names(g), c("survey", "region"))
})

test_that("data versioning", {
  skip_on_ci()
  g <- data_version()
  expect_equal(nrow(g), 6L)
  expect_equal(names(g), c("file", "last_updated"))
})

test_that("load_sql_data runs successfully", {
  # Don't skip on CI
  if (Sys.getenv("GITHUB_ACTIONS") == "true") {
    cli::cli_alert_info("Running load_sql_data() in CI...")
  } else {
    skip_on_cran()
  }
  # Changed to expect_no_error becasue load_sql_data throws warnings about pkg versions
  expect_no_error(load_sql_data())

  # Check if database was created
  db_path <- sql_folder()
  expect_true(file.exists(db_path), info = paste("Database file should exist at:", db_path))
})
