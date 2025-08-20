library(dplyr)

dir.create("data-raw/data", showWarnings = FALSE)
dir.create("data-raw/pbs-cache", showWarnings = FALSE)

# Catch data set ------------------------------------------------------

if (FALSE) {
  dat <- gfdata::get_all_survey_sets(species = NULL, ssid = c(1, 3, 4, 16))
  saveRDS(dat, "data-raw/pbs-all-trawl-catches.rds")
}
dat <- readRDS("data-raw/pbs-all-trawl-catches.rds")
sum(is.na(dat$usability_code))
select(dat, usability_code, usability_desc) |> distinct() |> arrange(usability_code)
names(dat)
# dat <- filter(dat, usability_code %in% c(0, 1, 2, 6, 22)) ## 22 adds redefinition of grid
dat <- filter(dat, usability_code %in% c(0, 1, 2, 6))
pbs_catch_all <- data.frame(
  event_id = dat$fishing_event_id,
  catch_numbers = dat$catch_count,
  catch_weight = dat$catch_weight,
  species_code = dat$species_code,
  species_common_name = dat$species_common_name,
  species_science_name = dat$species_science_name
)
glimpse(pbs_catch_all)
saveRDS(pbs_catch_all, "data-raw/data/pbs-catch-all.rds")

# Haul data set -------------------------------------------------------

haul <- select(dat, year, month, day, area_swept, time_deployed, survey_abbrev, fishing_event_id, latitude, longitude, latitude_end, longitude_end, depth_m, grouping_code) |>
  distinct()
table(haul$year)
haul$performance <- NA_integer_
haul$effort_units <- "ha"
haul$area_swept <- haul$area_swept * 0.0001 # from m^2 to ha
haul$pass <- NA_integer_
haul$vessel <- NA_character_

haul |> filter(is.na(time_deployed))
haul$date <- dplyr::if_else(is.na(haul$time_deployed), lubridate::ymd(paste(haul$year, haul$month, haul$day)), haul$time_deployed)
class(haul$date)
head(haul$date)

pbs_haul <- dplyr::select(
  haul,
  survey_name = survey_abbrev,
  event_id = fishing_event_id,
  date = date,
  pass,
  vessel,
  lat_start = latitude,
  lon_start = longitude,
  lat_end = latitude_end,
  lon_end = longitude_end,
  depth_m = depth_m,
  effort = area_swept,
  effort_units,
  performance,
  stratum = grouping_code
)
pbs_haul$event_id <- as.integer(pbs_haul$event_id)

# Environmental data addition -----------------------------------------

if (FALSE) {
  d <- gfdata::get_sensor_data_trawl(c(1, 3, 4, 16))
  saveRDS(d, "data-raw/data/pbs-env-data-raw.rds")
}
d <- readRDS("data-raw/data/pbs-env-data-raw.rds")
d <- select(d, event_id = fishing_event_id, attribute, value = avg)
d <- d |>
  group_by(event_id, attribute) |>
  summarise(value = mean(value), .groups = "drop")
d <- tidyr::pivot_wider(d,
  id_cols = c(event_id),
  names_from = attribute, values_from = value
) |>
  select(-depth_m) |>
  rename(temperature_C = `temperature_(¿C)`)
pbs_haul <- left_join(pbs_haul, d, by = join_by(event_id))

sum(duplicated(pbs_haul))
sum(duplicated(select(pbs_haul, event_id, date)))

saveRDS(pbs_haul, "data-raw/data/pbs-haul.rds")

if (FALSE) {
  system("cp data-raw/data/pbs-catch-all.rds ~/src/surveyjoin-data/pbs-catch-all.rds")
  system("cp data-raw/data/pbs-haul.rds ~/src/surveyjoin-data/pbs-haul.rds")
}
