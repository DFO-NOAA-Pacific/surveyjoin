# authenticate
# googledrive::drive_auth(use_oob = TRUE, cache = FALSE)

# SA: I had to use this to get going instead of drive_auth()!?
googledrive::drive_find(n_max = 5)

# check link to shared folder
# drive_ls(path = "West Coast Survey Data Join/data")
# files <- googledrive::drive_ls(path = "West Coast Survey Data Join/data")

drive <- googledrive::drive_get(path = "West Coast Survey Data Join/data")

f <- c(
  "pbs-catch.rds",
  "pbs-haul.rds",
  "afsc-catch.rds",
  "afsc-haul.rds",
  "nwfsc-catch.rds",
  "nwfsc-haul.rds"
)

# drop those with no join in ITIS spp dictionary:
dir.create("data-raw/data-itis-filtered/", showWarnings = FALSE)
purrr::walk(f[grepl("catch", f)], function(x) {
  d <- readRDS(paste0("data-raw/data/", x))
  d <- dplyr::semi_join(d, spp_dictionary, by = join_by(itis))
  saveRDS(d, paste0("data-raw/data-itis-filtered/", x),
    compress = "bzip2", version = 3
  )
})
purrr::walk(f[grepl("haul", f)], function(x) {
  d <- readRDS(paste0("data-raw/data/", x))
  saveRDS(d, paste0("data-raw/data-itis-filtered/", x),
    compress = "bzip2", version = 3
  )
})

upload <- function(x) {
  googledrive::drive_upload(
    media = file.path("data-raw/data-itis-filtered", x),
    path = drive,
    overwrite = TRUE
  )
}

purrr::walk(f, upload)

# library(googledrive)
#
# # examples
# drive_download(
#   file = "West Coast Survey Data Join/data/afsc.rda",
#   path = "data-raw/afsc.rda"
# )
#
# drive_download(
#   file = "West Coast Survey Data Join/data/nwfsc_haul.rda",
#   path = "data-raw/nwfsc_haul.rda", overwrite = TRUE
# )
#
# drive_download(
#   file = "West Coast Survey Data Join/data/nwfsc_catch.rda",
#   path = "data-raw/nwfsc_catch.rda", overwrite = TRUE
# )
