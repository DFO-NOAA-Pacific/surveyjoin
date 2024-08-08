
# surveyjoin

<!-- badges: start -->

[![R-CMD-check](https://github.com/DFO-NOAA-Pacific/surveyjoin/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/DFO-NOAA-Pacific/surveyjoin/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

This is a repository for combining trawl survey datasets from NOAA and
Fisheries and Oceans Canada in the Northeast Pacific Ocean.

The pkdown site can be found
[here](https://dfo-noaa-pacific.github.io/surveyjoin/)

[![DOI](https://zenodo.org/badge/484561620.svg)](https://zenodo.org/doi/10.5281/zenodo.10031852)

This data includes surveys conducted by the Northwest Fisheries Science
Center (NWFSC) off the west coast of the United States, surveys
collected by Fisheries and Oceans Canada (DFO) in the waters of British
Columbia, and surveys conducted by the Alaska Fisheries Science Center
(AFSC) in Alaska.

There are 55 species included in the initial version of the package,
focusing on species that are occurring in multiple regions. The list of
species can be viewed with the `get_species()` function.

### Citations

Citing the `surveyjoin` package can be done with the DOI linked above,
though more detailed citations may be needed for specific surveys or
methodology. For citations pertaining to surveys run by the Alaska
Fisheries Science Center (AFSC), see

<https://github.com/afsc-gap-products/citations>

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
resulted in the following list of 56 species:

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
