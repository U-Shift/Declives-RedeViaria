#google elevation and slopes

library(tidyverse)
library(sf)
library(slopes)
library(googleway)
set_key(Sys.getenv("GOOGLE_KEY"))


#use small sample od 10 linestrings from slopes package
Roads = st_transform(lisbon_road_segments, 4326) %>% slice(20:30)
mapview::mapview(Roads)


Roads_coords = data.frame(st_coordinates(Roads$geom))
names(Roads_coords) = c("lon", "lat", "l")


google = google_elevation(Roads_coords)
Roads_coords$elev = google$results$elevation
# Roads_coords$resol = google$results$resolution

Roads_xyz = Roads
Roads_xyz$geom= NULL
Roads_xyz$bbox= NULL

l=list()
for (i in 1:nrow(Roads)){ 
  line = Roads_coords[Roads_coords$l == i,]
  
  l[i] = st_as_sf(line, coords = c("lon","lat","elev")) %>% st_combine() %>%  st_cast("LINESTRING")
  
  Roads_xyz$geom[i] = l[i] 
}

Roads_xyz = st_as_sf(Roads_xyz, dim = "XYZ", crs=st_crs(Roads))

slope_xyz(Roads_xyz)
Roads$slope = slope_xyz(Roads_xyz)

mapview::mapview(Roads["slope"])





# with 1 request each linestring -----------------------------------------------------------------
library(tidyverse)
library(sf)
library(slopes)
library(googleway)
set_key(Sys.getenv("GOOGLE_KEY"))


Roads = st_transform(lisbon_road_segments, 4326)
# mapview::mapview(Roads)

#a df with only corddinates in WGS84 (google does not like others)
Roads_coords = data.frame(st_coordinates(Roads$geom))
names(Roads_coords) = c("lon", "lat", "l")

#a df without geometries
Roads_xyz = Roads
Roads_xyz$geom= NULL 
Roads_xyz$bbox= NULL
Roads_xyz$geom= NA

#get elevarion per point, and transform each line in a xyz linestring again
for (i in 1:nrow(Roads)){ 
  google = google_elevation(Roads_coords[Roads_coords$l == i,])
  Roads_coords$elev[Roads_coords$l == i] = google$results$elevation
  Roads_coords$resol[Roads_coords$l == i] = google$results$resolution
  
  line = Roads_coords[Roads_coords$l == i,]
  Roads_xyz$geom[i] = st_as_sf(line, coords = c("lon","lat","elev")) %>% st_combine() %>%  st_cast("LINESTRING")
}

Roads_xyz = st_as_sf(Roads_xyz, dim = "XYZ", crs=st_crs(Roads))

Roads$slope = slope_xyz(Roads_xyz) #to store the values in the original dataset

mapview::mapview(Roads["slope"])

summary(Roads$slope)
summary(Roads_coords$resol) #check average resolution



# for Benchmark paper -------------------------------------------------------------------------

RoadNetworkGMAP = RoadNetwork

#a df with only corddinates in WGS84 (google does not like others)
Roads_coords = data.frame(st_coordinates(RoadNetworkGMAP$geom))
names(Roads_coords) = c("lon", "lat", "l")

#a df without geometries
Roads_xyz = RoadNetworkGMAP
Roads_xyz$geometry= NULL 
Roads_xyz$bbox= NULL
Roads_xyz$geom= NA

#get elevarion per point, and transform each line in a xyz linestring again
for (i in 1:nrow(RoadNetworkGMAP)){ #1:nrow(RoadNetworkGMAP)
  google = google_elevation(Roads_coords[Roads_coords$l == i,])
  Roads_coords$elev[Roads_coords$l == i] = google$results$elevation
  Roads_coords$resol[Roads_coords$l == i] = google$results$resolution
  
  line = Roads_coords[Roads_coords$l == i,]
  Roads_xyz$geom[i] = st_as_sf(line, coords = c("lon","lat","elev")) %>% st_combine() %>%  st_cast("LINESTRING")
} #este processo às vezes pára, é preciso recomeçar de onde parou, substituindo o número no loop 1:

Roads_xyz = st_as_sf(Roads_xyz, dim = "XYZ", crs=st_crs(RoadNetworkGMAP))

RoadNetworkGMAP$slope = slope_xyz(Roads_xyz)
RoadNetworkGMAP$slope_pct = RoadNetworkGMAP$slope*100 #percentage

summary(RoadNetworkGMAP$slope) #devia ter tirado os tunneis
summary(Roads_coords$resol) #check average resolution #1.92

mapview::mapview(RoadNetworkGMAP["slope_pct"])
