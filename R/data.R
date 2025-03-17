#' Data frame of species common names, scientific names, and ITIS numbers
#'
#' @format A data frame.
"spp_dictionary"


#' Data frame containing two survey grids for the West Coast Bottom Trawl Survey
#' (WCBTS, "NWFSC.Combo") and triennial survey ("Triennial") collected by NOAA's
#' Northwest Fisheries Science Center. Columns include the latitude and
#' longitude in decimal degrees, area of each survey cell (in hectares), the
#' survey name (`survey`) year of update (`survey_domain_year`),
#' depth (currently in meters), and `split_state` indicating whether the cell
#' is in California, Oregon, or Washington
#'
#' @format A data frame.
"nwfsc_grid"


#' Data frame containing the survey grid for the Fisheries and Oceans Canada's
#' synoptic trawl survey collected by DFO's Pacific Biological Station.
#' Columns include the latitude and longitude in decimal degrees, area of each
#' survey cell (in hectares), the survey name (`survey`) and year of update
#' (`survey_domain_year`) and depth
#'
#' @format A data frame.
"dfo_synoptic_grid"


#' Data frame containing multiple survey grids for surveys collected by NOAA's Alaska
#' Fisheries Science Center. Columns include the latitude
#' and longitude in decimal degrees, area of each survey cell (in hectares), the survey
#' name (`survey`) year of update (`survey_domain_year`) and depth (currently NA
#' for this dataset and must be joined in separately). Survey names generally match
#' those for data in `get_data()`
#'
#' @format A data frame.
"afsc_grid"
