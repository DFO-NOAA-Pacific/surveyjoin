#---- Via Oracle internal server (requires credentials)
library(dplyr)
library(RODBC)
library(getPass)
library(gapindex)

channel <- gapindex::get_connected()

haul <- RODBC::sqlQuery(channel, "SELECT * FROM RACEBASE_FOSS.JOIN_FOSS_CPUE_HAUL")
names(haul) <- tolower(names(haul))
afsc_haul <- haul %>% dplyr::select(
  survey_name = survey,
  event_id = hauljoin,
  date = date_time,
  vessel = vessel_name,
  lat_start = latitude_dd_start,
  lon_start = longitude_dd_start,
  lat_end = latitude_dd_end,
  lon_end = longitude_dd_end,
  depth_m,
  performance,
  effort = area_swept_ha,
  bottom_temp_c = bottom_temperature_c
  ) %>%
  mutate(
    event_id = as.numeric(event_id),
    date = as.POSIXct(date,format="%m/%d/%Y %H:%M:%S",tz=Sys.timezone()),
    pass = NA_integer_,
    lat_start = as.numeric(lat_start),
    lon_start = as.numeric(lon_start),
    lat_end = as.numeric(lat_end),
    lon_end = as.numeric(lon_end),
    depth_m = as.numeric(depth_m),
    effort = as.numeric(effort),
    effort_units = "ha",
    performance = as.integer(performance),
    bottom_temp_c = as.numeric(bottom_temp_c)
  ) %>%
  select(
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
    bottom_temp_c
  )
# usethis::use_data(afsc_haul, overwrite = TRUE)
save_raw_data(afsc_haul, "afsc-haul")

catch <- RODBC::sqlQuery(channel, "SELECT * FROM RACEBASE_FOSS.JOIN_FOSS_CPUE_CATCH")
names(catch) <- tolower(names(catch))
afsc_catch <- catch %>% dplyr::select(
  event_id = hauljoin,
  itis,
  scientific_name,
  catch_numbers = count,
  catch_weight = weight_kg,
  ) %>%
  mutate(
    event_id = as.numeric(event_id),
    catch_numbers = as.numeric(catch_numbers),
    catch_weight = as.numeric(catch_weight),
    catch_weight_units = "kg"
  )
# usethis::use_data(afsc_catch, overwrite = TRUE)

# filter this down to something manageable size-wise:
# (to slow to load)
x <- group_by(afsc_catch, scientific_name) |>
  summarise(total_weight = sum(catch_weight), itis = itis[1]) |> arrange(-total_weight)

filter(x, total_weight > 3000) |> summarise(r = sum(total_weight) / sum(x$total_weight)) |> pull(r)

filter(x, total_weight > 3000) |>
  nrow()

na <- filter(x, is.na(itis)) |> summarise(s = sum(total_weight))
notna <- filter(x, !is.na(itis)) |> summarise(s = sum(total_weight))

na$s[1] / notna$s[1]

N <- group_by(afsc_catch, scientific_name) |>
  mutate(total_weight = sum(catch_weight)) |>
  filter(total_weight > 3000) |>
  nrow()

N / nrow(afsc_catch)

filter(afsc_catch, is.na(itis)) |> nrow()
filter(afsc_catch, !is.na(itis)) |> nrow()

tokeep <- afsc_catch |>
  filter(!is.na(itis)) |>
  group_by(itis) |>
  summarise(total_weight = sum(catch_weight)) |>
  filter(total_weight > 3000) |>
  select(itis) |>
  distinct()

afsc_catch_keep <- semi_join(afsc_catch, tokeep, by = join_by(itis))
sum(afsc_catch_keep$catch_weight) / sum(afsc_catch$catch_weight)

nrow(afsc_catch_keep) / nrow(afsc_catch)

afsc_catch_keep$catch_weight_units <- NULL
afsc_catch_keep$scientific_name <- NULL

glimpse(afsc_catch_keep)

save_raw_data(afsc_catch_keep, "afsc-catch")

#---- Via API (currently broken)
# link to the API generated at [AFSC RACE Groundfish and Shellfish Survey Public Data](https://github.com/afsc-gap-products/gap_public_data)
#library(httr)
#library(jsonlite)
#
# api_link <- "https://origin-tst-ods-st.fisheries.noaa.gov/ods/foss/afsc_groundfish_survey/"
#
# res <- httr::GET(url = api_link)
# res
#
# dat <- jsonlite::fromJSON(base::rawToChar(res$content))
#
# afsc <- dat[[1]] %>% dplyr::select(
#   survey_name = srvy,
#   event_id = hauljoin,
#   date = date_time,
#   vessel = vessel_name,
#   lat_start = latitude_dd_start,
#   lon_start = longitude_dd_start,
#   lat_end = latitude_dd_end,
#   lon_end = longitude_dd_end,
#   depth_m,
#   performance,
#   effort = area_swept_ha,
#   itis = itis,
#   catch_numbers = count,
#   catch_weight = weight_kg,
# ) %>%
#   mutate(
#     event_id = as.numeric(event_id),
#     date = as.POSIXct(date,format="%m/%d/%Y %H:%M:%S",tz=Sys.timezone()),
#     pass = NA_integer_,
#     lat_start = as.numeric(lat_start),
#     lon_start = as.numeric(lon_start),
#     lat_end = as.numeric(lat_end),
#     lon_end = as.numeric(lon_end),
#     depth_m = as.numeric(depth_m),
#     effort = as.numeric(effort),
#     effort_units = "ha",
#     performance = as.integer(performance),
#     catch_numbers = as.numeric(catch_numbers),
#     catch_weight = as.numeric(catch_weight),
#     catch_weight_units = "kg"
#   ) %>%
#   select(
#     survey_name,
#     event_id,
#     date,
#     pass,
#     vessel,
#     lat_start,
#     lon_start,
#     lat_end,
#     lon_end,
#     depth_m,
#     effort,
#     effort_units,
#     performance,
#     itis,
#     catch_numbers,
#     catch_weight
#   )
