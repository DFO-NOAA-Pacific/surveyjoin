library(testthat)
library(surveyjoin)

test_that("NWFSC data in surveyjoin matches original nwfscSurvey data", {
  skip_on_ci()
  skip_if_not_installed("nwfscSurvey")
  library(nwfscSurvey)
  library(dplyr)

  # Edit to test for other species/surveys
  test_species <- "arrowtooth flounder"
  test_survey <- "NWFSC.Slope"

  sj_data <- get_data(common = test_species, surveys = test_survey)

  nwfsc_catch_combo <- nwfscSurvey::pull_catch(survey = test_survey, common_name = test_species)
  nwfsc_haul_combo <- nwfscSurvey::pull_haul(survey = test_survey)

  nwfsc_data <- nwfsc_catch_combo %>%
    left_join(nwfsc_haul_combo, by = c("Trawl_id" = "trawl_id")) %>%
    rename(
      event_id = Trawl_id,
      catch_numbers = total_catch_numbers,
      catch_weight = total_catch_wt_kg,
      lat_start = vessel_start_latitude_dd,
      lon_start = vessel_start_longitude_dd,
      effort = Area_swept_ha
    )

  # Number of rows
  expect_equal(nrow(sj_data), nrow(nwfsc_data),
              info = "Number of records should be same")

  # Total catch weight
  expect_equal(sum(sj_data$catch_weight), sum(nwfsc_data$catch_weight),
               tolerance = 0.1,
               info = "Total catch weight should be approximately equal")

  # Total catch numbers
  expect_equal(sum(sj_data$catch_numbers), sum(nwfsc_data$catch_numbers),
               info = "Total catch numbers should match between data sources")

  # Total effort
  expect_equal(sum(sj_data$effort, na.rm = TRUE), sum(nwfsc_data$effort, na.rm = TRUE),
               tolerance = 0.1,
               info = "Total effort should be approximately equal")

  # Check latitude and longitude ranges
  expect_equal(range(sj_data$lat_start), range(nwfsc_data$lat_start),
               info = "Latitude range should match")

  expect_equal(range(sj_data$lon_start), range(nwfsc_data$lon_start),
               info = "Longitude range should match")
})