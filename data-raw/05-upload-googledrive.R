# authenticate
googledrive::drive_auth(use_oob = TRUE, cache = FALSE)

# SA: I had to use this to get going instead of drive_auth()!?
googledrive::drive_find(n_max = 5)

# check link to shared folder
# drive_ls(path = "West Coast Survey Data Join/data")
files <- googledrive::drive_ls(path = "West Coast Survey Data Join/data")

f <- c(
  "pbs_catch.rda",
  "pbs_haul.rda",
  "afsc_catch.rda",
  "afsc_haul.rda",
  "nwfsc_catch.rda",
  "nwfsc_haul.rda"
)

purrr::walk(seq_along(f), function(i) {
  googledrive::drive_upload(
    media = file.path("data", f[i]),
    name = file.path("data", f[i])
  )
})

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
