ssids <- c(1, 3, 4, 16)

dir.create("data_raw/pbs-cache", showWarnings = FALSE)
spp <- gfsynopsis::get_spp_names()
dat <- purrr::map(seq_len(nrow(spp)), function(i) {
  s <- spp$spp_w_hyphens[i]
  cat(s, "\n")
  f <- paste0("data_raw/pbs-cache/", s, ".rds")
  if (file.exists(f)) {
    readRDS(f)
  } else {
    d <- gfdata::get_survey_sets(species = spp$species_code[i], ssid = ssids)
    saveRDS(d, file = f)
    d
  }
})
