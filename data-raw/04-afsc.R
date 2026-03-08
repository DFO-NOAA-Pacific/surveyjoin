#---- Via Oracle internal server (requires credentials)

PKG <- unique(
  "dplyr",
  "RODBC",
  "rstudioapi")

for (p in PKG) {
  if(!require(p, character.only = TRUE)) {
    install.packages(p)
  }
  require(p, character.only = TRUE)
}

channel <- odbcConnect(dsn = "AFSC",
                       uid = rstudioapi::showPrompt(title = "Username",
                                                    message = "Oracle Username", default = ""),
                       pwd = rstudioapi::askForPassword("Enter Password"),
                       believeNRows = FALSE)
# channel <- gapindex::get_connected()
# source("Z:/Projects/ConnectToOracle.R"); channel <- channel_products # for em pulls :)

# Pull data from GAP_PRODUCTS --------------------------------------------------

locations <- c(
  "GAP_PRODUCTS.AKFIN_AGECOMP",
  # "GAP_PRODUCTS.AKFIN_AREA",
  "GAP_PRODUCTS.AKFIN_BIOMASS",
  "GAP_PRODUCTS.AKFIN_CATCH",
  "GAP_PRODUCTS.AKFIN_CRUISE",
  "GAP_PRODUCTS.AKFIN_HAUL",
  "GAP_PRODUCTS.AKFIN_CPUE",
  "GAP_PRODUCTS.AKFIN_METADATA_COLUMN",
  "GAP_PRODUCTS.AKFIN_SIZECOMP",
  "GAP_PRODUCTS.AKFIN_SPECIMEN",
  "GAP_PRODUCTS.SAMPLESIZE"#, # For for collecting number of length, age, and otolith samples
  # "GAP_PRODUCTS.AKFIN_STRATUM_GROUPS",
  # "GAP_PRODUCTS.AKFIN_SURVEY_DESIGN",
  # "GAP_PRODUCTS.AKFIN_TAXONOMIC_CLASSIFICATION",
  # "GAP_PRODUCTS.SPECIES_YEAR"
)

print(Sys.Date())

error_loading <- c()
for (i in 1:length(locations)){
  print(locations[i])

  a <- RODBC::sqlQuery(channel = channel,
                       query = paste0("SELECT *
    FROM ", locations[i], "
    FETCH FIRST 1 ROWS ONLY;"))

  end0 <- c()
  if ("SURVEY_DEFINITION_ID" %in% names(a)) {
    end0 <- c(end0, "SURVEY_DEFINITION_ID IN (143, 98, 52, 78, 47)")
  }
  if ("SPECIES_CODE" %in% names(a)) {
    end0 <- c(end0, "SPECIES_CODE < 32000")
  }

  end0 <- ifelse(is.null(end0), "", paste0(" WHERE ", paste0(end0, collapse = " AND ")))

  start0 <- ifelse(!("START_TIME" %in% names(a)),
                   "*",
                   paste0(paste0(names(a)[names(a) != "START_TIME"], sep = ",", collapse = " "),
                          " TO_CHAR(START_TIME,'MM/DD/YYYY HH24:MI:SS') START_TIME "))

  a <- RODBC::sqlQuery(channel, paste0("SELECT ", start0, " FROM ", locations[i], end0, "; "))

  if (is.null(nrow(a))) { # if (sum(grepl(pattern = "SQLExecDirect ", x = a))>1) {
    error_loading <- c(error_loading, locations[i])
  } else {
    filename0 <- tolower(locations[i])
    filename0 <- gsub(pattern = '.', replacement = "_", x = filename0, fixed = TRUE)
    filename0 <- gsub(pattern = "gap_products_", replacement = "", x = filename0, fixed = TRUE)
    filename0 <- gsub(pattern = "akfin_", replacement = "", x = filename0, fixed = TRUE)

    assign(value = a, x = filename0) # assign this data with the name of the file so we can check it out below

    filename0 <- paste0("afsc-", filename0)
    save(a, file = here::here("data-raw", paste0(filename0, ".rds")))
  }
  remove(a)
}
error_loading


if (FALSE) {

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
      area_swept_km2,
      bottom_temp_c = bottom_temperature_c
    ) %>%
    dplyr::mutate(
      event_id = as.numeric(event_id),
      date = as.POSIXct(date,
                        format = "%m/%d/%Y %H:%M:%S",
                        tz = Sys.timezone()),
      # date = as.POSIXct(date,
      #                   format = ifelse(data_source == "oracle",
      #                                   "%m/%d/%Y %H:%M:%S", # oracle
      #                                   "%Y-%m-%dT%H:%M:%S"), # foss
      #                   tz = Sys.timezone()),
      # date = as.POSIXct(date, format = "%m/%d/%Y %H:%M:%S", tz = Sys.timezone()),
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
  if (FALSE) {
    # catch_foss <- catch; haul_foss <- haul; afsc_catch_foss<-afsc_catch; afsc_haul_foss <- afsc_haul
    # catch_oracle <- catch; haul_oracle <- haul; afsc_catch_oracle<-afsc_catch; afsc_haul_oracle <- afsc_haul

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

}
