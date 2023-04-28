dir.create("data-raw/data", showWarnings = FALSE)
library(dplyr)
ssids <- c(1, 3, 4, 16)

dir.create("data-raw/pbs-cache", showWarnings = FALSE)
spp <- gfsynopsis::get_spp_names()

sean_cache <- "../gfsynopsis-2021/report/data-cache-feb-2023/"
user <- Sys.info()[["user"]]

dat <- purrr::map(seq_len(nrow(spp)), function(i) {
  s <- spp$spp_w_hyphens[i]
  cat(s, "\n")
  f <- paste0("data-raw/pbs-cache/", s, ".rds")
  if (file.exists(f)) {
    readRDS(f)
  } else {
    if (user == "seananderson") {
      d <- readRDS(paste0(sean_cache, s, ".rds"))$survey_sets
      if ("survey_series_id.x" %in% names(d)) {
        d$survey_series_id <- d$survey_series_id.x
        d$survey_series_id.x <- NULL
        d$survey_series_id.y <- NULL
        d <- dplyr::filter(d, survey_series_id %in% ssids)
      }
    } else {
      d <- gfdata::get_survey_sets(species = spp$species_code[i], ssid = ssids)
    }
    saveRDS(d, file = f)
    d
  }
})

haul <- dat[[1]] # pick one
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
  depth_m = depth_m,
  effort = area_swept,
  effort_units,
  performance
)
pbs_haul$event_id <- as.integer(pbs_haul$event_id)
save_raw_data(pbs_haul, "pbs-haul")

pbs_catch <- dat %>%
  dplyr::bind_rows() %>%
  dplyr::left_join(select(spp, species_science_name, itis_tsn), by = "species_science_name") %>%
  dplyr::select(
    event_id = fishing_event_id,
    itis = itis_tsn,
    catch_numbers = catch_count,
    catch_weight = catch_weight
  )
pbs_catch$event_id <- as.numeric(pbs_catch$event_id)

glimpse(pbs_catch)

save_raw_data(pbs_catch, "pbs-catch")
