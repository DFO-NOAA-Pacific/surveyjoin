library(dplyr)
remotes::install_github("nwfsc-assess/nwfscSurvey")
library(nwfscSurvey)
remotes::install_github("pbs-assess/gfplot")
library(gfplot)
library(sf)

######### NWFSC grid
data("availablecells")
nwfsc_grid <- dplyr::rename(availablecells,
                                id = Cent.ID,
                                ha = Hectares,
                                latitude_dd = Cent.Lat,
                                longitude_dd = Cent.Long) %>%
  dplyr::select(id, ha, latitude_dd, longitude_dd)
# only include km2, for compatibility with DFO-synopsis
nwfsc_grid <- dplyr::mutate(nwfsc_grid,
                            area_km2 = 0.01*ha,
                            survey = "WCBTS",
                            survey_domain_year = as.numeric(format(Sys.Date(), "%Y")),
                            depth = NA) %>%
  dplyr::select(-ha, -id)

usethis::use_data(nwfsc_grid, overwrite = TRUE)

######### DFO grid
data("synoptic_grid")

# Create an sf object
synoptic_grid$X <- synoptic_grid$X * 1000
synoptic_grid$Y <- synoptic_grid$Y * 1000
coordinates <- st_as_sf(synoptic_grid, coords = c("X", "Y"), crs = 32609)
# Transform to WGS 84
coordinates_dd <- st_transform(coordinates, crs = 4326)
new_coords <- st_coordinates(coordinates_dd)
synoptic_grid$longitude_dd <- new_coords[,1]
synoptic_grid$latitude_dd <- new_coords[,2]

dfo_synoptic_grid <- dplyr::select(synoptic_grid, survey, latitude_dd,
                               longitude_dd, survey, survey_domain_year,
                               cell_area) %>%
  dplyr::rename(area_km2 = cell_area)

usethis::use_data(dfo_synoptic_grid, overwrite = TRUE)

###

# Get the content from the URL
library(httr)

url <- "https://raw.githubusercontent.com/afsc-gap-products/model-based-indices/main/extrapolation_grids/eastern_bering_sea_grid.rda"

local_file_path <- "temp.rda"
download.file(url, destfile = local_file_path, mode = "wb")# Download the file
load(local_file_path) # Load the .rda file into R environment

afsc_ebs_grid <- as.data.frame(eastern_bering_sea_grid) %>%
  dplyr::rename(latitude_dd = Lat, longitude_dd = Lon, area_km2 = Area_in_survey_km2) %>%
  dplyr::select(latitude_dd, longitude_dd, area_km2) %>%
  dplyr::mutate(survey = "Eastern Bering Sea Crab/Groundfish Bottom Trawl Survey",
                survey_domain_year = as.numeric(format(Sys.Date(), "%Y")),
                depth=NA)
#usethis::use_data(afsc_ebs_grid, overwrite = TRUE)
unlink(local_file_path)# Clean up: remove the downloaded file

url <- "https://raw.githubusercontent.com/afsc-gap-products/model-based-indices/main/extrapolation_grids/bering_sea_slope_grid.rda"

local_file_path <- "temp.rda"
download.file(url, destfile = local_file_path, mode = "wb")# Download the file
load(local_file_path) # Load the .rda file into R environment

afsc_slope_grid <- as.data.frame(bering_sea_slope_grid) %>%
  dplyr::rename(latitude_dd = Lat, longitude_dd = Lon, area_km2 = Area_in_survey_km2) %>%
  dplyr::select(latitude_dd, longitude_dd, area_km2) %>%
  dplyr::mutate(survey = "Eastern Bering Sea Slope Bottom Trawl Survey",
                survey_domain_year = as.numeric(format(Sys.Date(), "%Y")),
                depth=NA)
#usethis::use_data(afsc_ebs_grid, overwrite = TRUE)
unlink(local_file_path)# Clean up: remove the downloaded file

url <- "https://raw.githubusercontent.com/afsc-gap-products/model-based-indices/main/extrapolation_grids/gulf_of_alaska_grid.rda"

