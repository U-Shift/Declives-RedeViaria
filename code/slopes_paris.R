# Produce a Paris slope map


# Extract the OSM network from geofabrik
library(dplyr)
library(sf)
library(osmextract)
paris_osm = oe_get("Paris", provider = "geofabrik", stringsAsFactors = FALSE, quiet = FALSE, force_download = TRUE, force_vectortranslate = TRUE) #579 MB!
paris_network = paris_osm %>% 
  dplyr::filter(highway %in% c('primary', "primary_link", 'secondary',"secondary_link", 'tertiary', "tertiary_link", 
                               "trunk", "trunk_link", "residential", "cycleway", "living_street", "unclassified", 
                               "motorway", "motorway_link", "pedestrian", "steps", "track", "service")) #remove: "service"?
table(paris_network$highway)

# Clean the road network
library(stplanr)
paris_network$group = stplanr::rnet_group(paris_network)
plot(paris_network["group"])
paris_network_clean = paris_network %>% filter(group == 1) #the network with more connected segments
100*nrow(paris_network_clean)/nrow(paris_network) #percentage of the remaining highways

paris_network_segments = stplanr::rnet_breakup_vertices(paris_network_clean)
nrow(paris_network_segments)/nrow(paris_network_clean) #multiply factor


# Import DEM (extracted with QGIS SRTM Downloader plugin and clipped)
library(raster)
DEM = raster("https://github.com/U-Shift/Declives-RedeViaria/raw/main/raster/ParisNASA_clip.tif")
class(DEM)
summary(values(DEM))
res(DEM) #27m of resolution
network = paris_network_segments
raster::plot(DEM)
plot(sf::st_geometry(network), add = TRUE) #check if they overlay


# Get the slope value for each segment (abs), using slopes package
library(slopes)
library(geodist)
network$slope = slope_raster(network, dem = DEM) #about 60sec
network$slope = network$slope*100 #percentage
summary(network$slope) #!

# Classify slopes
network$slope_class = network$slope %>%
  cut(
    breaks = c(0, 3, 5, 8, 10, 20, Inf),
    labels = c("0-3: flat", "3-5: mild", "5-8: medium", "8-10: hard", "10-20: extreme", ">20: impossible"),
    right = F
  )
round(prop.table(table(network$slope_class))*100,1)
# 0-3: flat       3-5: mild     5-8: medium      8-10: hard  10-20: extreme >20: impossible 
# 58.4            21.9            12.5             3.3             3.5             0.3 

# Estimate lenght
network$length = st_length(network)

# make an interactive map
library(tmap)
palredgreen = c("#267300", "#70A800", "#FFAA00", "#E60000", "#A80000", "#730000") #color palette
tmap_mode("view")
tmap_options(basemaps = leaflet::providers$CartoDB.Positron) #basemap
slopemap =
  tm_shape(network) +
  tm_lines(
    col = "slope_class",
    palette = palredgreen,
    lwd = 2, #line width
    title.col = "Slope [%]",
    popup.vars = c("Highway" = "highway",
                   "Extension" = "length",
                  "Slope: " = "slope",
                  "Class: " = "slope_class"),
    popup.format = list(digits = 1),
    # id = "slope"
    id = "name" #if it gets too memory consuming, delete this line
  )
slopemap #takes time to load


tmap_save(slopemap, "html/SlopesParis.html") #export to html

# export shapefile with hilliness data, in various formats
st_write(network, "shapefiles/Slopesparis.gpkg", append=F) #geopackage
# st_write(network, "shapefiles/Slopesparis.shp", append=F) #shapefile
# st_write(network, "shapefiles/Slopesparis.kml", append=F) #GoogleMaps

# tidy up
rm(paris_osm,paris_network_clean,paris_network_segments, paris_network, slopemap)
