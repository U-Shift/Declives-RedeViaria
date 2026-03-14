# Produce a Sydney slope map

# Extract the OSM network from BBBike/Geofabrik
library(dplyr)
library(sf)
library(osmextract)

# Fetch the Sydney extract
sydney_osm = oe_get("Sydney", stringsAsFactors = FALSE, quiet = FALSE, force_download = TRUE, force_vectortranslate = TRUE) 
sydney_network_filtered = sydney_osm %>% 
  dplyr::filter(highway %in% c('primary', "primary_link", 'secondary',"secondary_link", 'tertiary', "tertiary_link", 
                               "trunk", "trunk_link", "residential", "cycleway", "living_street", "unclassified", 
                               "motorway", "motorway_link", "pedestrian", "steps", "track", "service"))

table(sydney_network_filtered$highway)

# The extract is typically already cropped to the city's bounding box region.
# We will use it as-is, skipping the external polygon boundary clipping.
sydney_network = sydney_network_filtered

# Clean the road network
library(stplanr)
sydney_network$group = stplanr::rnet_group(sydney_network)
plot(sydney_network["group"])
sydney_network = sydney_network %>% filter(group == 1) #the network with more connected segments

st_geometry(sydney_network) # are linestrings?
sydney_network = st_cast(sydney_network, "LINESTRING", do_split=F) # only as linestrings
sydney_network_segments = stplanr::rnet_breakup_vertices(sydney_network)
nrow(sydney_network_segments)/nrow(sydney_network) #multiply factor

# Import DEM 
library(raster)
dem_path = "raster/SydneyNASA_clip.tif"

if (file.exists(dem_path)) {
  DEM = raster(dem_path)
} else {
  message("DEM file not found locally. Downloading using 'elevatr'...")
  library(elevatr) # You may need to run install.packages("elevatr") first
  # Download DEM for the network extent (z = 11 gives roughly ~30m resolution, similar to SRTM)
  DEM = get_elev_raster(locations = sydney_network_segments, z = 11, clip = "bbox")
  
  # Ensure the directory exists and save the downloaded raster for future use
  if (!dir.exists("raster")) dir.create("raster")
  writeRaster(DEM, dem_path, format = "GTiff", overwrite = TRUE)
}

class(DEM)
summary(values(DEM))
res(DEM) 

network = sydney_network_segments
# raster::plot(DEM)
# plot(sf::st_geometry(network), add = TRUE) #check if they overlay

# Get the slope value for each segment (abs), using slopes package
library(slopes)
library(geodist)
network$slope = slope_raster(network, dem = DEM) 
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

# Estimate length
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
    id = "name" #if it gets too memory consuming, delete this line
  )
slopemap #takes time to load

tmap_save(slopemap, "html/SlopesSydney.html") #export to html

# export shapefile with hilliness data, in various formats
st_write(network, "shapefiles/SlopesSydney.gpkg", append=F) #geopackage
