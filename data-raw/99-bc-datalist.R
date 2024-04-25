library(dplyr)

if (Sys.info()[["user"]] == "seananderson") {
  d <- readRDS("~/Downloads/pbs-survey-2024-04-24.rds")

  # Come up with some threshold (e.g. 5% of tows) to come up with initial species
  # lists for each region
  # try 5%
  # try 20%??

  spp1 <- group_by(d, species_science_name) |>
    summarise(prop_positive = mean(catch_weight > 0)) |>
    filter(prop_positive > 0.05) |>
    pull(species_science_name)

  spp2 <- group_by(d, species_science_name) |>
    summarise(prop_positive = mean(catch_weight > 0)) |>
    filter(prop_positive > 0.2) |>
    pull(species_science_name)

  # Sum up total biomass from filtered dataset and focus on species whose average
  # annual proportion has to be greater than some threshold (e.g. 0.25%) also try
  # 0.1%?

  temp <- filter(d, species_science_name %in% spp1) |>
    group_by(year, species_science_name) |>
    summarise(catch_weight = sum(catch_weight)) |>
    group_by(year) |>
    mutate(total_catch_weight = sum(catch_weight)) |>
    ungroup() |>
    mutate(prop_catch_weight = catch_weight / total_catch_weight) |>
    group_by(species_science_name) |>
    summarise(mean_catch_proportion = mean(prop_catch_weight))

  spp3 <- temp |> filter(mean_catch_proportion > 0.25 * 0.01) |>
    pull(species_science_name)
  spp4 <- temp |> filter(mean_catch_proportion > 0.1 * 0.01) |>
    pull(species_science_name)

  spp1
  spp2
  spp3
  spp4

  bc <- list("five" = spp1, "20" = spp2, "five_and_0.25" = spp3, "five_and_0.1" = spp4)
  saveRDS(bc, file = "data-raw/bc-spp-list.rds")
}
