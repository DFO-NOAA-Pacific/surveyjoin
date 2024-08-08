save_raw_data <- function(x, name = "pbs-haul") {
  dir.create("data-raw/data", showWarnings = FALSE)
  saveRDS(x,
    file = paste0("data-raw/data/", name, ".rds"),
    compress = "bzip2", version = 3
  )
}

#' Identify the local folder used for caching
#' @param name the directory name, default is the package name "surveyjoin"
#' @return The directory location used for caching
#' @importFrom rappdirs user_cache_dir
#' @importFrom rlang .data
#' @export
get_cache_folder <- function(name = "surveyjoin") {
  user_cache_dir(name)
}

download <- function(x, cache_folder = get_cache_folder()) {
  f <- "https://github.com/DFO-NOAA-Pacific/surveyjoin-data/raw/main/"
  utils::download.file(paste0(f, x), destfile = file.path(cache_folder, x))
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

#' Function to cache the data files locally
#'
#' @param region Region name(s)
#'
#' @return
#' Nothing returned; data files are cached locally.
#' @importFrom purrr map_chr walk map
#' @importFrom checkmate assert_choice
#' @importFrom cli cli_alert_success
#' @export
#'
#' @examples
#' \dontrun{
#' cache_data()
#' }
cache_data <- function(region = c("nwfsc", "pbs", "afsc")) {
  # valid region(s)?
  r <- map_chr(region, function(region) {
    assert_choice(
      region,
      c("nwfsc", "pbs", "afsc")
    )
  })

  # subset files?
  files <- cache_files()
  f <- map(r, ~ files[grepl(., files)])
  f <- unlist(f)

  # download/uncompress for speed
  dir.create(get_cache_folder(), showWarnings = FALSE)
  walk(f, download, cache_folder = get_cache_folder())
  # walk(f, uncompress)

  msg <- "All data downloaded and uncompressed"
  cli_alert_success(msg)
}

#' Load SQLite database
#'
#' @return Nothing; data is inserted into a local SQLite database.
#' @export
#' @importFrom rlang .data
#' @import cli dplyr purrr RSQLite
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
  haul <- map_dfr(f_haul, function(x) {
    out <- readRDS(file.path(get_cache_folder(), x))
    out$region <- gsub("([a-z]+)-[a-z]+.rds", "\\1", x)
    if (is.character(out$event_id)) out$event_id <- as.numeric(out$event_id)
    # out$event_id <- as.character(out$event_id)
    out$performance <- as.character(out$performance)
    out$year <- as.integer(lubridate::year(out$date))
    out$date <- as.character(lubridate::as_date(out$date))
    # FIXME: do this long before! Alaska
    out$lon_start <- ifelse(out$lon_start > 0, out$lon_start * -1, out$lon_start)
    out$lon_end <- ifelse(out$lon_end > 0, out$lon_end * -1, out$lon_end)
    if (out$region[1] == "pbs") {
      # Fix me earlier!
      out <- dplyr::rename(out, bottom_temp_c = .data$temperature_C) %>%
        dplyr::select(-.data$do_mlpL, -.data$salinity_PSU)
    }
    out
  })
  catch <- map_dfr(f_catch, function(x) {
    out <- readRDS(file.path(get_cache_folder(), x))
    out$region <- gsub("([a-z]+)-[a-z]+.rds", "\\1", x)
    out
  })
  cli::cli_alert_success("Raw data read into memory")

  catch <- left_join(catch, surveyjoin::spp_dictionary, by = join_by(.data$itis, .data$scientific_name))
  # stopifnot(sum(is.na(catch$scientific_name)) == 0L)
  cli::cli_alert_success("Taxonomic data joined to catch data")

  db <- dbConnect(RSQLite::SQLite(), dbname = sql_folder())
  on.exit(suppressWarnings(suppressMessages(DBI::dbDisconnect(db))))
  dbWriteTable(db, "haul", haul, overwrite = TRUE, append = FALSE)
  dbWriteTable(db, "catch", catch, overwrite = TRUE, append = FALSE)

  cli::cli_alert_success("SQLite database created")
}


