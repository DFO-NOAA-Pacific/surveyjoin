devtools::load_all()

library(dplyr)

dir.create("data-raw/data", showWarnings = FALSE)
ssids <- c(1, 3, 4, 16)

dir.create("data-raw/pbs-cache", showWarnings = FALSE)
spp <- gfsynopsis::get_spp_names()

sean_cache <- "../gfsynopsis-2023/report/data-cache-2024-05/"
user <- Sys.info()[["user"]]

joined_list <- readRDS("data-raw/joined_list.rds")

spp$species_science_name[spp$species_science_name %in% joined_list$scientific_name]
spp$species_science_name[!spp$species_science_name %in% joined_list$scientific_name]

# spp[!spp$species_science_name %in% joined_list$scientific_name, ]
spp <- spp[spp$species_science_name %in% joined_list$scientific_name, ]

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
      }
      d <- dplyr::filter(d, survey_series_id %in% ssids)
    } else {
      d <- gfdata::get_survey_sets(species = spp$species_code[i], ssid = ssids)
    }
    if (!"area_swept" %in% names(d)) { # depends on gfdata branch for now
      d <- dplyr::mutate(d,
        area_swept1 = doorspread_m * (speed_mpm * duration_min),
        area_swept2 = tow_length_m * doorspread_m,
        area_swept = dplyr::case_when(
          grepl("SYN", survey_abbrev) & !is.na(area_swept2) ~ area_swept2,
          grepl("SYN", survey_abbrev) & is.na(area_swept2) ~ area_swept1
        )
      )
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

## start environmental data
if (FALSE) {
  d <- gfdata::get_sensor_data_trawl(c(1, 3, 4, 16))
  saveRDS(d, "data-raw/data/pbs-env-data-raw.rds")
}
d <- readRDS("data-raw/data/pbs-env-data-raw.rds")
lu <- dat[[1]] |>
  filter(year > 2005) |>
  select(survey_series_id, survey_abbrev) |>
  distinct() |>
  rename(ssid = survey_series_id, survey_name = survey_abbrev)
d <- left_join(d, lu)
d <- select(d, year, survey_name, event_id = fishing_event_id, attribute, value = avg)
d <- d |>
  group_by(year, survey_name, event_id, attribute) |>
  summarise(value = mean(value), .groups = "drop")
d <- tidyr::pivot_wider(d,
  id_cols = c(year, survey_name, event_id),
  names_from = attribute, values_from = value
) |>
  select(-depth_m) |>
  rename(temperature_C = `temperature_(¿C)`)
pbs_haul <- left_join(pbs_haul, d, by = join_by(survey_name, event_id))
## end environmental data

sum(duplicated(pbs_haul))
sum(duplicated(select(pbs_haul, event_id, date)))

pbs_haul <- distinct(pbs_haul)

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
# pacific spiny dogfish:
pbs_catch$itis[pbs_catch$itis == 160617] <- 160620

glimpse(pbs_catch)

sum(duplicated(pbs_catch))
dd <- pbs_catch[duplicated(pbs_catch), ]
filter(pbs_catch, event_id == 2787010, itis == 160620)
pbs_catch <- dplyr::distinct(pbs_catch)

save_raw_data(pbs_catch, "pbs-catch")

# start with full dataset instead:
dat <- gfdata::get_all_survey_sets(species = NULL, ssid = c(1, 3, 4, 16))
saveRDS(dat, "data-raw/pbs-all-trawl-catches.rds")
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

## extra: composition data

dat_samp_list <- purrr::map(seq_len(nrow(spp)), function(i) {
  s <- spp$spp_w_hyphens[i]
  cat(s, "\n")
  f <- paste0("data-raw/pbs-cache/", s, "-samples.rds")
  if (file.exists(f)) {
    readRDS(f)
  } else {
    if (user == "seananderson") {
      d <- readRDS(paste0(sean_cache, s, ".rds"))$survey_samples
      d <- dplyr::filter(d, survey_series_id %in% ssids)
    } else {
      d <- gfdata::get_survey_samples(species = spp$species_code[i], ssid = ssids)
    }
    saveRDS(d, file = f)
    d
  }
})

spp_table <- select(spp, species_common_name, species_science_name, itis = itis_tsn)
saveRDS(spp_table, "data-raw/data/species-table.rds")

dat_samp <- dat_samp_list %>%
  dplyr::bind_rows() %>%
  dplyr::left_join(select(spp, species_science_name, itis_tsn), by = "species_science_name") %>%
  dplyr::select(
    event_id = fishing_event_id,
    itis = itis_tsn,
    sex,
    age,
    length,
    length_type,
    weight,
    maturity_code,
    sample_id,
    specimen_id,
    maturity_convention_code,
    maturity_convention_maxvalue,
    usability_code
  )
dat_samp$event_id <- as.numeric(dat_samp$event_id)

# clean up ------------------------------------------------------

dat_samp <- dat_samp |> filter(maturity_convention_code != 9)
dat_samp <- dat_samp |>
  filter(maturity_code <= maturity_convention_maxvalue)
usability_codes_keep <- c(0, 1, 2, 6)
dat_samp <- filter(dat_samp, usability_code %in% usability_codes_keep)
dat_samp <- dat_samp[dat_samp$sex %in% c(1, 2), , drop = FALSE]
dat_samp <- dat_samp[!duplicated(dat_samp$specimen_id), , drop = FALSE] # critical!
dat_samp$maturity_convention_maxvalue <- NULL
dat_samp <- left_join(dat_samp |> distinct(), select(gfplot::maturity_assignment, maturity_convention_code, sex, mature_at) |> distinct())
dat_samp <- mutate(dat_samp, mature = maturity_code >= mature_at)
dat_samp <- mutate(dat_samp, female = ifelse(sex == 2L, TRUE, FALSE))
dat_samp <- select(dat_samp, -sex, -maturity_convention_code, -usability_code, -mature_at, -maturity_code)
dat_samp$length_type <- tolower(dat_samp$length_type)

saveRDS(dat_samp, "data-raw/data/pbs-bio-samples.rds")

if (FALSE) {
  system("cp data-raw/data/pbs-catch-all.rds ~/src/surveyjoin-data/pbs-catch-all.rds")
  system("cp data-raw/data/pbs-catch.rds ~/src/surveyjoin-data/pbs-catch.rds")
  system("cp data-raw/data/pbs-haul.rds ~/src/surveyjoin-data/pbs-haul.rds")
}
