library(httr)
library(jsonlite)
library(dplyr)

# link to the API generated at [AFSC RACE Groundfish and Shellfish Survey Public Data](https://github.com/afsc-gap-products/gap_public_data)
api_link <- "https://origin-tst-ods-st.fisheries.noaa.gov/ods/foss/afsc_groundfish_survey/"

res <- httr::GET(url = api_link)
res

dat <- jsonlite::fromJSON(base::rawToChar(res$content))

afsc <- dat[[1]] %>% dplyr::select(
  survey_name = srvy,
  event_id = hauljoin,
  date = date_time,
  vessel = vessel_name,
  lat_start = latitude_dd_start,
  lon_start = longitude_dd_start,
  lat_end = latitude_dd_end,
  lon_end = longitude_dd_end,
  depth_m,
  effort = area_swept_ha,
  itis = itis,
  #itis_confidence = taxon_confidence, #consider adding this?
  catch_numbers = count,
  catch_weight = weight_kg,
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
    performance = NA_integer_,
    catch_numbers = as.numeric(catch_numbers),
    catch_weight = as.numeric(catch_weight),
    catch_weight_units = "kg"
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
    itis,
    catch_numbers,
    catch_weight
  )

str(afsc)

usethis::use_data(afsc, overwrite = TRUE)