sql_folder <- function() {
  file.path(get_cache_folder(), "surveyjoin.sqlite")
}

#' Function to create a connection to the database
#'
#' @return a [DBI::dbConnect()] connection to the database
#' @importFrom RSQLite dbConnect SQLite
#' @examples
#' \dontrun{
#' db <- surv_db()
#' }
surv_db <- function() {
  dbConnect(SQLite(), dbname = sql_folder())
}

#' Get the ITIS identifier of a species
#' @param spp (character) Taxonomic name to query
#' @return an integer representing the ITIS identifier
#' @export
#' @importFrom taxize get_ids
#' @examples
#' \dontrun{
#' id <- get_itis_spp("darkblotched rockfish")
#' }
get_itis_spp <- function(spp) {
  out <- get_ids(spp, db = "itis", verbose = FALSE)
  as.integer(unlist(out))
}

#' Get the metadata URLs for each dataset
#' @return a dataframe with the metadata URL for each region
#' @export
#' @examples
#' \dontrun{
#' m <- get_metadata()
#' }
get_metadata <- function() {
  df <- data.frame(
    region = c("afsc", "pbs", "nwfsc"),
    url = c(
      "https://afsc-gap-products.github.io/gap_products/content/foss-metadata.html",
      NA, "https://www.fisheries.noaa.gov/inport/item/18418"
    )
  )
  return(df)
}

#' Get the name for each survey and corresponding region
#' @return a dataframe with the survey name and associated region
#' @export
#' @examples
#' \dontrun{
#' m <- get_survey_names()
#' }
get_survey_names <- function() {
  df <- data.frame(
    survey = c(
      "Aleutian Islands", "Gulf of Alaska", "eastern Bering Sea",
      "northern Bering Sea", "Bering Sea Slope", "NWFSC.Combo", "NWFSC.Shelf", "NWFSC.Hypoxia",
      "NWFSC.Hypoxia", "Triennial", "SYN QCS", "SYN HS", "SYN WCVI", "SYN WCHG"
    ),
    region = c(rep("afsc", 5), rep("nwfsc", 5), rep("pbs", 4))
  )
  return(df)
}


#' Get the survey grid shapefiles for each dataset
#' @return a dataframe with the URL for each region
#' @export
#' @examples
#' \dontrun{
#' m <- get_shapefiles()
#' }
get_shapefiles <- function() {
  df <- data.frame(
    region = c("afsc", "pbs", "nwfsc"),
    url = c(
      "https://github.com/afsc-gap-products/akgfmaps",
      "https://github.com/pbs-assess/gfplot/tree/master/data",
      "https://www.webapps.nwfsc.noaa.gov/portal7/home/item.html?id=32f29675457e44d3b2e88f454f130ac9"
    )
  )
  return(df)
}

#' Get the URLs to raw data for each dataset
#' @return a dataframe with the URL for each region
#' @export
#' @examples
#' \dontrun{
#' m <- get_rawdata()
#' }
get_rawdata <- function() {
  df <- data.frame(
    region = c("afsc", "pbs", "nwfsc"),
    url = c(
      "https://www.fisheries.noaa.gov/foss/f?p=215:28",
      NA,
      "https://www.webapps.nwfsc.noaa.gov/data"
    )
  )
  return(df)
}

#' Get the table of common and scientific names in the joined dataset
#' @return a dataframe with the common and scientific name
#' @import dplyr
#' @importFrom DBI dbDisconnect
#' @export
#' @examples
#' \dontrun{
#' get_species()
#' }
get_species <- function() {
  db <- surv_db()
  catch <- as.data.frame(tbl(db, "catch"))
  catch_tbl <- dplyr::group_by(catch, .data$common_name) |>
    dplyr::summarise(scientific_name = .data$scientific_name[1], itis = .data$itis[1]) |>
    dplyr::filter(!is.na(.data$scientific_name), !is.na(.data$common_name))
  catch_tbl
}
