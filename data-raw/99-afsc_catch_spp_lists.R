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

# get catch data for fishes only, then apply common filters (maybe by survey?)
catch <- RODBC::sqlQuery(channel, "SELECT * FROM GAP_PRODUCTS.FOSS_CATCH
                         WHERE SPECIES_CODE < 32000")
catch_spp <- RODBC::sqlQuery(channel, "SELECT * FROM GAP_PRODUCTS.FOSS_SPECIES
                         WHERE SPECIES_CODE < 32000")
catchjoin <- left_join(catch, catch_spp)
names(catchjoin) <- tolower(names(catchjoin))
afsc_catch <- catchjoin %>%
  select(
    event_id = hauljoin,
    itis,
    scientific_name,
    common_name,
    catch_numbers = count,
    catch_weight = weight_kg
    #species_code,
    #id_rank
  ) %>%
    mutate(
      event_id = as.numeric(event_id),
      catch_numbers = as.numeric(catch_numbers),
      catch_weight = as.numeric(catch_weight)
  ) #%>%
  #filter(!is.na(itis))

percent5 <- group_by(afsc_catch, scientific_name) |>
  summarise(freq = n() / nrow(afsc_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
  filter(freq > 0.05) |>
  distinct(scientific_name)

percent20 <- group_by(afsc_catch, scientific_name) |>
  summarise(freq = n() / nrow(afsc_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
  filter(freq > 0.2) |>
  distinct(scientific_name)

total_yr <- left_join(afsc_catch, afsc_haul) |>
  mutate(year = lubridate::year(date)) |>
  group_by(year) |>
  summarise(total = sum(catch_weight))
total_mean <- mean(total_yr$total)

percent5_biomass_025 <- left_join(afsc_catch, afsc_haul) |>
  filter(scientific_name %in% percent5$scientific_name) |>
  group_by(scientific_name) |>
  summarise(mean_catch = sum(catch_weight) / 41) |>
  filter(mean_catch > 0.0025 * total_mean)

percent5_biomass_1 <- left_join(afsc_catch, afsc_haul) |>
  filter(scientific_name %in% percent5$scientific_name) |>
  group_by(scientific_name) |>
  summarise(mean_catch = sum(catch_weight) / 41) |>
  filter(mean_catch > 0.001 * total_mean)

max_n = max(nrow(percent5), nrow(percent20),
          nrow(percent5_biomass_025), nrow(percent5_biomass_1))

percent5 = c(percent5$scientific_name, rep(NA, max_n - nrow(percent5)))
percent20 = c(percent20$scientific_name, rep(NA, max_n - nrow(percent20)))
percent5_biomass_025 = c(percent5_biomass_025$scientific_name, rep(NA, max_n - nrow(percent5_biomass_025)))
percent5_biomass_1 = c(percent5_biomass_1$scientific_name, rep(NA, max_n - nrow(percent5_biomass_1)))

afsc_spp_lists <- data.frame(percent5, percent20, percent5_biomass_025, percent5_biomass_1)
saveRDS(afsc_spp_lists, "data-raw/afsc_spp_lists.rds")

#or splitting region into Bering vs GOA and AI surveys
goaai_haul <- filter(afsc_haul, survey_name %in% c("Aleutian Islands", "Gulf of Alaska"))

percent5 <-  left_join(afsc_catch, afsc_haul) |>
  filter(survey_name %in% c("Aleutian Islands", "Gulf of Alaska")) |>
  group_by(scientific_name) |>
  summarise(freq = n() / nrow(goaai_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
  filter(freq > 0.05) |>
  distinct(scientific_name)

percent20 <- left_join(afsc_catch, afsc_haul) |>
  filter(survey_name %in% c("Aleutian Islands", "Gulf of Alaska")) |>
  group_by(scientific_name) |>
  summarise(freq = n() / nrow(goaai_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
  filter(freq > 0.2) |>
  distinct(scientific_name)

total_yr <- left_join(afsc_catch, afsc_haul) |>
  filter(survey_name %in% c("Aleutian Islands", "Gulf of Alaska")) |>
  mutate(year = lubridate::year(date)) |>
  group_by(year) |>
  summarise(total = sum(catch_weight))
total_mean <- mean(total_yr$total)

percent5_biomass_025 <- left_join(afsc_catch, afsc_haul) |>
  filter(survey_name %in% c("Aleutian Islands", "Gulf of Alaska")) |>
  filter(scientific_name %in% percent5$scientific_name) |>
  group_by(scientific_name) |>
  mutate(year = lubridate::year(date)) |>
  summarise(mean_catch = sum(catch_weight) / length(unique(year))) |>
  filter(mean_catch > 0.0025 * total_mean)

percent5_biomass_1 <- left_join(afsc_catch, afsc_haul) |>
  filter(survey_name %in% c("Aleutian Islands", "Gulf of Alaska")) |>
  filter(scientific_name %in% percent5$scientific_name) |>
  group_by(scientific_name) |>
  mutate(year = lubridate::year(date)) |>
  summarise(mean_catch = sum(catch_weight) / length(unique(year))) |>
  filter(mean_catch > 0.001 * total_mean)

max_n = max(nrow(percent5), nrow(percent20),
          nrow(percent5_biomass_025), nrow(percent5_biomass_1))

percent5 = c(percent5$scientific_name, rep(NA, max_n - nrow(percent5)))
percent20 = c(percent20$scientific_name, rep(NA, max_n - nrow(percent20)))
percent5_biomass_025 = c(percent5_biomass_025$scientific_name, rep(NA, max_n - nrow(percent5_biomass_025)))
percent5_biomass_1 = c(percent5_biomass_1$scientific_name, rep(NA, max_n - nrow(percent5_biomass_1)))

goaai_spp_lists <- data.frame(percent5, percent20, percent5_biomass_025, percent5_biomass_1)
saveRDS(goaai_spp_lists, "data-raw/goaai_spp_lists.rds")


bering_haul <- filter(afsc_haul, survey_name %in% c("eastern Bering Sea", "northern Bering Sea", "Bering Sea Slope"))

percent5 <-  left_join(afsc_catch, afsc_haul) |>
  filter(survey_name %in% c("eastern Bering Sea", "northern Bering Sea", "Bering Sea Slope")) |>
  group_by(scientific_name) |>
  summarise(freq = n() / nrow(goaai_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
  filter(freq > 0.05) |>
  distinct(scientific_name)

percent20 <- left_join(afsc_catch, afsc_haul) |>
  filter(survey_name %in% c("eastern Bering Sea", "northern Bering Sea", "Bering Sea Slope")) |>
  group_by(scientific_name) |>
  summarise(freq = n() / nrow(goaai_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
  filter(freq > 0.2) |>
  distinct(scientific_name)

total_yr <- left_join(afsc_catch, afsc_haul) |>
  filter(survey_name %in% c("eastern Bering Sea", "northern Bering Sea", "Bering Sea Slope")) |>
  mutate(year = lubridate::year(date)) |>
  group_by(year) |>
  summarise(total = sum(catch_weight))
total_mean <- mean(total_yr$total)

percent5_biomass_025 <- left_join(afsc_catch, afsc_haul) |>
  filter(survey_name %in% c("eastern Bering Sea", "northern Bering Sea", "Bering Sea Slope")) |>
  filter(scientific_name %in% percent5$scientific_name) |>
  group_by(scientific_name) |>
  mutate(year = lubridate::year(date)) |>
  summarise(mean_catch = sum(catch_weight) / length(unique(year))) |>
  filter(mean_catch > 0.0025 * total_mean)

percent5_biomass_1 <- left_join(afsc_catch, afsc_haul) |>
  filter(survey_name %in% c("eastern Bering Sea", "northern Bering Sea", "Bering Sea Slope")) |>
  filter(scientific_name %in% percent5$scientific_name) |>
  group_by(scientific_name) |>
  mutate(year = lubridate::year(date)) |>
  summarise(mean_catch = sum(catch_weight) / length(unique(year))) |>
  filter(mean_catch > 0.001 * total_mean)

max_n = max(nrow(percent5), nrow(percent20),
            nrow(percent5_biomass_025), nrow(percent5_biomass_1))

percent5 = c(percent5$scientific_name, rep(NA, max_n - nrow(percent5)))
percent20 = c(percent20$scientific_name, rep(NA, max_n - nrow(percent20)))
percent5_biomass_025 = c(percent5_biomass_025$scientific_name, rep(NA, max_n - nrow(percent5_biomass_025)))
percent5_biomass_1 = c(percent5_biomass_1$scientific_name, rep(NA, max_n - nrow(percent5_biomass_1)))

bering_spp_lists <- data.frame(percent5, percent20, percent5_biomass_025, percent5_biomass_1)
saveRDS(bering_spp_lists, "data-raw/bering_spp_lists.rds")
