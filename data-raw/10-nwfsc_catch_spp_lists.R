library(dplyr)
library(lubridate)
#remotes::install_github("nwfsc-assess/nwfscSurvey")
library(nwfscSurvey)

# pull in the haul data from various nwfsc surveys
catch_nwfsc_combo <- nwfscSurvey::PullCatch.fn(SurveyName = "NWFSC.Combo")
catch_nwfsc_combo$survey_name <- "NWFSC.Combo"

catch_nwfsc_slope <- nwfscSurvey::PullCatch.fn(SurveyName = "NWFSC.Slope")
catch_nwfsc_slope$survey_name <- "NWFSC.Slope"

catch_nwfsc_shelf <- nwfscSurvey::PullCatch.fn(SurveyName = "NWFSC.Shelf")
catch_nwfsc_shelf$survey_name <- "NWFSC.Shelf"

catch_nwfsc_hypox <- nwfscSurvey::PullCatch.fn(SurveyName = "NWFSC.Hypoxia")
catch_nwfsc_hypox$survey_name <- "NWFSC.Hypoxia"

catch_nwfsc_tri <- nwfscSurvey::PullCatch.fn(SurveyName = "Triennial")
catch_nwfsc_tri$survey_name <- "Triennial"

# bind together
catch <- rbind(catch_nwfsc_combo,
               catch_nwfsc_slope,
               catch_nwfsc_shelf,
               catch_nwfsc_hypox,
               catch_nwfsc_tri)

catch <- dplyr::rename(catch,
                       event_id = Trawl_id,
                       common_name = Common_name,
                       catch_numbers = total_catch_numbers,
                       catch_wt = total_catch_wt_kg) %>%
  dplyr::select(event_id, common_name, catch_numbers,
                catch_wt)

catch$common_name <- tolower(catch$common_name)

# Filter out species that occur in 20% of tows
n_tows <- length(unique(catch$event_id))
totals <- dplyr::filter(catch, !is.na(common_name), catch_wt > 0) %>%
  dplyr::group_by(common_name) %>%
  dplyr::summarize(p = length(unique(event_id)) / n_tows, # proportion of all tows that include this species
                   tot_catch = sum(catch_wt)) %>%
  dplyr::arrange(-p)

list_20_percent <- sort(totals$common_name[which(totals$p >= 0.2)])
list_5_percent <- sort(totals$common_name[which(totals$p >= 0.05)])

# Next, get year info
catch$year <- as.numeric(substr(catch$event_id, 1, 4))

filtered_5_percent <- dplyr::filter(catch, common_name %in% list_5_percent) %>%
  dplyr::group_by(year) %>%
  dplyr::mutate(total_annual_weight = sum(catch_wt)) %>%
  dplyr::group_by(year, common_name) %>%
  dplyr::mutate(total_annual_species_p = sum(catch_wt) / total_annual_weight ) %>%
  dplyr::group_by(common_name) %>%
  dplyr::summarise(mean_p = mean(total_annual_species_p))

list_5_percent_biomass_025 <- sort(filtered_5_percent$common_name[which(filtered_5_percent$mean_p > 0.25/100)])

list_5_percent_biomass_1 <- sort(filtered_5_percent$common_name[which(filtered_5_percent$mean_p > 0.1/100)])

# remove unident and invert species
remove_inverts <- function(x) {
  # Define the terms to exclude
  terms_to_exclude <- c("unident", "anemone", "shrimp", "star", "squid", "crab", "jelly", "urchin", "whelk",
                        "pasiphaeid","snail","tongue","cucumber","unsorted")
  indices_to_remove <- unique(Reduce(c, sapply(terms_to_exclude, grep, x = x)))
  x <- x[-indices_to_remove]
  return(x)
}

list_5_percent_biomass_025 <- remove_inverts(list_5_percent_biomass_025)
list_5_percent_biomass_1 <- remove_inverts(list_5_percent_biomass_1)
list_5_percent <- remove_inverts(list_5_percent)
list_20_percent <- remove_inverts(list_20_percent)

max_size <- max(length(list_5_percent_biomass_025), length(list_5_percent),
                length(list_20_percent), length(list_5_percent_biomass_1))

df <- data.frame("percent5" = rep(NA, max_size),
                 "percent20" = rep(NA,max_size),
                 "percent5_biomass_025" = rep(NA, max_size),
                 "percent5_biomass_1" = rep(NA, max_size))

df$percent5[1:length(list_5_percent)] = list_5_percent
df$percent20[1:length(list_20_percent)] = list_20_percent
df$percent5_biomass_025[1:length(list_5_percent_biomass_025)] = list_5_percent_biomass_025
df$percent5_biomass_1[1:length(list_5_percent_biomass_1)] = list_5_percent_biomass_1

saveRDS(df, "data-raw/nwfsc_spp_lists.rds")
