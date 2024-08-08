library(dplyr)
library(lubridate)
# remotes::install_github("nwfsc-assess/nwfscSurvey")
library(nwfscSurvey)

# pull in the haul data from various nwfsc surveys
catch_nwfsc_combo <- nwfscSurvey::pull_catch(survey = "NWFSC.Combo")
catch_nwfsc_combo$survey_name <- "NWFSC.Combo"

catch_nwfsc_slope <- nwfscSurvey::pull_catch(survey = "NWFSC.Slope")
catch_nwfsc_slope$survey_name <- "NWFSC.Slope"

catch_nwfsc_shelf <- nwfscSurvey::pull_catch(survey = "NWFSC.Shelf")
catch_nwfsc_shelf$survey_name <- "NWFSC.Shelf"

catch_nwfsc_hypox <- nwfscSurvey::pull_catch(survey = "NWFSC.Hypoxia")
catch_nwfsc_hypox$survey_name <- "NWFSC.Hypoxia"

catch_nwfsc_tri <- nwfscSurvey::pull_catch(survey = "Triennial")
catch_nwfsc_tri$survey_name <- "Triennial"

# bind together
catch <- rbind(
  catch_nwfsc_combo,
  catch_nwfsc_slope,
  catch_nwfsc_shelf,
  catch_nwfsc_hypox,
  catch_nwfsc_tri
)

catch <- dplyr::rename(catch,
  event_id = Trawl_id,
  common_name = Common_name,
  scientific_name = Scientific_name,
  catch_numbers = total_catch_numbers,
  catch_wt = total_catch_wt_kg
) %>%
  dplyr::select(
    event_id, common_name, scientific_name, catch_numbers,
    catch_wt
  )

catch$common_name <- tolower(catch$common_name)
catch$scientific_name <- tolower(catch$scientific_name)

# Filter out species that occur in 20% of tows
n_tows <- length(unique(catch$event_id))
totals <- dplyr::filter(catch, !is.na(scientific_name), catch_wt > 0) %>%
  dplyr::group_by(scientific_name) %>%
  dplyr::summarize(
    common_name = common_name[1],
    p = length(unique(event_id)) / n_tows, # proportion of all tows that include this species
    tot_catch = sum(catch_wt)
  ) %>%
  dplyr::arrange(-p)

list_20_percent <- dplyr::filter(totals, p >= 0.2)
list_5_percent <- dplyr::filter(totals, p >= 0.05)

# Next, get year info
catch$year <- as.numeric(substr(catch$event_id, 1, 4))

filtered_5_percent <- dplyr::filter(catch, scientific_name %in% list_5_percent$scientific_name) %>%
  dplyr::group_by(year) %>%
  dplyr::mutate(total_annual_weight = sum(catch_wt)) %>%
  dplyr::group_by(year, scientific_name) %>%
  dplyr::mutate(total_annual_species_p = sum(catch_wt) / total_annual_weight) %>%
  dplyr::group_by(scientific_name) %>%
  dplyr::summarise(
    mean_p = mean(total_annual_species_p),
    common_name = common_name[1]
  )

list_5_percent_biomass_025 <- dplyr::filter(filtered_5_percent, mean_p > 0.25 / 100)
list_5_percent_biomass_1 <- dplyr::filter(filtered_5_percent, mean_p > 0.1 / 100)


# remove the inverts
terms_to_exclude <- c(
  "unident", "anemone", "shrimp", "star", "squid", "crab", "jelly", "urchin", "whelk",
  "pasiphaeid", "snail", "tongue", "cucumber", "unsorted"
)
pattern <- paste(terms_to_exclude, collapse = "|")

list_5_percent_biomass_025 <- list_5_percent_biomass_025[-grep(pattern, list_5_percent_biomass_025$common_name, ignore.case = TRUE), ]
list_5_percent_biomass_1 <- list_5_percent_biomass_1[-grep(pattern, list_5_percent_biomass_1$common_name, ignore.case = TRUE), ]
list_5_percent <- list_5_percent[-grep(pattern, list_5_percent$common_name, ignore.case = TRUE), ]
list_20_percent <- list_20_percent[-grep(pattern, list_20_percent$common_name, ignore.case = TRUE), ]

max_size <- max(
  length(list_5_percent_biomass_025$common_name), length(list_5_percent$common_name),
  length(list_20_percent$common_name), length(list_5_percent_biomass_1$common_name)
)

df <- data.frame(
  "percent5" = rep(NA, max_size),
  "percent20" = rep(NA, max_size),
  "percent5_biomass_025" = rep(NA, max_size),
  "percent5_biomass_1" = rep(NA, max_size)
)

df$percent5[1:length(list_5_percent$scientific_name)] <- list_5_percent$scientific_name
df$percent20[1:length(list_20_percent$scientific_name)] <- list_20_percent$scientific_name
df$percent5_biomass_025[1:length(list_5_percent_biomass_025$scientific_name)] <- list_5_percent_biomass_025$scientific_name
df$percent5_biomass_1[1:length(list_5_percent_biomass_1$scientific_name)] <- list_5_percent_biomass_1$scientific_name

saveRDS(df, "data-raw/nwfsc_spp_lists.rds")
