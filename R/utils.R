save_raw_data <- function(x, name = "pbs-haul") {
  dir.create("data-raw/data", showWarnings = FALSE)
  saveRDS(x, file = paste0("data-raw/data/", name, ".rds"),
    compress = "bzip2", version = 3)
}

cache_folder <- function(name = "surveyjoin") {
  rappdirs::user_cache_dir(name)
}

drive_folder <- function(path = "West Coast Survey Data Join/data") {
  # googledrive::drive_get(
  #   path = path
  # )
  path
}

download <- function(x) {
  cli::cli_progress_step(
    "Downloading {x}",
    msg_done = "{x} data cached"
  )
  googledrive::local_drive_quiet()
  googledrive::drive_download(
    file = file.path(drive_folder(), x),
    path = file.path(cache_folder(), x),
    overwrite = TRUE
  )
}

uncompress <- function(x) { # for reading speed:
  cli::cli_progress_step(
    "Uncompressing {x} ",
    msg_done = "{x} uncompressed"
  )
  p <- file.path(cache_folder(), x)
  d <- readRDS(p)
  saveRDS(p, x, compress = FALSE, version = 3)
}

cache_files <- function() {
  c(
    "pbs-catch.rds",
    "pbs-haul.rds",
    "afsc-catch.rds",
    "afsc-haul.rds",
    "nwfsc-catch.rds",
    "nwfsc-haul.rds"
  )
}

#' Cache data
#'
#' @param region Region name(s)
#'
#' @return
#' Nothing returned; data files are cached locally.
#' @export
#'
#' @examples
#' \dontrun{
#' cache_data()
#' }
cache_data <- function(region = c("nwfsc", "pbs", "afsc")) {
  # valid region(s)?
  r <- purrr::map_chr(region, function(region) {
    checkmate::assert_choice(
      region,
      c("nwfsc", "pbs", "afsc"))}
  )

  # subset files?
  files <- cache_files()
  f <- purrr::map(r, ~files[grepl(., files)])
  f <- unlist(f)

  # download/uncompress for speed
  dir.create(cache_folder(), showWarnings = FALSE)
  purrr::walk(f, download)
  purrr::walk(f, uncompress)

  msg <- "All data downloaded and uncompressed"
  cli::cli_alert_success(msg)
}

#' Load SQLite database
#'
#' @return Nothing; data is inserted into a local SQLite database.
#' @export
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' load_sql_data()
#' }
load_sql_data <- function() {
  f <- cache_files()
  f_haul <- sort(f[grepl("haul", f)])
  f_catch <- sort(f[grepl("catch", f)])
  stopifnot(length(f_haul) == length(f_catch))
  haul <- purrr::map_dfr(f_haul, function(x) {
    out <- readRDS(file.path(cache_folder(), x))
    out$region <- gsub("([a-z]+)-[a-z]+.rds", "\\1", x)
    out$performance <- as.character(out$performance)
    out$year <- as.integer(lubridate::year(out$date))
    out$date <- as.character(lubridate::as_date(out$date))
    # FIXME: do this long before! Alaska
    out$lon_start <- ifelse(out$lon_start > 0, out$lon_start * -1, out$lon_start)
    out$lon_end <- ifelse(out$lon_end > 0, out$lon_end * -1, out$lon_end)
    out
  })
  catch <- purrr::map_dfr(f_catch, function(x) {
    out <- readRDS(file.path(cache_folder(), x))
    out$region <- gsub("([a-z]+)-[a-z]+.rds", "\\1", x)
    out
  })
  cli::cli_alert_success("Raw data read into memory")

  catch <- dplyr::left_join(catch, surveyjoin::spp_dictionary)
  stopifnot(sum(is.na(catch$scientific_name)) == 0L)
  cli::cli_alert_success("Taxonomic data joined to catch data")

  db <- RSQLite::dbConnect(RSQLite::SQLite(), dbname = sql_folder())
  on.exit(suppressWarnings(suppressMessages(DBI::dbDisconnect(db))))
  RSQLite::dbWriteTable(db, "haul", haul, overwrite = TRUE, append = FALSE)
  RSQLite::dbWriteTable(db, "catch", catch, overwrite = TRUE, append = FALSE)

  cli::cli_alert_success("SQLite database created")
}


sql_folder <- function() {
  file.path(cache_folder(), "surveyjoin.sqlite")
}

#' Load the survey database
#'
#' @return a [DBI::dbConnect()] connection to the database
#' @export
#'
#' @examples
#' \dontrun{
#' db <- surv_db()
#'
#' }
surv_db <- function() {
  RSQLite::dbConnect(RSQLite::SQLite(), dbname = sql_folder())
}

get_itis_spp <- function(spp) {
  out <- taxize::get_ids(spp, db = "itis", verbose = FALSE)
  as.integer(unlist(out))
}

#' Query the survey database
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
#' "NWFSC.Combo", "NWFSC.Shelf", "NWFSC.Hypoxia", "NWFSC.Hypoxia", "Triennial", "SYN QCS",
#' "SYN HS", "SYN WCVI", "SYN WCHG". If NULL, all are returned
#' @param years a vector of years, e.g. `year = 2013:2018`. If NULL, all are returned
#' @return a dataframe of joined haul and catch data
#' @import dplyr
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
      filter(common %in% common)
  }
  if(!is.null(scientific)) {
    catch <- catch |>
      filter(scientific %in% scientific)
  }
  if(!is.null(itis_id)) {
    catch <- catch |>
      filter(itis_id %in% itis_id)
  }

  # Filter hauls as needed, default returns all
  if(!is.null(surveys)) {
    haul <- haul |>
      filter(survey_name %in% surveys)
  }

  # Join data and filter years if specified
  d <- catch |>
    left_join(haul) |>
    collect(n = Inf)
  if(!is.null(years)) {
    d <- d |>
      filter(year %in% years)
  }
  if(!is.null(regions)) {
    d <- d |>
      filter(region %in% regions)
  }
  DBI::dbDisconnect(conn = db)

  return(d)
}

# make_itis_spp_table()

# results <- bird_tracking %>%
#   filter(device_info_serial == 860) %>%
#   select(date_time, latitude, longitude, altitude) %>%
#   filter(date_time < "2014-07-01") %>%
#   filter(date_time > "2014-03-01")
# head(results)

