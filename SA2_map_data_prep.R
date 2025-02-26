###############################################################################
#' Description: Shape file preparation for map
#'
#' Input: Meshblock higher geographies map
#' https://datafinder.stats.govt.nz/layer/120977-meshblock-higher-geographies-2025/
#'
#' Output: Rds file containing prepared GIS data
#'
#' Author: Simon Anastasiadis
#'
#' Dependencies: sf, here, rmapshaper, dplyr packages
#'
#' Notes:
#' - Uses code folding by headers (Alt + O to collapse all).
#'
#' Issues:
#'
#' History (reverse order):
#' 2025-01-27 SA v1
#' ############################################################################

## install required packages ---------------------------------------------- ----

req_packages = c("sf", "here", "rmapshaper", "dplyr")
for(pp in req_packages){
  if(pp %in% installed.packages())
    next
  install.packages(pp)
}

## setup ------------------------------------------------------------------ ----

library(dplyr)

input_file = "meshblock-higher-geographies-2025.shp"
output_file = "SA2_higher_geographies_2025.Rds"

## process shape file ----------------------------------------------------- ----

# load file
shape_data = sf::st_read(here::here(input_file))

# convert to leaflet projection
shape_data = sf::st_transform(shape_data, crs = 4326)

# discard records that are not in regional council
shape_data = shape_data[shape_data$LANDWATER_ == "Mainland",]

# add column for island based on regional council
shape_data$island = ifelse(substr(shape_data$REGC2025_V, 1, 1) == "0", "north", "south")

# rename required columns
shape_data$TALB_code = shape_data$TALB2025_V
shape_data$TALB_name = shape_data$TALB2025_2
shape_data$SA2_code = shape_data$SA22025_V1
shape_data$SA2_name = shape_data$SA22025__2

# keep req columns
req_columns = c("id", "island", "TALB_code", "TALB_name", "SA2_code", "SA2_name", "geometry")
for(col in colnames(shape_data)){
  if(col %in% req_columns){
    next
  }
  shape_data[[col]] = NULL
}

## simplify geometry ------------------------------------------------------ ----

# must process in separate islands due to memory constraints
# alternative is to install system version, see:
# https://github.com/ateucher/rmapshaper#using-the-system-mapshaper
north = shape_data[shape_data$island == "north",]
south = shape_data[shape_data$island == "south",]
rm("shape_data")

# tested keep = 0.05, 0.01, 0.005 >> 0.05 recommended for fidelity
north = rmapshaper::ms_simplify(north, keep = 0.05, sys_mem = 12)
south = rmapshaper::ms_simplify(south, keep = 0.05, sys_mem = 12)

# setting to prevent error - but makes lots of warnings
sf::sf_use_s2(FALSE)
# merge MBs to make SA2s
north = dplyr::group_by(north, island, TALB_code, TALB_name, SA2_code, SA2_name)
north = dplyr::summarise(north, geometry = sf::st_union(geometry), .groups = "drop")
south = dplyr::group_by(south, island, TALB_code, TALB_name, SA2_code, SA2_name)
south = dplyr::summarise(south, geometry = sf::st_union(geometry), .groups = "drop")

# recombine
shape_data = rbind(north, south)
rm("north", "south")

# add column for layerIds (must be of type character)
shape_data$id = as.character(seq_len(nrow(shape_data)))

## test plot -------------------------------------------------------------- ----

# print(Sys.time())
# 
# leaflet::leaflet(shape_data) %>%
#   leaflet::addProviderTiles("OpenStreetMap",group = "OpenStreetMap") %>%
#   leaflet::addTiles() %>%
#   leaflet::addPolygons(
#     layerId = ~id,
#     color = "blue",
#     fillOpacity = 0.5,
#     highlight = leaflet::highlightOptions(weight = 3, color = "red", bringToFront = TRUE)
#   )
# 
# print(Sys.time())

## output processed file -------------------------------------------------- ----

saveRDS(shape_data, here::here(output_file))
