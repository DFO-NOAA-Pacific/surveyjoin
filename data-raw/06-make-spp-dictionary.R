make_itis_spp_table <- function() {
  # db <- surv_db()
  # haul <- dplyr::tbl(db, "haul")
  # catch <- dplyr::tbl(db, "catch")

  catch <- readRDS("data-raw/data/afsc-catch.rds") |>
    bind_rows(readRDS("data-raw/data/nwfsc-catch.rds")) |>
    bind_rows(readRDS("data-raw/data/pbs-catch.rds"))

  itis <- catch |>
    select(itis) |>
    distinct() |>
    collect(n = Inf) |>
    pull(itis) |>
    sort()
  spp <- taxize::id2name(itis, db = "itis")

  sn <- purrr::map_chr(spp, ~ .[["name"]])
  lu <- data.frame(scientific_name = unname(sn), itis = names(sn), stringsAsFactors = FALSE)
  common <- taxize::sci2comm(lu$scientific_name, db = "ncbi")

  com <- purrr::map_chr(common, ~ .[1])
  lu$common_name <- tolower(unname(com))

  missing <- filter(lu, is.na(common_name))
  common2 <- taxize::sci2comm(missing$scientific_name, db = "itis")
  com2 <- purrr::map_chr(common2, ~.[1])
  tolower(unname(com2))
  lu2 <- data.frame(scientific_name = names(com2), common_name = tolower(unname(com2)))
  lu2 <- left_join(lu2, select(lu, scientific_name, itis))

  lu <- filter(lu, !is.na(common_name))
  lu <- bind_rows(lu, lu2)
  lu <- filter(lu, !is.na(common_name))

  lu$itis <- as.integer(lu$itis)
  lu$common_name <- tolower(lu$common_name)
  lu$scientific_name <- tolower(lu$scientific_name)
  spp_dictionary <- lu
  usethis::use_data(spp_dictionary, overwrite = TRUE)
}

# slow!!
make_itis_spp_table()