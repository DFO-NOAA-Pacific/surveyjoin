#---- Via Oracle internal server (requires credentials)
library(dplyr)
library(RODBC)
library(getPass)
library(gapindex)

channel <- gapindex::get_connected()

haul <- RODBC::sqlQuery(channel, "SELECT * FROM GAP_PRODUCTS.FOSS_HAUL")
names(haul) <- tolower(names(haul))
afsc_haul <- haul %>% select(
  survey_name = survey, # or = survey_name for full description if beyond trawl
  event_id = hauljoin,
  date = date_time,
  vessel = vessel_name,
  lat_start = latitude_dd_start,
  lon_start = longitude_dd_start,
  lat_end = latitude_dd_end,
  lon_end = longitude_dd_end,
  depth_m,
  performance,
  area_swept_km2,
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
    effort = as.numeric(area_swept_km2 * 100), # convert to ha
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
save_raw_data(afsc_haul, "afsc-haul")

catch <- RODBC::sqlQuery(channel, "SELECT * FROM GAP_PRODUCTS.FOSS_CPUE_PRESONLY")
names(catch) <- tolower(names(catch))
afsc_catch <- catch %>%
  select(
    event_id = hauljoin,
    itis,
    scientific_name,
    catch_numbers = count,
    catch_weight = weight_kg,
    species_code,
    id_rank
  ) %>%
    mutate(
      event_id = as.numeric(event_id),
      catch_numbers = as.numeric(catch_numbers),
      catch_weight = as.numeric(catch_weight)
  ) %>%
  filter(!is.na(itis))

# filter this to most prevalent species, by category ----
afsc_catch_fish <- afsc_catch %>%
  filter(species_code < 32000) %>%
  filter(id_rank == "species")
afsc_catch_sfi <- afsc_catch %>%
  filter(species_code %in% c(41000:45000, 91000:91999, 99981:99988)) # corals and sponges
afsc_catch_inv <- afsc_catch %>%
  filter(species_code %in% c(40000:40999, 45001:90999, 92000:99981)) # other inverts

# filter by frequency of occurrence and catch weights
fish_high <- group_by(afsc_catch_fish, scientific_name) |>
  summarise(freq = n() / nrow(afsc_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
  filter(total_weight > 1000) |> # freq > 0.01 gives 79 species vs 94
  arrange(-freq)
nrow(fish_high)

fish_low <- group_by(afsc_catch_fish, scientific_name) |>
  summarise(freq = n() / nrow(afsc_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
  filter(total_weight > 1000, freq > 0.1) |>
  arrange(-freq)
nrow(fish_low)

sfi_high <- group_by(afsc_catch_sfi, scientific_name) |>
  summarise(freq = n() / nrow(afsc_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
  filter(total_weight > 500) |>
  arrange(-freq)
nrow(sfi_high)

sfi_low <- group_by(afsc_catch_sfi, scientific_name) |>
  summarise(freq = n() / nrow(afsc_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
  filter(total_weight > 500, freq > 0.02) |>
  arrange(-freq)
nrow(sfi_low)

inv_high <- group_by(afsc_catch_inv, scientific_name) |>
  summarise(freq = n() / nrow(afsc_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
  filter(total_weight > 500, freq > 0.05) |>
  arrange(-freq)
nrow(inv_high)

inv_low <- group_by(afsc_catch_inv, scientific_name) |>
  summarise(freq = n() / nrow(afsc_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
  filter(total_weight > 500, freq > 0.15) |>
  arrange(-freq)
nrow(inv_low)

afsc_catch <- select(afsc_catch, -scientific_name, - species_code, -id_rank)

afsc_catch_fish_h <- semi_join(afsc_catch, select(fish_high, itis), by = join_by(itis))
afsc_catch_fish_l <- semi_join(afsc_catch, select(fish_low, itis), by = join_by(itis))
afsc_catch_sfi_h <- semi_join(afsc_catch, select(sfi_high, itis), by = join_by(itis))
afsc_catch_sfi_l <- semi_join(afsc_catch, select(sfi_low, itis), by = join_by(itis))
afsc_catch_inv_h <- semi_join(afsc_catch, select(inv_high, itis), by = join_by(itis))
afsc_catch_inv_l <- semi_join(afsc_catch, select(inv_low, itis), by = join_by(itis))

save_raw_data(afsc_catch_fish_h, "afsc-catch-fish-h")
save_raw_data(afsc_catch_fish_l, "afsc-catch-fish-l")
save_raw_data(afsc_catch_sfi_h, "afsc-catch-sfi-h")
save_raw_data(afsc_catch_sfi_l, "afsc-catch-sfi-l")
save_raw_data(afsc_catch_inv_h, "afsc-catch-inv-h")
save_raw_data(afsc_catch_inv_l, "afsc-catch-inv-l")
