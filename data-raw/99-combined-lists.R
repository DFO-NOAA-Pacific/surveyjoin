bc <- readRDS("data-raw/bc-spp-list.rds")
nw <- readRDS("data-raw/nwfsc_spp_lists.rds")
goa <- readRDS("data-raw/goaai_spp_lists.rds")
ebs <- readRDS("data-raw/bering_spp_lists.rds")

bc <- na.omit(bc$five) |> tolower()
nw <- na.omit(nw$percent5) |> tolower()
goa <- na.omit(goa$percent5) |> tolower()
ebs <- na.omit(ebs$percent5) |> tolower()

x <- sort(unique(c(bc, nw, goa, ebs)))
x

dl <- list(bc, nw, goa, ebs)
dl <- lapply(dl, \(x) {
  x[grepl("rougheye and", x)] <- "rougheye and blackspotted rockfish"
  x[grepl("rougheye/", x)] <- "rougheye and blackspotted rockfish"
  x
  x
})

x <- sort(unique(unlist(dl)))
x

x <- unlist(dl)
xt <- table(x) |> sort()

x[xt >= 2]

x[xt < 2]
