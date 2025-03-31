test_that("cache_data runs successfully", {
  # Don't skip on CI
  if (Sys.getenv("GITHUB_ACTIONS") == "true") {
    cli::cli_alert_info("Running cache_data() in CI...")
  } else {
    skip_on_cran()
  }
  cache_folder <- surveyjoin::get_cache_folder()

  cli::cli_alert_info("Cache folder path: {cache_folder}")
  expect_no_error(cache_data())
})


test_that("cached files recognized when not in CI", {
  cache_folder <- surveyjoin::get_cache_folder()
  cached_files <- list.files(cache_folder, full.names = TRUE)
  expect_true(length(cached_files) > 0)
})


test_that("load_sql_data runs successfully", {
  # Don't skip on CI
  if (Sys.getenv("GITHUB_ACTIONS") == "true") {
    cli::cli_alert_info("Running {.fn load_sql_data} in CI ...")
  } else {
    skip_on_cran()
  }
  # Changed to expect_no_error because load_sql_data throws warnings about pkg versions
  db_path <- surveyjoin:::sql_folder()
  cli::cli_alert_info("Database path: {.file {db_path}}")

  load_sql_data()

  # Check if database was created
  db_path <- sql_folder()
  expect_true(file.exists(db_path), info = paste("Database file should exist at:", db_path))

  # test that SQLite database contains data
  g <- get_data(regions="pbs")
  expect_gt(nrow(g), 300000)
})


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

test_that("data version", {
  skip_on_ci()
  df <- data_version()
  expect_s3_class(df, "data.frame")
  expect_equal(colnames(df), c("file", "last_updated"))
  expect_equal(nrow(df), length(files_to_cache()))
})
