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

xt[xt >= 2]


df <- data.frame(scientific_name = sort(names(xt[xt >= 2])))
get_itis <- function(spp) {
  out <- taxize::get_ids(spp, db = "itis", verbose = FALSE)
  as.integer(unlist(out))
}
df$itis <- get_itis(df$scientific_name)

# assign itis to big skate (listed as Raja binoculata in nwfsc and ITIS)
df$itis[df$scientific_name == "beringraja binoculata"] <- 160848
# remove unidentified sp group and invertebrate
df <- dplyr::filter(df, scientific_name != "lepidopsetta sp.", # rock sole unid.
                        itis != 96979) # spot shrimp

saveRDS(df, "data-raw/joined_list.rds")
