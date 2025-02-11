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

# data("spp_dictionary")

# pull in the haul data from various nwfsc surveys
catch_nwfsc_combo <- nwfscSurvey::pull_catch(survey = "NWFSC.Combo")
# remove hake, and re-query
catch_nwfsc_combo <- dplyr::filter(catch_nwfsc_combo, Common_name != "Pacific hake")
catch_nwfsc_combo_hake <- nwfscSurvey::pull_catch(survey = "NWFSC.Combo", common_name = "Pacific hake",
                                             sample_types = c("NA", NA, "Life Stage", "Size"))
catch_nwfsc_combo_hake <- nwfscSurvey::combine_tows(catch_nwfsc_combo_hake)
# join hake back in
catch_nwfsc_combo <- rbind(catch_nwfsc_combo, catch_nwfsc_combo_hake)
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

# do initial filter of all species that pass the 5% filter, regardless of other regions
nwfsc_list <- readRDS("data-raw/nwfsc_spp_lists.rds")
catch <- dplyr::filter(catch, scientific_name %in% nwfsc_list$percent5)

get_itis <- function(spp) {
  out <- taxize::get_ids(spp, db = "itis", verbose = FALSE)
  as.integer(unlist(out))
}

# Double checking the itis codes -- they're already pulled in joined_list.rds
spp <- sort(unique(catch$scientific_name))
itis_codes <- get_itis(spp)
spp_df <- tibble(scientific_name = spp, itis = itis_codes)
catch <- dplyr::left_join(catch, spp_df)
# bring in the common name
# nwfsc_catch <- dplyr::left_join(catch, spp_dictionary) #%>%
# dplyr::select(-common_name)
# specify units -- kilograms
# nwfsc_catch$catch_wt_units = "kg"

# filter out only species that are included in our joined list across regions
joined_list <- readRDS("data-raw/joined_list.rds")
nwfsc_catch_keep <- dplyr::filter(catch, itis %in% joined_list$itis)
# rename for consistency with other data
nwfsc_catch_keep <- rename(nwfsc_catch_keep, catch_weight = catch_wt)

# save space:
# nwfsc_catch_keep$catch_wt_units <- NULL
nwfsc_catch_keep$scientific_name <- NULL
nwfsc_catch_keep$common_name <- NULL
nwfsc_catch_keep$event_id <- as.numeric(nwfsc_catch_keep$event_id)

# usethis::use_data(nwfsc_catch, overwrite = TRUE)
surveyjoin:::save_raw_data(nwfsc_catch_keep, "nwfsc-catch")
