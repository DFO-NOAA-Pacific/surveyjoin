test_that("nwfscSurvey and surveyjoin return similar structure for Canary Rockfish", {

  testthat::skip_if_not_installed("nwfscSurvey")
  library(nwfscSurvey)

  survey_data <- try(
    nwfscSurvey::pull_catch(
      common_name = "canary rockfish",
      survey = "NWFSC.Combo"
    ),
    silent = TRUE
  )

  if (inherits(survey_data, "try-error")) {
    skip("nwfscSurvey::pull_catch() failed")
  }

  package_data <- surveyjoin::get_data("canary rockfish")

  expect_s3_class(survey_data, "data.frame")
  expect_s3_class(package_data, "data.frame")
  expect_gt(nrow(survey_data), 0)
  expect_gt(nrow(package_data), 0)

  # Compare lowercased column names
  cols_survey <- tolower(colnames(survey_data))
  cols_package <- tolower(colnames(package_data))
  common_cols <- intersect(cols_survey, cols_package)

  message("Common columns: ", paste(common_cols, collapse = ", "))

  expect_true(length(common_cols) >= 2)
  expect_true("common_name" %in% common_cols)
  expect_true("scientific_name" %in% common_cols)
})




