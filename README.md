
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

    ## Rows: 60,521
    ## Columns: 22
    ## $ survey_name     <chr> "eastern Bering Sea", "eastern Bering Sea", "e…
    ## $ event_id        <dbl> -23911, -23910, -23909, -23908, -23900, -23899…
    ## $ date            <chr> "2024-08-05", "2024-08-05", "2024-08-05", "202…
    ## $ pass            <int> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
    ## $ vessel          <chr> "NORTHWEST EXPLORER", "NORTHWEST EXPLORER", "N…
    ## $ lat_start       <dbl> 60.66179, 60.65791, 60.31444, 59.98789, 60.011…
    ## $ lon_start       <dbl> -178.1456, -177.5000, -177.3701, -177.2008, -1…
    ## $ lat_end         <dbl> 60.63815, 60.67198, 60.33932, 60.01284, 60.032…
    ## $ lon_end         <dbl> -178.1443, -177.5468, -177.3784, -177.1980, -1…
    ## $ depth_m         <dbl> 159, 147, 147, 137, 141, 176, 149, 119, 86, 15…
    ## $ effort          <dbl> 4.4429, 4.9899, 4.5955, 4.5007, 4.4427, 4.6980…
    ## $ effort_units    <chr> "ha", "ha", "ha", "ha", "ha", "ha", "ha", "ha"…
    ## $ performance     <chr> "0", "0", "0", "0", "0", "0", "0", "0", "0", "…
    ## $ stratum         <dbl> 61, 61, 61, 61, 61, 61, 61, 622, 621, 50, 314,…
    ## $ year            <int> 2024, 2024, 2024, 2024, 2024, 2024, 2024, 2024…
    ## $ bottom_temp_c   <dbl> 2.5, 0.8, 1.5, 1.1, 1.8, 3.6, 2.4, 4.8, 5.4, 4…
    ## $ region          <chr> "afsc", "afsc", "afsc", "afsc", "afsc", "afsc"…
    ## $ itis            <dbl> 164711, 164711, 164711, 164711, 164711, 164711…
    ## $ catch_numbers   <dbl> 4, 3, 1, 8, 7, 9, 5, 2, 2, 10, 0, 9, 6, 6, 21,…
    ## $ catch_weight    <dbl> 22.600, 11.740, 2.370, 34.920, 23.960, 35.450,…
    ## $ scientific_name <chr> "gadus macrocephalus", "gadus macrocephalus", …
    ## $ common_name     <chr> "pacific cod", "pacific cod", "pacific cod", "…

### Citations

Citing the `surveyjoin` package can be done with the DOI linked above,
though more detailed citations may be needed for specific surveys or
methodology. Some recent citations are:

<u>Aleutian Islands Bottom Trawl Survey</u>

- Von Szalay PG, Raring NW, Siple MC, Dowlin AN, Riggle BC, and Laman
  EA. 2023. Data Report: 2022 Aleutian Islands bottom trawl survey. U.S.
  Dep. Commer. DOI: 10.25923/85cy-g225.

<u>Gulf of Alaska Bottom Trawl Survey</u>

- Siple MC, von Szalay PG, Raring NW, Dowlin AN, Riggle BC. 2024. Data
  Report: 2023 Gulf of Alaska bottom trawl survey. DOI:
  10.25923/GBB1-X748.

<u>Eastern & Northern Bering Sea Crab/Groundfish Bottom Trawl
Surveys</u>

- Zacher LS, Richar JI, Fedewa EJ, Ryznar ER, Litzow MA. 2023. The 2023
  Eastern Bering Sea Continental Shelf Trawl Survey: Results for
  Commercial Crab Species. U.S. Dep. Commer, 213 p.

- Markowitz EH, Dawson EJ, Wassermann S, Anderson AB, Rohan SK,
  Charriere BK, Stevenson DE. 2024. Results of the 2023 eastern and
  northern Bering Sea continental shelf bottom trawl survey of
  groundfish and invertebrate fauna. U.S. Dep. Commer.

<u>Eastern Bering Sea Slope Bottom Trawl Survey</u>

- Hoff GR. 2016. Results of the 2016 eastern Bering Sea upper
  continental slope survey of groundfishes and invertebrate resources.
  U.S. Dep. Commer. DOI: 10.7289/V5/TM-AFSC-339.

<u>Fisheries and Oceans Canada Synoptic Bottom Trawl Surveys</u>

- Nottingham MK, Williams DC, Wyeth MR, Olsen N. 2017. *Summary of the
  West Coast Vancouver Island synoptic bottom trawl survey, May 28 –
  June 21, 2014*. DFO Can. Manuscr. Rep. Fish. Aquat. Sci. 2017/3140,
  viii + 55 p, Nanaimo.

- Sinclair A, Schnute J, Haigh R, Starr P, Stanley R, Fargo J,
  Workman G. 2003. *Feasibility of Multispecies Groundfish Bottom Trawl
  Surveys on the BC Coast. DFO Canadian Science Advisory Secretariat
  (CSAS) Research Document, 2003/049.*

- Williams DC, Nottingham MK, Olsen N, Wyeth MR. 2018a. *Summary of the
  Queen Charlotte Sound synoptic bottom trawl survey, July 6 – August 8,
  2015*. DFO Can. Manuscr. Rep. Fish. Aquat. Sci. 3136, viii + 64 p,
  Nanaimo.

- Williams DC, Nottingham MK, Olsen N, Wyeth MR. 2018b. *Summary of the
  West Coast Haida Gwaii synoptic bottom trawl survey, August 25 –
  October 2, 2014*. DFO Can. Manuscr. Rep. Fish. Aquat. Sci. 2018/3134,
  viii + 42 p, Nanaimo.

- Wyeth MR, Olsen N, Nottingham MK, Williams DC. 2018. *Summary of the
  Hecate Strait synoptic bottom trawl survey, May 26 – June 22, 2015*.
  DFO Can. Manuscr. Rep. Fish. Aquat. Sci. 2018/3126, viii + 55 p,
  Nanaimo.

<u>USA West Coast Bottom Trawl Surveys</u>

- Keller AA, Wallace JR, Methot RD. 2017. The Northwest Fisheries
  Science Center’s West Coast Groundfish Bottom Trawl Survey: history,
  design, and description. DOI: 10.7289/V5/TM-NWFSC-136.

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
| Yellowtail Rockfish   | *Sebastes flavidus*                 |
