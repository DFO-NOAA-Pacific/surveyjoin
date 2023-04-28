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

load_sql_data <- function() {
  f <- cache_files()
  f_haul <- sort(f[grepl("haul", f)])
  f_catch <- sort(f[grepl("catch", f)])
  stopifnot(length(f_haul) == length(f_catch))
  haul <- purrr::map_dfr(f_haul, function(x) {
    out <- readRDS(file.path(cache_folder(), x))
    out$region <- gsub("([a-z]+)-[a-z]+.rds", "\\1", x)
    out$performance <- as.character(out$performance)
    out
  })
  catch <- purrr::map_dfr(f_catch, function(x) {
    out <- readRDS(file.path(cache_folder(), x))
    out$region <- gsub("([a-z]+)-[a-z]+.rds", "\\1", x)
    out
  })

  catch <- left_join(catch, spp_dictionary, by = join_by(itis))
  stopifnot(sum(is.na(catch$scientific_name)) == 0L)

  db <- RSQLite::dbConnect(RSQLite::SQLite(), dbname = sql_folder())
  on.exit(suppressWarnings(suppressMessages(DBI::dbDisconnect(db))))
  RSQLite::dbWriteTable(db, "haul", haul, overwrite = TRUE, append = FALSE)
  RSQLite::dbWriteTable(db, "catch", catch, overwrite = TRUE, append = FALSE)
}


sql_folder <- function() {
  file.path(cache_folder(), "surveyjoin.sqlite")
}

# library(dplyr)

surv_db <- function() {
  RSQLite::dbConnect(RSQLite::SQLite(), dbname = sql_folder())
}

get_itis_spp <- function(itis) {
  out <- taxize::get_ids(spp, db = "itis", verbose = FALSE)
  as.integer(unlist(out))
}



# get_data <- function(species, survey)

# # db <-
#




# make_itis_spp_table()

# results <- bird_tracking %>%
#   filter(device_info_serial == 860) %>%
#   select(date_time, latitude, longitude, altitude) %>%
#   filter(date_time < "2014-07-01") %>%
#   filter(date_time > "2014-03-01")
# head(results)

