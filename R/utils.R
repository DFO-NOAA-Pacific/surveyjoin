save_raw_data <- function(x, name = "pbs-haul") {
  dir.create("data-raw/data", showWarnings = FALSE)
  saveRDS(x,
    file = paste0("data-raw/data/", name, ".rds"),
    compress = "bzip2", version = 3
  )
}

files_to_cache <- function() {
  f <- c(
    "pbs-catch.rds",
    "pbs-haul.rds",
    "afsc-catch.rds",
    "afsc-haul.rds",
    "nwfsc-catch.rds",
    "nwfsc-haul.rds"
  )
  return(f)
}

#' Identify the local folder used for caching
#'
#' @param name The directory name, default is the package name `"surveyjoin"`.
#' @return The directory location used for caching
#' @importFrom rappdirs user_cache_dir
#' @importFrom rlang .data
#' @export
get_cache_folder <- function(name = "surveyjoin") {
  # platform specific directories -- Windows has unique handling
  # https://www.rdocumentation.org/packages/rappdirs/versions/0.3.3/topics/user_cache_dir
  user_cache_dir(appname = name, appauthor = NULL)
}

#' Function to get the metadata file path
#' @return NULL
get_metadata_file <- function() {
  file.path(get_cache_folder(), "data_metadata.json")
}

#' Function to load metadata
#' @importFrom jsonlite fromJSON
#' @return NULL
load_metadata <- function() {
  metadata_file <- get_metadata_file()

  # Load existing metadata if available, otherwise create a new list
  if (file.exists(metadata_file)) {
    fromJSON(metadata_file)
  } else {
    list(files = list(), version = "0.1", last_download = NULL)
  }
}

#' Public facing function to create table of metadata
#' @return dataframe containing file names and dates of last update
#' @export
data_version <- function() {
  meta <- load_metadata()
  df <- data.frame(file = files_to_cache(),
                   last_updated = as.character(unlist(lapply(meta[[1]], getElement, 3))))
  return(df)
}

#' Function to save metadata
#' @param metadata the name of the metadata object
#' @importFrom jsonlite write_json
#' @return NULL
save_metadata <- function(metadata) {
  metadata_file <- get_metadata_file()
  # make sure directory exists before writing the file
  cache_dir <- dirname(metadata_file)
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  }
  write_json(metadata, metadata_file, pretty = TRUE, auto_unbox = TRUE)
}


#' Wrapper function to cache files only if a newer version exists
#' @return NULL
#' @importFrom cli cli_inform
#' @importFrom utils download.file
cache_files <- function() {

  running_ci <- Sys.getenv("GITHUB_ACTIONS") == "true"
  if (running_ci) {
    cli_inform("Running in CI: Skipping cache_files() file downloads.")
    return(NULL)  # skip this step, ignore rest of function
  }

  files <- files_to_cache()
  metadata <- load_metadata()
  cache_folder <- get_cache_folder()

  if (!dir.exists(cache_folder)) {
    dir.create(cache_folder, recursive = TRUE, showWarnings = FALSE)
  }

  for (file in files) {
    # Get timestamp from GitHub and local file path
    last_modified <- file_last_modified(file)
    local_file <- file.path(cache_folder, file)

    # Compare versions between Github timestamp and local version
    download_file <- TRUE
    if (file.exists(local_file) && !is.null(last_modified)) {
      cached_version <- metadata$files[[file]]$version
      if (!is.null(cached_version) && last_modified <= cached_version) {
        cli_inform(paste("Skipping:", file, "- Local version is up to date"))
        download_file <- FALSE
      }
    }

    if(download_file) {
      # new version of file needs downloading
      f <- "https://github.com/DFO-NOAA-Pacific/surveyjoin-data/raw/main/"
      try({
        download.file(paste0(f, file), destfile = local_file, mode = "wb")

        # Add version info to attributes and re-save
        temp <- readRDS(local_file)
        attr(temp, "version") <- last_modified
        saveRDS(temp, local_file)

        # Update metadata
        file_info <- file.info(local_file)
        metadata$files[[file]] <- list(
          version = last_modified,
          size = file_info$size,
          last_modified = last_modified
        )

        cli_inform(paste("Updated:", file))
      }, silent = TRUE)
    }
  }

}


#' Function to get the last modified date of a file from GitHub
#' @param file_name the file name, e.g. "nwfsc-catch.rds"
#' @return The time stamp file was last changed
#' @importFrom httr GET content user_agent status_code
#' @importFrom cli cli_abort cli_inform
#' @export
file_last_modified <- function(file_name) {
  # Specify the repo and file path
  repo <- "DFO-NOAA-Pacific/surveyjoin-data"
  url <- paste0("https://api.github.com/repos/", repo, "/commits?path=", file_name)

  # Make a GET request to GitHub API
  response <- GET(url, user_agent("R (httr)"))

  # Check for a successful response
  if (status_code(response) == 200) {
    # Parse the response and get the last commit date for the file
    commit_data <- content(response, as = "parsed")
    if (length(commit_data) > 0) {
      # Extract the timestamp on last commit
      last_modified <- commit_data[[1]]$commit$committer$date
      return(last_modified)
    } else {
      cli_abort(paste("No commits found for file:", file_name))
    }
  } else if (status_code(response) == 403) {  # Rate limit exceeded
    cli_inform("GitHub API rate limit exceeded. Using local data if available.")
    return(NULL)
  } else {
    cli_abort(paste("Failed to get GitHub file info for: ", file_name))
  }
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
  # Ensure valid region(s)
  valid_regions <- c("nwfsc", "pbs", "afsc")
  purrr::walk(region, ~assert_choice(.x, valid_regions))

  files <- cache_files()

  cli_alert_success("All data for region(s) {region} downloaded and cached")
}

