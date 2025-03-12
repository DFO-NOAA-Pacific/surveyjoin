library(sf)
library(ggplot2)
library(dplyr)
cols <- RColorBrewer::brewer.pal(4, "Set2")

grid_sf <- gfdata::survey_blocks |>
  filter(grepl("SYN", survey_abbrev), active_block)
ggplot() +
  geom_sf(data = grid_sf, mapping = aes(colour = survey_abbrev)) +
  scale_colour_brewer(palette = "Set2")

grid_sf_list <- split(grid_sf, grid_sf$survey_abbrev)
merged_polygons <- lapply(grid_sf_list, st_union)

# with holes:
ggplot() +
  geom_sf(data = merged_polygons[[1]], fill = cols[1]) +
  geom_sf(data = merged_polygons[[2]], fill = cols[2]) +
  geom_sf(data = merged_polygons[[3]], fill = cols[3]) +
  geom_sf(data = merged_polygons[[4]], fill = cols[4])

# remove holes:
outer_polygon <- lapply(merged_polygons, sfheaders::sf_remove_holes)

# combined back together if desired:
combined_sf <- st_combine(do.call("c", outer_polygon))
ggplot() +
  geom_sf(data = combined_sf)

# but probably best to keep separate?
ggplot() +
  geom_sf(data = outer_polygon[[1]], fill = cols[1]) +
  geom_sf(data = outer_polygon[[2]], fill = cols[2]) +
  geom_sf(data = outer_polygon[[3]], fill = cols[3]) +
  geom_sf(data = outer_polygon[[4]], fill = cols[4])
