# Make map of all surveys in surveyjoin, starting with Markowitz' AK code ----

library(ggplot2)
library(viridis)
library(sf)
# devtools::install_github("afsc-gap-products/akgfmaps", build_vignettes = TRUE)
library(akgfmaps)

crs_out <- "EPSG:3338"

world_coordinates <- maps::map("world", plot = FALSE, fill = TRUE) %>%
  sf::st_as_sf() %>%
  # sf::st_union() %>%
  sf::st_transform(crs = crs_out) %>%
  dplyr::filter(ID %in% c("USA", "Russia", "Canada", "Mexico")) %>%
  dplyr::mutate(ID = ifelse(ID == "USA", "Alaska", ID))

place_labels <- data.frame(
  type = c("mainland", "mainland", "mainland", "mainland", "survey",
           "peninsula", "survey", "survey", "survey", "survey", "survey"),
  lab = c("Alaska", "Russia", "Canada", "USA", "West Coast",
          "Alaska Peninsula", "Aleutian Islands", "Gulf of Alaska",
          "Bering\nSea\nSlope", "Eastern\nBering Sea", "Northern\nBering Sea"),
  angle = c(0, 0, 0, 0, -45, 45, 0, 30, 0, 0, 0),
  lat = c(63, 62.798276, 58, 42, 40, 56.352495, 53.25, 54.720787,
          57, 57.456912, 62.25),
  lon = c(-154, 173.205231, -122, -120, -125.2,
          -159.029430, -173, -154.794131, -176, -162, -170.5)) %>%
  dplyr::filter(type != "peninsula") %>%
  sf::st_as_sf(coords = c("lon", "lat"),
               crs = "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0") %>%
  sf::st_transform(crs = crs_out)

# AK surveys
shp_ebs <- akgfmaps::get_base_layers(select.region = "bs.south", set.crs = "auto")
shp_nbs <- akgfmaps::get_base_layers(select.region = "bs.north", set.crs = "auto")
shp_ai <- akgfmaps::get_base_layers(select.region = "ai", set.crs = "auto")
shp_ai$survey.strata$Stratum <- shp_ai$survey.strata$STRATUM
shp_goa <- akgfmaps::get_base_layers(select.region = "goa", set.crs = "auto")
shp_goa$survey.strata$Stratum <- shp_goa$survey.strata$STRATUM
shp_bss <- akgfmaps::get_base_layers(select.region = "ebs.slope", set.crs = "auto")

# WC surveys
shp_wc <- st_read("inst/extdata/WCGBTS_Strata_Albers_NAD83.shp") %>%
  st_union() %>% # dissolve inner stratum boundaries
  st_sf()

# BC surveys

## Pull together all areas -----------------------------------------------------
shp_all <- shp <- dplyr::bind_rows(list(
  shp_ebs$survey.area %>%
    sf::st_transform(crs = crs_out) %>%
    dplyr::mutate(SURVEY = "EBS"),
  shp_nbs$survey.area  %>%
    sf::st_transform(crs = crs_out) %>%
    dplyr::mutate(SURVEY = "NBS"),
  shp_ai$survey.area %>%
    sf::st_transform(crs = crs_out) %>%
    dplyr::mutate(SURVEY = "AI"),
  shp_goa$survey.area %>%
    sf::st_transform(crs = crs_out) %>%
    dplyr::mutate(SURVEY = "GOA"),
  shp_bss$survey.area %>%
    sf::st_transform(crs = crs_out) %>%
    dplyr::mutate(SURVEY = "BSS"),
  shp_wc %>%
    sf::st_transform(crs = crs_out) %>%
    dplyr::mutate(SURVEY = "WC"))) %>%
  dplyr::select(Survey = SURVEY, geometry)