#' Load SQLite database
#'
#' @return Nothing; data is inserted into a local SQLite database.
#' @export
#' @importFrom rlang .data
#' @importFrom dplyr %>%
#' @importFrom purrr map_dfr
#' @importFrom cli cli_alert_warning cli_abort cli_alert_info
#' @importFrom RSQLite dbWriteTable
#'
#' @examples
#' \dontrun{
#' load_sql_data()
#' }
load_sql_data <- function() {
  f <- files_to_cache()

  # detect if running in GitHub Actions
  in_ci <- Sys.getenv("GITHUB_ACTIONS") == "true"

  f_haul <- sort(f[grepl("haul", f)])
  f_catch <- sort(f[grepl("catch", f)])

  haul <- map_dfr(f_haul, function(x) {
    if (in_ci) {
      # Runnng in CI, read from GitHub
      url <- paste0("https://github.com/DFO-NOAA-Pacific/surveyjoin-data/raw/main/", x)
      cli::cli_alert_info("Downloading haul data from: {url}")
      temp <- tryCatch(readRDS(url(url)), error = function(e) {
        cli::cli_abort("Failed to download: {x}")
      })
    } else {
      # Read from local cache
      this_file <- file.path(get_cache_folder(), x)
      if (!file.exists(this_file)) {
        cli::cli_abort("File missing locally: {this_file}")
      } else {
        temp <- readRDS(this_file)
      }
    }

    if (!is.null(temp)) {
      temp$region <- gsub("([a-z]+)-[a-z]+.rds", "\\1", x)
      if (is.character(temp$event_id)) temp$event_id <- as.numeric(temp$event_id)
      temp$performance <- as.character(temp$performance)
      temp$year <- as.integer(lubridate::year(temp$date))
      temp$date <- as.character(lubridate::as_date(temp$date))
      temp$lon_start <- ifelse(temp$lon_start > 0, temp$lon_start * -1, temp$lon_start)
      temp$lon_end <- ifelse(temp$lon_end > 0, temp$lon_end * -1, temp$lon_end)
      if (temp$region[1] == "pbs") {
        temp <- dplyr::rename(temp, bottom_temp_c = "temperature_C") %>%
          dplyr::select(-"do_mlpL", -"salinity_PSU")
      }
    }
    temp
  })

  catch <- map_dfr(f_catch, function(x) {
    if (in_ci) {
      url <- paste0("https://github.com/DFO-NOAA-Pacific/surveyjoin-data/raw/main/", x)
      cli::cli_alert_info("Downloading catch data from: {url}")
      temp <- tryCatch(readRDS(url(url)), error = function(e) {
        cli::cli_abort("Failed to download: {x}")
      })
    } else {
      this_file <- file.path(get_cache_folder(), x)
      if (!file.exists(this_file)) {
        cli::cli_abort("File missing locally: {this_file}")
      } else {
        temp <- readRDS(this_file)
      }
    }

    if (!is.null(temp)) {
      temp$region <- gsub("([a-z]+)-[a-z]+.rds", "\\1", x)
    }
    temp
  })

  if (nrow(catch) != 0) {
    cli::cli_alert_success("Raw data read into memory")
    catch$scientific_name <- NULL
    catch <- dplyr::left_join(catch, surveyjoin::spp_dictionary, by = dplyr::join_by("itis"))

    db <- dbConnect(RSQLite::SQLite(), dbname = sql_folder())
    on.exit(suppressWarnings(suppressMessages(DBI::dbDisconnect(db))))
    dbWriteTable(db, "haul", haul, overwrite = TRUE, append = FALSE)
    dbWriteTable(db, "catch", catch, overwrite = TRUE, append = FALSE)

    cli::cli_alert_success("SQLite database created")
  } else {
    cli::cli_alert_warning("Data loading failed, SQLite database not created.")
  }
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
      "https://open.canada.ca/data/en/dataset/a278d1af-d567-4964-a109-ae1e84cbd24a", "https://www.fisheries.noaa.gov/inport/item/18418"
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
      "NWFSC.Slope", "Triennial", "SYN QCS", "SYN HS", "SYN WCVI", "SYN WCHG"
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
#' @importFrom DBI dbDisconnect
#' @export
#' @examples
#' \dontrun{
#' m <- get_species()
#' }
get_species <- function() {
  db <- surv_db()
  on.exit(suppressWarnings(suppressMessages(DBI::dbDisconnect(db))))
  catch <- as.data.frame(tbl(db, "catch"))
  catch_tbl <- dplyr::group_by(catch, .data$common_name) |>
    dplyr::summarise(scientific_name = .data$scientific_name[1], itis = .data$itis[1]) |>
    dplyr::filter(!is.na(.data$scientific_name), !is.na(.data$common_name))
  catch_tbl
}
