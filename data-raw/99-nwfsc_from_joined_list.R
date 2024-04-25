library(dplyr)
library(lubridate)
#remotes::install_github("nwfsc-assess/nwfscSurvey")
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
catch <- rbind(catch_nwfsc_combo,
               catch_nwfsc_slope,
               catch_nwfsc_shelf,
               catch_nwfsc_hypox,
               catch_nwfsc_tri)



catch <- dplyr::rename(catch,
                       event_id = Trawl_id,
                       common_name = Common_name,
                       scientific_name = Scientific_name,
                       catch_numbers = total_catch_numbers,
                       catch_wt = total_catch_wt_kg) %>%
  dplyr::select(event_id, common_name, scientific_name, catch_numbers,
                catch_wt)

catch$common_name <- tolower(catch$common_name)
catch$scientific_name <- tolower(catch$scientific_name)

# load in joined list
joined <- readRDS("data-raw/joined_list.rds")
# identify any problem spp because of formatting, etc
# all good here -- these look to be in north
joined$scientific_name[which(joined$scientific_name %in% catch$scientific_name==FALSE)]

sum(catch$catch_wt) #7378366
catch <- dplyr::filter(catch, scientific_name %in% joined$scientific_name)
sum(catch$catch_wt) #4935823, retaining 2/3 of total catch

catch <- dplyr::left_join(catch, joined)

catch <- dplyr::rename(catch, catch_weight = catch_wt)
catch <- dplyr::select(catch, event_id, itis, catch_numbers, catch_weight)

save_raw_data(catch, "nwfsc-catch")
