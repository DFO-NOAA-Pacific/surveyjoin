test_that("test metadata", {
  g <- get_metadata()
  expect_equal(nrow(g), 3)
  expect_equal(g$region, c("afsc","pbs","nwfsc"))

  g <- get_rawdata()
  expect_equal(nrow(g), 3)
  expect_equal(g$region, c("afsc","pbs","nwfsc"))

  g <- get_shapefiles()
  expect_equal(nrow(g), 3)
  expect_equal(g$region, c("afsc","pbs","nwfsc"))
})

test_that("get itis", {
  g <- get_itis_spp("chinook salmon")
  expect_equal(g, 161980)
})

test_that("get species", {
  g <- get_species()
  expect_equal(nrow(g), 55)
  expect_equal(names(g), c("common_name", "scientific_name", "itis" ))
})

test_that("get surveys", {
  g <- get_survey_names()
  expect_equal(nrow(g), 14)
  expect_equal(names(g), c("survey", "region" ))
})