local_file_path <- "temp.rda"
download.file(url, destfile = local_file_path, mode = "wb")# Download the file
load(local_file_path) # Load the .rda file into R environment

afsc_goa_grid <- as.data.frame(gulf_of_alaska_grid) %>%
  dplyr::rename(latitude_dd = Lat, longitude_dd = Lon, area_km2 = Area_in_survey_km2) %>%
  dplyr::select(latitude_dd, longitude_dd, area_km2) %>%
  dplyr::mutate(survey = "Gulf of Alaska Bottom Trawl Survey",
                survey_domain_year = as.numeric(format(Sys.Date(), "%Y")),
                depth=NA)
#usethis::use_data(afsc_goa_grid, overwrite = TRUE)
unlink(local_file_path)# Clean up: remove the downloaded file


url <- "https://raw.githubusercontent.com/afsc-gap-products/model-based-indices/main/extrapolation_grids/aleutian_islands_grid.rda"

local_file_path <- "temp.rda"
download.file(url, destfile = local_file_path, mode = "wb")# Download the file
load(local_file_path) # Load the .rda file into R environment

afsc_ai_grid <- as.data.frame(aleutian_islands_grid) %>%
  dplyr::rename(latitude_dd = Lat, longitude_dd = Lon, area_km2 = Area_km2) %>%
  dplyr::select(latitude_dd, longitude_dd, area_km2) %>%
  dplyr::mutate(survey = "Aleutian Islands Bottom Trawl Survey",
                survey_domain_year = as.numeric(format(Sys.Date(), "%Y")),
                depth=NA)
#usethis::use_data(afsc_ai_grid, overwrite = TRUE)
unlink(local_file_path)# Clean up: remove the downloaded file


url <- "https://raw.githubusercontent.com/afsc-gap-products/model-based-indices/main/extrapolation_grids/northern_bering_sea_grid.rda"

local_file_path <- "temp.rda"
download.file(url, destfile = local_file_path, mode = "wb")# Download the file
load(local_file_path) # Load the .rda file into R environment

afsc_nbs_grid <- as.data.frame(northern_bering_sea_grid) %>%
  dplyr::rename(latitude_dd = Lat, longitude_dd = Lon, area_km2 = Area_in_survey_km2) %>%
  dplyr::select(latitude_dd, longitude_dd, area_km2) %>%
  dplyr::mutate(survey = "Northern Bering Sea Crab/Groundfish Survey - Eastern Bering Sea Shelf Survey Extension",
                survey_domain_year = as.numeric(format(Sys.Date(), "%Y")),
                depth=NA)
#usethis::use_data(afsc_nbs_grid, overwrite = TRUE)
unlink(local_file_path)# Clean up: remove the downloaded file

# Combine all AFSC grids into a single DF
afsc_grid <- rbind(afsc_nbs_grid, afsc_ebs_grid, afsc_slope_grid,
                   afsc_goa_grid, afsc_ai_grid)
usethis::use_data(afsc_grid, overwrite = TRUE)

# url <- "https://raw.githubusercontent.com/afsc-gap-products/model-based-indices/main/extrapolation_grids/chukchi_sea_grid.rda"
#
# local_file_path <- "temp.rda"
# download.file(url, destfile = local_file_path, mode = "wb")# Download the file
# load(local_file_path) # Load the .rda file into R environment
#
# afsc_chukchi_grid <- as.data.frame(chukchi_sea_grid) %>%
#   dplyr::rename(latitude_dd = Lat, longitude_dd = Lon, area_km2 = Area_in_survey_km2) %>%
#   dplyr::select(latitude_dd, longitude_dd, area_km2) %>%
#   dplyr::mutate(survey = "Chukchi",
#                 survey_domain_year = as.numeric(format(Sys.Date(), "%Y")),
#                 depth=NA)
# usethis::use_data(afsc_chukchi_grid, overwrite = TRUE)
# unlink(local_file_path)# Clean up: remove the downloaded file
