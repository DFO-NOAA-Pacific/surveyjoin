#' Main function to query the survey database
#'
#' @param common A string, or vector of strings of common names for species
#' @param scientific A string, or vector of strings of scientific names for species
#' @param itis_id An integer or vector of integers corresponding to ITIS identifiers
#' @param regions A string, or vector of strings of common names for regions. May be one or more
#' of "afsc", "nwfsc", "pbs". Surveys are nested within region, so returning data from a region will
#' return more than one survey.
#' @param surveys A string, or vector of strings of common names for surveys. May be one or more
#' of "Aleutian Islands Bottom Trawl Survey", "Eastern Bering Sea Crab/Groundfish Bottom Trawl Survey",
#' "Eastern Bering Sea Slope Bottom Trawl Survey", "Gulf of Alaska Bottom Trawl Survey",
#' "Northern Bering Sea Crab/Groundfish Survey - Eastern Bering Sea Shelf Survey Extension",
#' "NWFSC.Combo", "NWFSC.Shelf", "NWFSC.Hypoxia", "Triennial", "SYN QCS",
#' "SYN HS", "SYN WCVI", "SYN WCHG". If NULL, all are returned
#' @param years a vector of years, e.g. `year = 2013:2018`. If NULL, all are returned
#' @return a dataframe of joined haul and catch data
#' \itemize{
#'   \item \strong{event_id}: Unique haul identifier.
#'   \item \strong{itis}: ITIS identifier for species.
#'   \item \strong{catch_numbers}: Numbers of fish for this haul - species.
#'   \item \strong{catch_weight}: Weight (kg) of fish for this haul - species.
#'   \item \strong{region}: Region this survey originated in ("pbs", "nwfsc", "afsc").
#'   \item \strong{scientific_name}: Scientific name for this species.
#'   \item \strong{common_name}: Common name for this species.
#'   \item \strong{survey_name}: Name of the survey this haul is part of.
#'   \item \strong{date}: String representation of the date, format YYYY-MM-DD.
#'   \item \strong{pass}: Optional pass identifier (1 or 2), only used for NWFSC surveys.
#'   \item \strong{vessel}: Optional unique vessel identifier, not included in all surveys.
#'   \item \strong{lat_start}: Starting latitude of haul, decimal degrees.
#'   \item \strong{lon_start}: Starting longitude of haul, decimal degrees.
#'   \item \strong{lat_end}: Ending latitude of haul, decimal degrees.
#'   \item \strong{lon_end}: Ending longitude of haul, decimal degrees.
#'   \item \strong{depth_m}: Haul bottom depth (meters).
#'   \item \strong{effort}: Amount of units corresponding to this haul.
#'   \item \strong{effort_units}: Units of effort.
#'   \item \strong{performance}: Optional performance indicator for each haul, not used for all surveys. If not
#'   indicated, assume performance is satisfactory
#'   \item \strong{bottom_temp_c}: Bottom temperature recorded at the gear, in degrees Celsius.
#'   \item \strong{year}: Calendar year corresponding to the haul.
#' }
#' @import dplyr
#' @importFrom DBI dbDisconnect
#' @export
#'
#' @examples
#' \dontrun{
#' d <- get_data(common = "arrowtooth flounder", years = 2013:2018, region="pbs")
#' }
get_data <- function(common = NULL, scientific = NULL, itis_id = NULL, regions = NULL, surveys = NULL, years = NULL) {

  db <- surv_db() # create connection to database; need error checking
  catch <- tbl(db, "catch")
  haul <- tbl(db, "haul")

  if(!is.null(common)) common <- tolower(common)
  if(!is.null(scientific)) scientific <- tolower(scientific)
  if(!is.null(itis_id)) itis_id <- as.integer(itis_id)
  if(!is.null(years)) years <- as.integer(years)

  # Filter species as needed, default returns all
  if(!is.null(common)) {
    catch <- catch |>
      filter(common_name %in% common)
  }
  if(!is.null(scientific)) {
    catch <- catch |>
      filter(scientific_name %in% scientific)
  }
  if(!is.null(itis_id)) {
    catch <- catch |>
      filter(itis %in% itis_id)
  }

  # Filter hauls as needed, default returns all
  if(!is.null(surveys)) {
    haul <- haul |>
      filter(survey_name %in% surveys)
  }

  # Join data and filter years if specified
  d <- catch |>
    suppressWarnings(left_join(haul)) |>
    collect(n = Inf)
  if(!is.null(years)) {
    d <- d |>
      filter(year %in% years)
  }
  if(!is.null(regions)) {
    d <- d |>
      filter(region %in% regions)
  }
  dbDisconnect(conn = db)

  return(d)
}
