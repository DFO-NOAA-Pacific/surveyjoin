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
haul$effort_units <- "ha"
haul$area_swept <- haul$area_swept * 0.0001 # from m^2 to ha
haul$pass <- NA_integer_
haul$vessel <- NA_character_

pbs_haul <- dplyr::select(
  haul,
  survey_name = survey_abbrev,
  event_id = fishing_event_id,
  date = time_deployed,
  pass,
  vessel,
  lat_start = latitude,
  lon_start = longitude,
  lat_end = latitude_end,
  lon_end = longitude_end,
  depth_m = longitude_end, # looks like a copy/paste error, need to get correct depth column name
  effort = area_swept,
  effort_units,
  performance
)
pbs_haul$event_id <- as.integer(pbs_haul$event_id)
usethis::use_data(pbs_haul, overwrite = TRUE)

pbs_catch <- dat %>%
  dplyr::bind_rows() %>%
  dplyr::left_join(select(spp, species_science_name, itis_tsn), by = "species_science_name") %>%
  dplyr::select(
    event_id = fishing_event_id,
    itis = itis_tsn,
    catch_numbers = catch_count,
    catch_weight = catch_weight
  )
pbs_catch$event_id <- as.integer(pbs_catch$event_id)
usethis::use_data(pbs_catch, overwrite = TRUE)
