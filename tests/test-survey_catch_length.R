test_that("survey_catch_length joins correctly on all keys", {
  catch <- data.frame(
    survey = "WCGBTS", year = 2020, vessel = 123,
    cruise = 1, haul = 10, species_code = 100,
    weight = 500
  )

  length <- data.frame(
    survey = "WCGBTS", year = 2020, vessel = 123,
    cruise = 1, haul = 10, species_code = 100,
    length = 25
  )

  result <- survey_catch_length(catch, length)

  expect_equal(nrow(result), 1)
  expect_true("length" %in% names(result))
  expect_equal(result$length, 25)
})

test_that("survey_catch_length returns no rows for unmatched keys", {
  catch <- data.frame(
    survey = "WCGBTS", year = 2020, vessel = 123,
    cruise = 1, haul = 10, species_code = 100
  )

  length <- data.frame(
    survey = "GOA", year = 2021, vessel = 321,
    cruise = 2, haul = 99, species_code = 999,
    length = 40
  )

  result <- survey_catch_length(catch, length)

  expect_equal(nrow(result), 0)
})