# ## Pull together all stations ---------------------------------------------------
# survey.grid <- dplyr::bind_rows(list(
#   shp_ebs$survey.grid %>%
#     sf::st_transform(crs = crs_out) %>%
#     dplyr::mutate(SRVY = "EBS",
#                   station = STATIONID),
#   shp_nbs$survey.grid  %>%
#     sf::st_transform(crs = crs_out) %>%
#     dplyr::mutate(SRVY = "NBS",
#                   station = STATIONID),
#   shp_ai$survey.grid %>%
#     sf::st_transform(crs = crs_out) %>%
#     dplyr::mutate(SRVY = "AI",
#                   survey_definition_id = 52,
#                   station = ID,
#                   stratum = STRATUM),
#   shp_goa$survey.grid %>%
#     sf::st_transform(crs = crs_out) %>%
#     dplyr::mutate(SRVY = "GOA",
#                   survey_definition_id = 47,
#                   station = ID,
#                   stratum = STRATUM))) %>%
#   dplyr::select(survey_definition_id, SRVY, stratum, station, geometry)
#
# ## Pull together all strata ---------------------------------------------------
# survey.strata <- dplyr::bind_rows(list(
#   shp_ebs$survey.strata %>%
#     sf::st_transform(crs = crs_out) %>%
#     dplyr::mutate(SRVY = "EBS",
#                   survey_definition_id = 98,
#                   stratum = as.numeric(Stratum)) %>%
#     dplyr::select(-Stratum),
#   shp_nbs$survey.strata  %>%
#     sf::st_transform(crs = crs_out) %>%
#     dplyr::mutate(SRVY = "NBS",
#                   survey_definition_id = 143,
#                   stratum = as.numeric(Stratum)) %>%
#     dplyr::select(-Stratum),
#   shp_ai$survey.strata %>%
#     sf::st_transform(crs = crs_out) %>%
#     dplyr::mutate(SRVY = "AI",
#                   survey_definition_id = 52,
#                   stratum = as.numeric(STRATUM)) %>%
#     dplyr::select(-STRATUM),
#   shp_goa$survey.strata %>%
#     sf::st_transform(crs = crs_out) %>%
#     dplyr::mutate(SRVY = "GOA",
#                   survey_definition_id = 47,
#                   stratum = as.numeric(STRATUM)) %>%
#     dplyr::select(-STRATUM, -Stratum),
#   shp_bss$survey.strata %>%
#     sf::st_transform(crs = crs_out) %>%
#     dplyr::mutate(SRVY = "BSS",
#                   survey_definition_id = 78,
#                   stratum = as.numeric(STRATUM)) %>%
#     dplyr::select(-STRATUM))) %>%
#   dplyr::select(SRVY, survey_definition_id, area_id = stratum, geometry)

## Plot ------------------------------------------------------------------------
p <- ggplot2::ggplot() +
  ggplot2::geom_sf(data = world_coordinates,
                   fill = "grey10",
                   color = "grey20")  +
  # Survey area shapefile
  ggplot2::geom_sf(data = shp_all,
                   mapping = aes(fill = Survey),
                   color = "grey50",
                   alpha = 0.5,
                   show.legend = FALSE) +
  ggplot2::scale_fill_manual(
    values =  c("gray90",
                viridis::viridis(
                  option = "mako",
                  # direction = -1,
                  n = nrow(shp_all),
                  begin = 0.20,
                  end = 0.80))) +
  # Manage Axis extents (limits) and breaks
  ggplot2::scale_x_continuous(name = "Longitude °W",
                              breaks = c(170, seq(-180, -120, 10))) +
  ggplot2::scale_y_continuous(name = "Latitude °N",
                              breaks = seq(30, 70, 10)) +
  ggplot2::coord_sf(xlim = sf::st_bbox(shp_all)[c(1,3)],
                    ylim = sf::st_bbox(shp_all)[c(2,4)]) +
  ggplot2::geom_sf_text(
    data = place_labels %>% dplyr::filter(type == "mainland"),
    mapping = aes(label = lab, angle = angle),
    color = "grey60",
    size = 3,
    show.legend = FALSE) +
  ggplot2::geom_sf_text(
    data = place_labels %>% dplyr::filter(type == "survey"),
    mapping = aes(label = lab, angle = angle),
    color = "black",
    fontface = "bold",
    size = 2,
    show.legend = FALSE) +
  ggplot2::geom_sf_text(
    data = place_labels %>% dplyr::filter(!(type %in% c("mainland", "survey"))),
    mapping = aes(label = lab, angle = angle),
    color = "grey10",
    fontface = "italic",
    size = 2,
    show.legend = FALSE) +
  ggplot2::theme_bw() +
  ggplot2::theme(
    plot.margin=unit(c(0,0,0,0), "cm"),
    strip.background = element_rect(fill = "transparent", colour = "white"),
    strip.text = element_text(face = "bold"), # , family = font0
    panel.border = element_rect(colour = "grey20", linewidth = .25, fill = NA),
    panel.background = element_rect(fill = "white"),
    panel.grid = element_line(colour="grey80", linewidth=0.5),
    plot.title = element_text(face = "bold"), # , size = 12, family = font0
    axis.text = element_text(face = "bold"), # , size = 12 , family = font0
  ) +
  ggplot2::ggtitle(label = paste0("Bottom Trawl Survey Coverage"))
p

ggsave(filename = paste0("survey_coverage_map.png"),
       plot = p,
       path = here::here("img"),
       width = 7,
       height = 3)
