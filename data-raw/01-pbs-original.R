# This version creates the original pbs-catch.rds for the non-db version

library(dplyr)

# Regenerate pbs-catch.rds from the all-species raw trawl data (data-raw/pbs-all-trawl-catches.rds)
# filtered to the species in joined_list.rds, with ITIS codes, matching the schema of
# the original pbs-catch.rds (event_id, itis, catch_numbers, catch_weight).

# 1. Read raw all-species trawl data
dat <- readRDS("data-raw/pbs-all-trawl-catches.rds")

# 2. Apply same usability filter as 01-pbs.R
dat <- filter(dat, usability_code %in% c(0, 1, 2, 6))

# 3. Build catch table with species_science_name for joining
pbs_catch_raw <- data.frame(
  event_id             = as.numeric(dat$fishing_event_id),
  catch_numbers        = dat$catch_count,
  catch_weight         = dat$catch_weight,
  species_science_name = dat$species_science_name
)

# 4. Load ITIS mapping from joined_list
joined_list <- readRDS("data-raw/joined_list.rds")

# 5. Join ITIS codes; filter to matched species only
#    (the 2 species in joined_list absent from BC simply won't appear in PBS data)
pbs_catch <- left_join(
  pbs_catch_raw,
  select(joined_list, species_science_name = scientific_name, itis),
  by = "species_science_name"
) |>
  filter(!is.na(itis)) |>
  select(event_id, itis, catch_numbers, catch_weight)

# 6. Pacific spiny dogfish ITIS fix (taxonomy change: 160617 -> 160620)
pbs_catch$itis[pbs_catch$itis == 160617] <- 160620

# 7. Remove duplicates
pbs_catch <- distinct(pbs_catch)

# 8. Diagnostics
cat("Rows:", nrow(pbs_catch), "\n")
cat("Unique ITIS:", length(unique(pbs_catch$itis)), "\n")
glimpse(pbs_catch)

# 9. Check event_id coverage against pbs-haul.rds
pbs_haul <- readRDS("data-raw/data/pbs-haul.rds")
catch_ids <- unique(pbs_catch$event_id)
haul_ids  <- unique(pbs_haul$event_id)
in_catch_not_haul <- setdiff(catch_ids, haul_ids)
in_haul_not_catch <- setdiff(haul_ids, catch_ids)
cat("\nEvent ID coverage:\n")
cat("  Haul events:                    ", length(haul_ids), "\n")
cat("  Catch events:                   ", length(catch_ids), "\n")
cat("  In catch but not haul:          ", length(in_catch_not_haul), "\n")
cat("  In haul but not catch:          ", length(in_haul_not_catch), "\n")

# 9. Save
dir.create("data-raw/data", showWarnings = FALSE)
saveRDS(pbs_catch, "data-raw/data/pbs-catch.rds")
saveRDS(pbs_catch, "~/src/surveyjoin-data/pbs-catch.rds")
