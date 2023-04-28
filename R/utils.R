save_raw_data <- function(x, name = "pbs-haul") {
  dir.create("data-raw/data", showWarnings = FALSE)
  saveRDS(x, file = paste0("data-raw/data/", name, ".rds"),
    compress = "bzip2", version = 3)
}
