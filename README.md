
# surveyjoin package

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
resulted in the following list of 55 species:

| common_name           | scientific_name                   |   itis |
|:----------------------|:----------------------------------|-------:|
| aleutian skate        | bathyraja aleutica                | 160935 |
| arrowtooth flounder   | atheresthes stomias               | 172862 |
| bigfin eelpout        | lycodes cortezianus               | 550588 |
| bigmouth sculpin      | hemitripterus bolini              | 167287 |
| blackbelly eelpout    | lycodes pacificus                 | 630999 |
| bocaccio              | sebastes paucispinis              | 166733 |
| canary rockfish       | sebastes pinniger                 | 166734 |
| capelin               | mallotus villosus                 | 162035 |
| curlfin sole          | pleuronichthys decurrens          | 172924 |
| darkblotched rockfish | sebastes crameri                  | 166715 |
| darkfin sculpin       | malacocottus zonurus              | 167305 |
| dover sole            | microstomus pacificus             | 172887 |
| english sole          | parophrys vetulus                 | 172921 |
| eulachon              | thaleichthys pacificus            | 162051 |
| flathead sole         | hippoglossoides elassodon         | 172875 |
| giant grenadier       | albatrossia pectoralis            | 165427 |
| great sculpin         | myoxocephalus polyacanthocephalus | 167315 |
| greenstriped rockfish | sebastes elongatus                | 166717 |
| harlequin rockfish    | sebastes variegatus               | 166742 |
| kamchatka flounder    | atheresthes evermanni             | 172861 |
| lingcod               | ophiodon elongatus                | 167116 |
| north pacific hake    | merluccius productus              | 164792 |
| northern rock sole    | lepidopsetta polyxystra           | 616392 |
| pacific cod           | gadus macrocephalus               | 164711 |
| pacific halibut       | hippoglossus stenolepis           | 172932 |
| pacific herring       | clupea pallasii                   | 551209 |
| pacific ocean perch   | sebastes alutus                   | 166707 |
| pacific sanddab       | citharichthys sordidus            | 172716 |
| petrale sole          | eopsetta jordani                  | 172868 |
| puget sound dogfish   | squalus suckleyi                  | 160620 |
| redbanded rockfish    | sebastes babcocki                 | 166710 |
| rex sole              | glyptocephalus zachirus           | 172978 |
| rock sole             | lepidopsetta bilineata            | 172917 |
| rosethorn rockfish    | sebastes helvomaculatus           | 166723 |
| sablefish             | anoplopoma fimbria                | 167123 |
| sandpaper skate       | bathyraja interrupta              | 160937 |
| searcher              | bathymaster signatus              | 170949 |
| sharpchin rockfish    | sebastes zacentrus                | 166744 |
| shortfin eelpout      | lycodes brevipes                  | 165258 |
| shortspine thornyhead | sebastolobus alascanus            | 166783 |
| slender sole          | lyopsetta exilis                  | 172871 |
| spinyhead sculpin     | dasycottus setiger                | 167265 |
| splitnose rockfish    | sebastes diploproa                | 166716 |
| spotted ratfish       | hydrolagus colliei                | 161015 |
| sturgeon poacher      | podothecus accipenserinus         | 644358 |
| threadfin sculpin     | icelinus filamentosus             | 167293 |
| walleye pollock       | gadus chalcogrammus               | 934083 |
| wattled eelpout       | lycodes palearis                  | 165265 |
| widow rockfish        | sebastes entomelas                | 166719 |
| yellow irish lord     | hemilepidotus jordani             | 167280 |
| yellowtain rockfish   | sebastes flavidus                 | 166720 |
