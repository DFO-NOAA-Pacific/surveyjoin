library(downloader)
# from indexwc package

path <- fs::path(tempdir(), "california_current_grid.rda")
url <- "https://github.com/James-Thorson-NOAA/FishStatsUtils/raw/main/data/california_current_grid.rda"

downloader::download(
  url = url,
  destfile = path
)

load(path)
unlink(path)

california_current_grid <- california_current_grid |>
  dplyr::rowwise() |>
  dplyr::mutate(
    pass_scaled = 0,
    vessel_year = 0,
    region = 0,
    split_mendocino = dplyr::case_when(Lat > 40.1666667 ~ "N", .default = "S"),
    split_conception = dplyr::case_when(Lat > 34.45 ~ "N", .default = "S"),
    split_monterey = dplyr::case_when(Lat > 36.0 ~ "N", .default = "S"),
    split_state = dplyr::case_when(Lat > 46.25 ~ "W", Lat < 42.0 ~ "C", .default = "O"),
    propInTriennial = ifelse(Lat < 34.5, 0, propInTriennial),
    depth = Depth_km * -1000,
    dplyr::across(
      .cols = dplyr::matches("propIn[WTS]"),
      .fns = ~ ifelse(Ngdc_m > -35, 0, .)
    ),
    dplyr::across(
      .cols = dplyr::matches("propIn[WTS]"),
      .fns = ~ 4 * min(.),
      .names = "{gsub('propIn', 'area_km2_', {col})}"
    )
  )

utm_zone_10 <- 32610
california_current_grid <- suppressWarnings(sdmTMB::add_utm_columns(
  california_current_grid,
  utm_crs = utm_zone_10,
  ll_names = c("Lon", "Lat"),
  utm_names = c("x", "y")
)) |>
  dplyr::rename(
    longitude = "Lon",
    latitude = "Lat"
  )


grid_df <- dplyr::rename(california_current_grid,
                         lon = longitude, lat = latitude,
                                         depth_m = depth) |>
  dplyr::mutate(survey_domain_year = 2023) |> as.data.frame()

grid_WCGBTS <- dplyr::rename(grid_df,
                             area = area_km2_WCGBTS) |>
  dplyr::mutate(survey = "NWFSC.Combo") |>
  dplyr::select(-area_km2_Triennial)
grid_tri <- dplyr::rename(grid_df,
                            area = area_km2_Triennial) |>
  dplyr::mutate(survey = "Triennial")|>
  dplyr::select(-area_km2_WCGBTS)

nwfsc_grid <- rbind(grid_WCGBTS, grid_tri) |>
  dplyr::select(lon, lat, area, depth_m, survey, survey_domain_year)
nwfsc_grid$area <- nwfsc_grid$area * 100
# convert to ha

usethis::use_data(nwfsc_grid, overwrite = TRUE)
