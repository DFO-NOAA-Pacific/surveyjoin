library(dplyr)

data_source <- "foss" # set to "foss" (public) or "oracle" (permissions needed)

# Load data from oracle via internal NOAA-NMFS-AFSC connection
if (data_source == "oracle") {
  library(RODBC)
  library(getPass)
  library(gapindex)

  channel <- gapindex::get_connected()

  haul <- RODBC::sqlQuery(channel, "SELECT * FROM GAP_PRODUCTS.FOSS_HAUL")
  names(haul) <- tolower(names(haul))

  # get catch data for fishes only, then filter to combined species list
  catch <- RODBC::sqlQuery(channel, "SELECT * FROM GAP_PRODUCTS.FOSS_CATCH
                         WHERE SPECIES_CODE < 32000")
  names(catch) <- tolower(names(catch))

  catch_spp <- RODBC::sqlQuery(channel, "SELECT * FROM GAP_PRODUCTS.FOSS_SPECIES
                         WHERE SPECIES_CODE < 32000")
  names(catch_spp) <- tolower(names(catch_spp))

  # get specimen data for fishes only (not available in public FOSS repo)
  afsc_specimen <- RODBC::sqlQuery(channel, "SELECT * FROM GAP_PRODUCTS.AKFIN_SPECIMEN
                         WHERE SPECIES_CODE < 32000")
  names(afsc_specimen) <- tolower(names(afsc_specimen))

  # TODO: process specimen data once common standards are determined,
  # join with catch_spp to get ITIS
  surveyjoin:::save_raw_data(afsc_specimen, "afsc-specimen")

} else if (data_source == "foss") { # Load data from FOSS public data API
  # adatapted from https://afsc-gap-products.github.io/gap_products/content/foss-api-r.html#haul-data
  # September 26, 2024 by Emily Markowitz

  library(httr)
  library(jsonlite)
  options(scipen = 999)

  # Load Haul Data -------------------------------------------------------------

  dat <- data.frame()
  for (i in seq(0, 500000, 10000)){
    # print(i)
    ## query the API link
    res <- httr::GET(url = paste0('https://apps-st.fisheries.noaa.gov/ods/foss/afsc_groundfish_survey_haul/',
                                  "?offset=",i,"&limit=10000"))
    ## convert from JSON format
    data <- jsonlite::fromJSON(base::rawToChar(res$content))

    ## if there are no data, stop the loop
    if (is.null(nrow(data$items))) {
      break
    }

    ## bind sub-pull to dat data.frame
    dat <- dplyr::bind_rows(dat,
                            data$items %>%
                              dplyr::select(-links)) # necessary for API accounting, but not part of the dataset)
  }
  haul <- dat %>%
    dplyr::mutate(date_time = as.POSIXct(date_time,
                                        format = "%Y-%m-%dT%H:%M:%S",
                                        tz = Sys.timezone()))

  # Load Species Data ------------------------------------------------------------

  res <- httr::GET(url = paste0('https://apps-st.fisheries.noaa.gov/ods/foss/afsc_groundfish_survey_species/',
                                "?offset=0&limit=10000", '&q={"species_code":{"$lt":32000}}'))

  ## convert from JSON format
  data <- jsonlite::fromJSON(base::rawToChar(res$content))
  catch_spp <- data$items  %>%
    dplyr::select(-links) # necessary for API accounting, but not part of the dataset

  # Load Catch Data ------------------------------------------------------------

  dat <- data.frame()
  for (i in seq(0, 1000000, 10000)){
    ## find how many iterations it takes to cycle through the data
    print(i)
    ## query the API link
    res <- httr::GET(url = paste0("https://apps-st.fisheries.noaa.gov/ods/foss/afsc_groundfish_survey_catch/",
                                  "?offset=",i,"&limit=10000", '&q={"species_code":{"$lt":32000}}'))
    ## convert from JSON format
    data <- jsonlite::fromJSON(base::rawToChar(res$content))

    ## if there are no data, stop the loop
    if (is.null(nrow(data$items))) {
      break
    }

    ## bind sub-pull to dat data.frame
    dat <- dplyr::bind_rows(dat,
                            data$items %>%
                              dplyr::select(-links)) # necessary for API accounting, but not part of the dataset)
  }

  catch <- dat

  # # Zero-Filled Data -----------------------------------------------------------
  #
  # dat <- dplyr::full_join(
  #   afsc_haul,
  #   afsc_catch) %>%
  #   dplyr::full_join(
  #     afsc_species)  %>%
  #   # modify zero-filled rows
  #   dplyr::mutate(
  #     cpue_kgkm2 = ifelse(is.na(cpue_kgkm2), 0, cpue_kgkm2),
  #     cpue_nokm2 = ifelse(is.na(cpue_nokm2), 0, cpue_nokm2),
  #     count = ifelse(is.na(count), 0, count),
  #     weight_kg = ifelse(is.na(weight_kg), 0, weight_kg))

}


# mostly for testing, but also nice to have it organized
catch <- catch[order(catch$species_code), ]
catch <- catch[order(catch$hauljoin), ]
haul <- haul[order(haul$hauljoin), ]

afsc_haul <- haul %>%
  dplyr::select(
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
    stratum,
    area_swept_km2,
    bottom_temp_c = bottom_temperature_c
  ) %>%
  dplyr::mutate(
    event_id = as.numeric(event_id),
    date = as.POSIXct(date,
                      format = "%m/%d/%Y %H:%M:%S",
                      tz = Sys.timezone()),
    pass = NA_integer_,
    lat_start = as.numeric(lat_start),
    lon_start = as.numeric(lon_start),
    lat_end = as.numeric(lat_end),
    lon_end = as.numeric(lon_end),
    depth_m = as.numeric(depth_m),
    effort = as.numeric(area_swept_km2 * 100), # convert to ha
    effort_units = "ha",
    performance = as.integer(performance),
    stratum = as.numeric(stratum),
    year = as.integer(format(date, format="%Y")),
    bottom_temp_c = as.numeric(bottom_temp_c)
  ) %>%
  dplyr::select(
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
    stratum,
    year,
    bottom_temp_c
  ) %>%
  tidyr::drop_na(lat_end, lon_end)

surveyjoin:::save_raw_data(afsc_haul, "afsc-haul")

catchjoin <- left_join(catch, catch_spp)
catchjoin$scientific_name <- tolower(catchjoin$scientific_name)

spp <- readRDS("data-raw/joined_list.rds")

afsc_catch <- catchjoin %>%
  dplyr::filter(scientific_name %in% spp$scientific_name) %>%
  dplyr::select(
    event_id = hauljoin,
    itis,
    scientific_name,
    catch_numbers = count,
    catch_weight = weight_kg
  ) %>%
  dplyr::mutate(
    event_id = as.numeric(event_id),
    catch_numbers = as.numeric(catch_numbers),
    catch_weight = as.numeric(catch_weight)
  )

surveyjoin:::save_raw_data(afsc_catch, "afsc-catch")

# # custom filter to most prevalent species, by category ----
# catch <- RODBC::sqlQuery(channel, "SELECT * FROM GAP_PRODUCTS.FOSS_CATCH")
# catch_spp <- RODBC::sqlQuery(channel, "SELECT * FROM GAP_PRODUCTS.FOSS_SPECIES")
# catchjoin <- left_join(catch, catch_spp)
# names(catchjoin) <- tolower(names(catchjoin))
#
# afsc_catch <- catchjoin %>%
#   filter(scientific_name %in% spp$scientific_name) %>%
#   select(
#     event_id = hauljoin,
#     itis,
#     scientific_name,
#     catch_numbers = count,
#     catch_weight = weight_kg,
#     id_rank,
#     species_code
#   ) %>%
#   mutate(
#     event_id = as.numeric(event_id),
#     catch_numbers = as.numeric(catch_numbers),
#     catch_weight = as.numeric(catch_weight)
#   )
#
# afsc_catch_fish <- afsc_catch %>%
#   filter(species_code < 32000) %>%
#   filter(id_rank == "species")
# afsc_catch_sfi <- afsc_catch %>%
#   filter(species_code %in% c(41000:45000, 91000:91999, 99981:99988)) # corals and sponges
# afsc_catch_inv <- afsc_catch %>%
#   filter(species_code %in% c(40000:40999, 45001:90999, 92000:99981)) # other inverts
#
# # filter by frequency of occurrence and catch weights
# fish_high <- group_by(afsc_catch_fish, scientific_name) |>
#   summarise(freq = n() / nrow(afsc_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
#   filter(total_weight > 1000) |> # freq > 0.01 gives 79 species vs 94
#   arrange(-freq)
# nrow(fish_high)
#
# fish_low <- group_by(afsc_catch_fish, scientific_name) |>
#   summarise(freq = n() / nrow(afsc_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
#   filter(total_weight > 1000, freq > 0.1) |>
#   arrange(-freq)
# nrow(fish_low)
#
# sfi_high <- group_by(afsc_catch_sfi, scientific_name) |>
#   summarise(freq = n() / nrow(afsc_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
#   filter(total_weight > 500) |>
#   arrange(-freq)
# nrow(sfi_high)
#
# sfi_low <- group_by(afsc_catch_sfi, scientific_name) |>
#   summarise(freq = n() / nrow(afsc_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
#   filter(total_weight > 500, freq > 0.02) |>
#   arrange(-freq)
# nrow(sfi_low)
#
# inv_high <- group_by(afsc_catch_inv, scientific_name) |>
#   summarise(freq = n() / nrow(afsc_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
#   filter(total_weight > 500, freq > 0.05) |>
#   arrange(-freq)
# nrow(inv_high)
#
# inv_low <- group_by(afsc_catch_inv, scientific_name) |>
#   summarise(freq = n() / nrow(afsc_haul), total_weight = sum(catch_weight), itis = itis[1]) |>
#   filter(total_weight > 500, freq > 0.15) |>
#   arrange(-freq)
# nrow(inv_low)
#
# afsc_catch <- select(afsc_catch, -scientific_name, - species_code, -id_rank)
#
# afsc_catch_fish_h <- semi_join(afsc_catch, select(fish_high, itis), by = join_by(itis))
# afsc_catch_fish_l <- semi_join(afsc_catch, select(fish_low, itis), by = join_by(itis))
# afsc_catch_sfi_h <- semi_join(afsc_catch, select(sfi_high, itis), by = join_by(itis))
# afsc_catch_sfi_l <- semi_join(afsc_catch, select(sfi_low, itis), by = join_by(itis))
# afsc_catch_inv_h <- semi_join(afsc_catch, select(inv_high, itis), by = join_by(itis))
# afsc_catch_inv_l <- semi_join(afsc_catch, select(inv_low, itis), by = join_by(itis))
#
# save_raw_data(afsc_catch_fish_h, "afsc-catch-fish-h")
# save_raw_data(afsc_catch_fish_l, "afsc-catch-fish-l")
# save_raw_data(afsc_catch_sfi_h, "afsc-catch-sfi-h")
# save_raw_data(afsc_catch_sfi_l, "afsc-catch-sfi-l")
# save_raw_data(afsc_catch_inv_h, "afsc-catch-inv-h")
# save_raw_data(afsc_catch_inv_l, "afsc-catch-inv-l")


# TEST similarities between foss and oracle tables -----------------------------
test <- FALSE
if (test == TRUE) {
  catch_foss <- catch; haul_foss <- haul; afsc_catch_foss<-afsc_catch; afsc_haul_foss <- afsc_haul
  catch_oracle <- catch; haul_oracle <- haul; afsc_catch_oracle<-afsc_catch; afsc_haul_oracle <- afsc_haul

  # Input catch and haul tables ------------------------------------------------

  check_diff <- function(bb, bbb){
    whoisaproblem <- c()
    for (i in names(bb)) {
      aa <- bb[,i]
      aa[is.na(aa)] <- 0
      aaa <- bbb[,i]
      aaa[is.na(aaa)] <- 0
      a <- (aa != aaa)
      whoisaproblem <- dplyr::bind_rows(
        whoisaproblem,
        data.frame(column = i,
                   issues = sum(a)) )
      if (sum(a)>0) {
        print(data.frame("col" = i, "foss" = aa[which(a)], "oracle" = aaa[which(a)], "diff" = aa[which(a)]-aaa[which(a)]))
      }
    }
    print(whoisaproblem)
  }

  dim(catch_oracle)
  dim(catch_foss)
  dim(haul_oracle)
  dim(haul_foss)

  str(catch_oracle)
  str(catch_foss)
  str(haul_oracle)
  str(haul_foss)

  check_diff(bb = haul_foss, bbb = haul_oracle)
  check_diff(bb = catch_foss, bbb = catch_oracle)

  # Final catch and haul tables ------------------------------------------------

  dim(afsc_catch_oracle)
  dim(afsc_catch_foss)
  dim(afsc_haul_oracle)
  dim(afsc_haul_foss)

  str(afsc_catch_oracle)
  str(afsc_catch_foss)
  str(afsc_haul_oracle)
  str(afsc_haul_foss)

  check_diff(bb = afsc_haul_foss, bbb = afsc_haul_oracle)
  check_diff(bb = afsc_catch_foss, bbb = afsc_catch_oracle)
}

