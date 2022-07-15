library(dplyr)
library(lubridate)
remotes::install_github("nwfsc-assess/nwfscSurvey")
library(nwfscSurvey)

# d <- dplyr::group_by(d, scientific_name) %>%
#   dplyr::summarise(common_name = common_name[1])
# d$scientific_name <- tolower(d$scientific_name)
# d$common_name <- tolower(d$common_name)
# species <- d
# usethis::use_data(species)
min_threshold <- 10 # minimum number of occurrences

data(species)

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

nwfsc_catch <- dplyr::left_join(catch, species) %>%
  dplyr::select(-common_name)

nwfsc_catch$catch_wt_units = "kg"

nwfsc_catch = dplyr::group_by(nwfsc_catch, scientific_name) %>%
  dplyr::mutate(n = length(which(catch_wt > 0))) %>%
  dplyr::filter(n >= min_threshold) %>%
  dplyr::select(-n)

usethis::use_data(nwfsc_catch, overwrite = TRUE)
