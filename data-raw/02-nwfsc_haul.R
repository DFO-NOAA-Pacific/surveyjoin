library(dplyr)
library(lubridate)
remotes::install_github("nwfsc-assess/nwfscSurvey")
library(nwfscSurvey)

# pull in the haul data from various nwfsc surveys
haul_nwfsc_combo <- nwfscSurvey::pull_haul(survey = "NWFSC.Combo")
haul_nwfsc_combo$survey_name <- "NWFSC.Combo"

haul_nwfsc_slope <- nwfscSurvey::pull_haul(survey = "NWFSC.Slope")
haul_nwfsc_slope$survey_name <- "NWFSC.Slope"

haul_nwfsc_shelf <- nwfscSurvey::pull_haul(survey = "NWFSC.Shelf")
haul_nwfsc_shelf$survey_name <- "NWFSC.Shelf"

haul_nwfsc_hypox <- nwfscSurvey::pull_haul(survey = "NWFSC.Hypoxia")
haul_nwfsc_hypox$survey_name <- "NWFSC.Hypoxia"

haul_nwfsc_tri <- nwfscSurvey::pull_haul(survey = "Triennial")
haul_nwfsc_tri$survey_name <- "Triennial"

# bind together
haul <- rbind(
  haul_nwfsc_combo,
  haul_nwfsc_slope,
  haul_nwfsc_shelf,
  haul_nwfsc_hypox,
  haul_nwfsc_tri
)

# rename based on notes
# https://docs.google.com/document/d/1c_WRMsuYJ8EJrNu4yuIxv6augtx0Ic9bO84UPc6_jwg/edit

# combine date and HMS into a single variable
haul$sampling_start <- paste0(
  substr(haul$sampling_start_hhmmss, 1, 2), ":",
  substr(haul$sampling_start_hhmmss, 3, 4), ":",
  substr(haul$sampling_start_hhmmss, 5, 6)
)
haul$date <- haul$date_formatted
haul$year <- year(haul$date)

haul <- dplyr::rename(haul,
  "effort" = "area_swept_ha_der",
  "lat_start" = "vessel_start_latitude_dd",
  "lon_start" = "vessel_start_longitude_dd",
  "lat_end" = "vessel_end_latitude_dd",
  "lon_end" = "vessel_end_longitude_dd",
  "depth_m" = "depth_hi_prec_m",
  "event_id" = "trawl_id",
  "bottom_temp_c" = "temperature_at_gear_c_der"
)
haul$effort_units <- "ha"

nwfsc_haul <- dplyr::select(
  haul,
  survey_name,
  event_id,
  date,
  pass,
  vessel,
  lat_start,
  lon_start,
  lat_end,
  lon_end,
  depth_m,
  effort,
  effort_units,
  performance,
  bottom_temp_c,
  year
)

# enforce types for dates, consistent with afsc / pbs
nwfsc_haul$date <- as.POSIXct.Date(nwfsc_haul$date)
# enforce types
# nwfsc_haul$vessel = as.character(nwfsc_haul$vessel)

# usethis::use_data(nwfsc_haul, overwrite = TRUE)
surveyjoin:::save_raw_data(nwfsc_haul, name = "nwfsc-haul")
