ssids <- c(1, 3, 4, 16)

fold <- "../gfsynopsis-2021/report/data-cache-april-2022/"
if (file.exists(fold)) {
  f <- list.files(fold, include.dirs = FALSE)
  f <- f[!grepl("iphc", f)]
  f <- f[!grepl("cpue", f)]
  dat <- list()
  for (i in seq_along(f)) {
    cat(f[i], "\n")
    dat[[i]] <- readRDS(paste0(fold, f[i]))$survey_sets
    dat[[i]] <- dplyr::filter(dat[[i]], survey_series_id.x %in% ssids)
  }
} else {
  spp <- gfsynopsis::get_spp_names()
  dat <- purrr::map(spp$species_code, function(.x) {
    gfdata::get_survey_sets(species = .x, ssid = ssids)
  })
}
