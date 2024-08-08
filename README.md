
# surveyjoin

<!-- badges: start -->

[![R-CMD-check](https://github.com/DFO-NOAA-Pacific/surveyjoin/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/DFO-NOAA-Pacific/surveyjoin/actions/workflows/R-CMD-check.yaml)
[![DOI](https://zenodo.org/badge/484561620.svg)](https://zenodo.org/doi/10.5281/zenodo.10031852)
<!-- badges: end -->

This is a repository for combining trawl survey datasets from NOAA and
Fisheries and Oceans Canada in the Northeast Pacific Ocean.

A pkgdown site is available
[here](https://dfo-noaa-pacific.github.io/surveyjoin/).

This data includes surveys conducted by the Northwest Fisheries Science
Center (NWFSC) off the west coast of the United States, surveys
collected by Fisheries and Oceans Canada (DFO) in the waters of British
Columbia, and surveys conducted by the Alaska Fisheries Science Center
(AFSC) in Alaska.

There are 55 species included in the initial version of the package,
focusing on species that are occurring in multiple regions.

### Installing

``` r
# install.packages("pak")
pak::pkg_install("DFO-NOAA-Pacific/surveyjoin")
```

### Basic use

``` r
library(surveyjoin)
```

On first use, download the data and load it into a local SQL database:

``` r
cache_data()
load_sql_data()
```

Find available species:

``` r
get_species()
```

    ## # A tibble: 55 × 3
    ##    common_name         scientific_name        itis
    ##    <chr>               <chr>                 <dbl>
    ##  1 aleutian skate      bathyraja aleutica   160935
    ##  2 arrowtooth flounder atheresthes stomias  172862
    ##  3 big skate           raja binoculata      160848
    ##  4 bigfin eelpout      lycodes cortezianus  550588
    ##  5 bigmouth sculpin    hemitripterus bolini 167287
    ##  6 black eelpout       lycodes diapterus    165261
    ##  7 blackbelly eelpout  lycodes pacificus    630999
    ##  8 bocaccio            sebastes paucispinis 166733
    ##  9 canary rockfish     sebastes pinniger    166734
    ## 10 capelin             mallotus villosus    162035
    ## # ℹ 45 more rows

Load data for a species:

``` r
d <- get_data("pacific cod")
```

``` r
dplyr::glimpse(d, width = 72)
```

    ## Rows: 58,889
    ## Columns: 21
    ## $ survey_name     <chr> "Aleutian Islands", "Aleutian Islands", "Aleut…
    ## $ event_id        <dbl> -21893, -21764, -21455, -18280, -18259, -18094…
    ## $ date            <chr> "2022-08-07", "2022-07-28", "2022-07-03", "201…
    ## $ pass            <int> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
    ## $ vessel          <chr> "OCEAN EXPLORER", "OCEAN EXPLORER", "ALASKA PR…
    ## $ lat_start       <dbl> 52.01721, 53.11242, 51.96523, 52.67577, 52.507…
    ## $ lon_start       <dbl> -175.8889, -170.9027, -172.6282, -172.7522, -1…
    ## $ lat_end         <dbl> 52.00690, 53.10904, 51.96874, 52.67061, 52.516…
    ## $ lon_end         <dbl> -175.9017, -170.9244, -172.6096, -172.7648, -1…
    ## $ depth_m         <dbl> 184, 98, 216, 184, 167, 133, 225, 80, 186, 111…
    ## $ effort          <dbl> 2.3745, 2.5268, 2.6409, 1.7392, 1.8012, 1.8531…
    ## $ effort_units    <chr> "ha", "ha", "ha", "ha", "ha", "ha", "ha", "ha"…
    ## $ performance     <chr> "0", "0", "5", "4", "4", "0", "4", "0", "0", "…
    ## $ bottom_temp_c   <dbl> 4.6, 4.9, 4.5, 4.5, 4.6, 4.6, 4.3, 5.5, 4.8, 4…
    ## $ region          <chr> "afsc", "afsc", "afsc", "afsc", "afsc", "afsc"…
    ## $ year            <int> 2022, 2022, 2022, 2018, 2018, 2018, 2018, 2018…
    ## $ itis            <dbl> 164711, 164711, 164711, 164711, 164711, 164711…
    ## $ catch_numbers   <dbl> 0, 0, 0, 7, 11, 4, 11, 30, 12, 56, 2, 0, 0, 3,…
    ## $ catch_weight    <dbl> 0.00, 0.00, 0.00, 24.65, 31.22, 14.61, 34.22, …
    ## $ scientific_name <chr> "gadus macrocephalus", "gadus macrocephalus", …
    ## $ common_name     <chr> "pacific cod", "pacific cod", "pacific cod", "…

### Citations

Citing the `surveyjoin` package can be done with the DOI linked above,
though more detailed citations may be needed for specific surveys or
methodology. For citations pertaining to surveys run by the Alaska
Fisheries Science Center (AFSC), 
see <https://github.com/afsc-gap-products/citations>. 
Metadata for surveys conducted by the AFSC can be found at 
<https://afsc-gap-products.github.io/gap_products>.

Background and additional citations on surveys run by the Northwest
Fisheries Science Center (NWFSC) can be found in [Keller et
al. 2017](https://repository.library.noaa.gov/view/noaa/14179/noaa_14179_DS1.pdf). 

### What species are included?

We first divided the joined datasets into 4 major areas: Eastern Bering
Sea, Gulf of Alaska, British Columbia, and west coast of California /
Oregon / Washington states.

Within each region, we identified the species that occurred in at least
5% of all tows (resulting in 4 lists, 1 for each region). Because our
interests are in cross-regional work, we identified species meeting our
occurrence threshold that also occurred in 2 or more regions. This
resulted in the following list of 55 species:

| Common name           | Scientific name                     |
|:----------------------|:------------------------------------|
| Aleutian Skate        | *Bathyraja aleutica*                |
| Arrowtooth Flounder   | *Atheresthes stomias*               |
| Big Skate             | *Raja binoculata*                   |
| Bigfin Eelpout        | *Lycodes cortezianus*               |
| Bigmouth Sculpin      | *Hemitripterus bolini*              |
| Black Eelpout         | *Lycodes diapterus*                 |
| Blackbelly Eelpout    | *Lycodes pacificus*                 |
| Bocaccio              | *Sebastes paucispinis*              |
| Canary Rockfish       | *Sebastes pinniger*                 |
| Capelin               | *Mallotus villosus*                 |
| Curlfin Sole          | *Pleuronichthys decurrens*          |
| Darkblotched Rockfish | *Sebastes crameri*                  |
| Darkfin Sculpin       | *Malacocottus zonurus*              |
| Dover Sole            | *Microstomus pacificus*             |
| English Sole          | *Parophrys vetulus*                 |
| Eulachon              | *Thaleichthys pacificus*            |
| Flathead Sole         | *Hippoglossoides elassodon*         |
| Giant Grenadier       | *Albatrossia pectoralis*            |
| Great Sculpin         | *Myoxocephalus polyacanthocephalus* |
| Greenstriped Rockfish | *Sebastes elongatus*                |
| Harlequin Rockfish    | *Sebastes variegatus*               |
| Kamchatka Flounder    | *Atheresthes evermanni*             |
| Lingcod               | *Ophiodon elongatus*                |
| Longnose Skate        | *Raja rhina*                        |
| North Pacific Hake    | *Merluccius productus*              |
| Northern Rock Sole    | *Lepidopsetta polyxystra*           |
| Pacific Cod           | *Gadus macrocephalus*               |
| Pacific Halibut       | *Hippoglossus stenolepis*           |
| Pacific Herring       | *Clupea pallasii*                   |
| Pacific Ocean Perch   | *Sebastes alutus*                   |
| Pacific Sanddab       | *Citharichthys sordidus*            |
| Pacific Spiny Dogfish | *Squalus suckleyi*                  |
| Petrale Sole          | *Eopsetta jordani*                  |
| Redbanded Rockfish    | *Sebastes babcocki*                 |
| Rex Sole              | *Glyptocephalus zachirus*           |
| Rock Sole             | *Lepidopsetta bilineata*            |
| Rosethorn Rockfish    | *Sebastes helvomaculatus*           |
| Sablefish             | *Anoplopoma fimbria*                |
| Sandpaper Skate       | *Bathyraja interrupta*              |
| Sawback Poacher       | *Sarritor frenatus*                 |
| Searcher              | *Bathymaster signatus*              |
| Sharpchin Rockfish    | *Sebastes zacentrus*                |
| Shortfin Eelpout      | *Lycodes brevipes*                  |
| Shortspine Thornyhead | *Sebastolobus alascanus*            |
| Slender Sole          | *Lyopsetta exilis*                  |
| Spinyhead Sculpin     | *Dasycottus setiger*                |
| Splitnose Rockfish    | *Sebastes diploproa*                |
| Spotted Ratfish       | *Hydrolagus colliei*                |
| Sturgeon Poacher      | *Podothecus accipenserinus*         |
| Threadfin Sculpin     | *Icelinus filamentosus*             |
| Walleye Pollock       | *Gadus chalcogrammus*               |
| Wattled Eelpout       | *Lycodes palearis*                  |
| Widow Rockfish        | *Sebastes entomelas*                |
| Yellow Irish Lord     | *Hemilepidotus jordani*             |
| Yellowtain Rockfish   | *Sebastes flavidus*                 |
