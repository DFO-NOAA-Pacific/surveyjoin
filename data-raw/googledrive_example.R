library(googledrive)

# authenticate
drive_auth(use_oob = TRUE, cache = FALSE)


# check link to shared folder
# drive_ls(path = "West Coast Survey Data Join/data")
files <- drive_ls(path = "West Coast Survey Data Join/data")

# examples
drive_download(file = "West Coast Survey Data Join/data/afsc.rda",
                       path = "data-raw/afsc.rda")

drive_download(file = "West Coast Survey Data Join/data/nwfsc_haul.rda",
               path="data-raw/nwfsc_haul.rda",overwrite = TRUE)

drive_download(file = "West Coast Survey Data Join/data/nwfsc_catch.rda",
               path="data-raw/nwfsc_catch.rda",overwrite = TRUE)
