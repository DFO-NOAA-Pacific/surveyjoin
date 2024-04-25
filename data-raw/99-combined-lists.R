bc <- readRDS("data-raw/bc-common-list.rds")
nw <- readRDS("~/Downloads/nwfsc_spp_lists.rds")
goa <- readRDS("~/Downloads/goaai_spp_lists.rds")
ebs <- readRDS("~/Downloads/bering_spp_lists.rds")

bc <- spp1 |> tolower()
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
