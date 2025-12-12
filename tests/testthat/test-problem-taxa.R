# Test for kamchatka flounder identification
test_that("kamchatka flounder not zero-filled in years before identification", {

  # Get kamchatka flounder data
  kamchatka <- get_data(scientific = "atheresthes evermanni")

  # Identify first year with actual kamchatka records in each region
  first_year_by_region <- kamchatka |>
    dplyr::filter(!is.na(catch_weight) | !is.na(catch_numbers)) |>
    dplyr::group_by(region) |>
    dplyr::summarise(first_year = min(year, na.rm = TRUE))

  # For each region, check that pre-identification years don't have zeros
  for (i in seq_len(nrow(first_year_by_region))) {
    region_name <- first_year_by_region$region[i]
    first_yr <- first_year_by_region$first_year[i]

    # Get kamchatka records for this region before first identification
    pre_identification <- kamchatka |>
      dplyr::filter(region == region_name, year < first_yr)

    if (nrow(pre_identification) > 0) {
      # if they exist these years should have zeros
      # They should be NA (species not identified) not 0 (absence)
      zero_filled <- pre_identification %>%
        dplyr::filter(catch_weight == 0 | catch_numbers == 0)
      expect_equal(nrow(zero_filled), 0)
    }
  }
})


test_that("arrowtooth and kamchatka not both zero-filled in early Bering/Aleutian years", {

  # Get both species for Aleutian Islands and Bering Sea regions
  arrowtooth <- get_data(
    scientific = "atheresthes stomias",
    regions = c("afsc")
  )

  kamchatka <- get_data(
    scientific = "atheresthes evermanni",
    regions = c("afsc")
  )

  # Find years where both species have records
  kamchatka_years <- kamchatka |>
    dplyr::filter(catch_weight > 0) |>  # Only actual catches
    dplyr::group_by(year) |>
    dplyr::summarise(
      n_hauls_with_catch = dplyr::n(),
      total_catch_weight = sum(catch_weight, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(year)
  kamchatka_years <- kamchatka_years$year

  arrowtooth_years <- arrowtooth |>
    dplyr::filter(catch_weight > 0) |>  # Only actual catches
    dplyr::group_by(year) |>
    dplyr::summarise(
      n_hauls_with_catch = dplyr::n(),
      total_catch_weight = sum(catch_weight, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(year)
  arrowtooth_years <- arrowtooth_years$year

  # Early years should have one or the other, not both
  earliest_year <- min(c(arrowtooth_years, kamchatka_years))
  expect_equal(earliest_year, 1992)

  # Check if there's a period where both are being reported
  overlap_years <- intersect(arrowtooth_years, kamchatka_years)
  expect_equal(overlap_years, c(earliest_year:2019, 2021:as.integer(format(Sys.Date(), "%Y"))))
})

test_that("northern rock sole and southern rock sole working properly in Alaska", {

  # Get both species for Aleutian Islands and Bering Sea regions
  southern <- get_data(
    common = "southern rock sole",
    regions = c("afsc")
  )

  northern <- get_data(
    common = "northern rock sole",
    regions = c("afsc")
  )

  # Find years where both species have records
  southern_years <- southern |>
    dplyr::filter(catch_weight > 0) |>  # Only actual catches
    dplyr::group_by(year) |>
    dplyr::summarise(
      n_hauls_with_catch = dplyr::n(),
      total_catch_weight = sum(catch_weight, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(year)
  southern_years <- southern_years$year

  northern_years <- northern |>
    dplyr::filter(catch_weight > 0) |>  # Only actual catches
    dplyr::group_by(year) |>
    dplyr::summarise(
      n_hauls_with_catch = dplyr::n(),
      total_catch_weight = sum(catch_weight, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(year)
  northern_years <- northern_years$year

  # Early years should have one or the other, not both
  earliest_year <- min(c(southern_years, northern_years))
  expect_equal(earliest_year, 1996)

  # Check if there's a period where both are being reported
  overlap_years <- intersect(southern_years, northern_years)
  expect_equal(overlap_years, c(earliest_year:2019, 2021:as.integer(format(Sys.Date(), "%Y"))))
})


test_that("big skate and bering skate are working properly in Alaska", {

  # Get both species for Aleutian Islands and Bering Sea regions
  bigskate <- get_data(
    common = "big skate",
    regions = c("afsc")
  )

  beringskate <- get_data(
    common = "bering skate",
    regions = c("afsc")
  )

  # Find years where both species have records
  bigskate_years <- bigskate |>
    dplyr::filter(catch_weight > 0) |>  # Only actual catches
    dplyr::group_by(year) |>
    dplyr::summarise(
      n_hauls_with_catch = dplyr::n(),
      total_catch_weight = sum(catch_weight, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(year)
  bigskate_years <- bigskate_years$year

  beringskate_years <- beringskate |>
    dplyr::filter(catch_weight > 0) |>  # Only actual catches
    dplyr::group_by(year) |>
    dplyr::summarise(
      n_hauls_with_catch = dplyr::n(),
      total_catch_weight = sum(catch_weight, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(year)
  beringskate_years <- beringskate_years$year

  # Early years should have one or the other, not both
  earliest_year <- min(c(bigskate_years, beringskate_years))
  expect_equal(earliest_year, 1983)
  expect_equal(min(bigskate_years), 1983)
  expect_equal(min(beringskate_years), 1996)

  # Check if there's a period where both are being reported
  overlap_years <- intersect(southern_years, northern_years)
  expect_equal(overlap_years, c(1996:2019, 2021:as.integer(format(Sys.Date(), "%Y"))))
})
