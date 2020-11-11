# Produce a Isle Of Wight slope map


# Extract the OSM network from geofabrik
library(dplyr)
library(sf)
library(osmextract)
iow_osm = oe_get("Isle of Wight", provider = "geofabrik", stringsAsFactors = FALSE, quiet = FALSE, force_download = TRUE, force_vectortranslate = TRUE) #218 MB!
iow_network = iow_osm %>% 
  dplyr::filter(highway %in% c('primary', "primary_link", 'secondary',"secondary_link", 'tertiary', "tertiary_link", 
                               "trunk", "trunk_link", "residential", "cycleway", "living_street", "unclassified", 
                               "motorway", "motorway_link", "pedestrian", "steps", "track")) #remove: "service",
table(iow_network_clean$highway)

# Clean the road network
library(stplanr)
iow_network$group = stplanr::rnet_group(iow_network)
plot(iow_network["group"])
iow_network_clean = iow_network %>% filter(group == 1) #the network with more connected segments
# 100*nrow(iow_network_clean)/nrow(iow_network) #percentage of the remaining highways

iow_network_segments = stplanr::rnet_breakup_vertices(iow_network_clean)
# nrow(iow_network_segments)/nrow(iow_network_clean) #multiply factor


# Import DEM (extracted with QGIS SRTM Downloader plugin and clipped)
library(raster)
library(geodist)
DEM = raster("raster/IsleOfWightNASA_clip.tif")
class(DEM)
summary(values(DEM))
res(DEM) #27m of resolution
raster::plot(DEM)
network = iow_network_segments
plot(sf::st_geometry(network), add = TRUE) #check if they overlay

# Get the slope value for each segment (abs), using slopes package
library(slopes)
network$slope = slope_raster(network, e = DEM)
network$slope = network$slope*100 #percentage
summary(network$slope)

# Classify slopes
network$slope_class = network$slope %>%
  cut(
    breaks = c(0, 3, 5, 8, 10, 20, Inf),
    labels = c("0-3: flat", "3-5: mild", "5-8: medium", "8-10: hard", "10-20: extreme", ">20: impossible"),
    right = F
  )
round(prop.table(table(network$slope_class))*100,1)


# make an interactive map
library(tmap)
palredgreen = c("#267300", "#70A800", "#FFAA00", "#E60000", "#A80000", "#730000")
tmap_mode("view")
tmap_options(basemaps = leaflet::providers$CartoDB.Positron) #mapa base
slopemap =
  tm_shape(network) +
  tm_lines(
    col = "slope_class",
    palette = palredgreen, #palete de cores
    lwd = 2, #espessura das linhas
    title.col = "Slope [%]",
    popup.vars = c("Highway" = "highway",
                  "Slope: " = "slope",
                  "Class: " = "slope_class"),
    popup.format = list(digits = 1),
    # id = "slope"
    id = "name" #if it gets too memory consuming, delete this line
  )
slopemap


tmap_save(slopemap, "SlopesIoW.html") #export to html

# export shapefile with hilliness data, in various formats
# st_write(network, "shapefiles/SlopesIoW.gpkg", append=F) #geopackage
# st_write(network, "shapefiles/SlopesIoW.shp", append=F) #shapefile
# st_write(network, "shapefiles/SlopesIoW.kml", append=F) #GoogleMaps