library(dplyr)
ssids <- c(1, 3, 4, 16)

dir.create("data-raw/pbs-cache", showWarnings = FALSE)
spp <- gfsynopsis::get_spp_names()
# dat <- purrr::map(seq_len(nrow(spp)), function(i) {
dat <- purrr::map(1:2, function(i) {
  s <- spp$spp_w_hyphens[i]
  cat(s, "\n")
  f <- paste0("data-raw/pbs-cache/", s, ".rds")
  if (file.exists(f)) {
    readRDS(f)
  } else {
    d <- gfdata::get_survey_sets(species = spp$species_code[i], ssid = ssids)
    saveRDS(d, file = f)
    d
  }
})

haul <- dat[[1]]
haul$performance <- NA_integer_
haul$area_swept_units <- "ha"
haul$area_swept <- haul$area_swept * 0.0001 # from m^2 to ha
haul$pass <- NA_integer_
# haul$date <- lubridate::ymd(paste(haul$year, haul$month, haul$day, sep = "-"))
haul$vessel <- NA_character_
pbs_haul <- dplyr::select(
  haul,
  survey_name = survey_abbrev,
  trawl_id = fishing_event_id,
  date = time_deployed,
  pass,
  vessel,
  lat_start = latitude,
  lon_start = longitude,
  lat_end = latitude_end,
  lon_end = longitude_end,
  depth_m = longitude_end,
  area_swept = area_swept,
  area_swept_units,
  performance
)
usethis::use_data(pbs_haul, overwrite = TRUE)

pbs_catch <- dat %>%
  dplyr::bind_rows() %>%
  dplyr::select(
    trawl_id = fishing_event_id,
    scientific_name = species_science_name,
    total_catch_numbers = catch_count,
    total_catch_wt_kg = catch_weight
  )
usethis::use_data(pbs_catch, overwrite = TRUE)
