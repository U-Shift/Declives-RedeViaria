#tentativa de fazer download da rede viária do OpenStreet Map, com o package osmextract: https://itsleeds.github.io/osmextract/articles/osmextract.html

remotes::install_github("ITSLeeds/osmextract")

library(osmextract)
library(sf)


# osm_lines_lx = oe_get("Lisbon Portugal", provider = "openstreetmap_fr", stringsAsFactors = FALSE)
# 
# osm_lines_lx = oe_get("Lisbon", provider = "geofabrik", match_by = "name",stringsAsFactors = FALSE)
# 
# oe_match("Lisbon", provider="openstreetmap_fr" , max_string_dist = 3)

Lisbonplace = oe_match(c(-9.14074,38.73153))

osm_lines_lx = oe_get("Portugal", provider = "geofabrik", stringsAsFactors = FALSE) #são 218MB !


#clipar com a shape de Lisboa
LisboaLimite = st_read("D:/GIS/Ciclovias_CML/RedeCiclavel-Lisboa/data/Lisboa_limite.gpkg")
LisboaLimite = st_transform(LisboaLimite, 4326)

st_bbox(LisboaLimite)

osm_lines_Lisboa = st_crop(osm_lines_lx, LisboaLimite) #corta nos bounding boxes
# st_write(osm_lines_Lisboa, "D:/GIS/Porto/osm/osm_linesLisboaTODAS.gpkg")
osm_lines_Lisboa = st_read("D:/GIS/Porto/osm/osm_linesLisboaTODAS.gpkg")

table(osm_lines_Lisboa$highway)
plot(osm_lines_Lisboa$highway[osm_lines_Lisboa$highway=="cycleway"])
plot(osm_lines_Lisboa["highway"])
# mapview::mapview(osm_lines_Lisboa, zcol="highway")


lisbonosm = osm_lines_Lisboa %>% 
  dplyr::filter(highway %in% c('primary', 'secondary', 'tertiary', "residential", "cycleway", "living_street",
                               "primary_link", "secondary_link", "tertiary_link", "pedestrian", "steps", "service")) # "footway"?dúvida de remover pedestrian ou footway

plot(lisbonosm["highway"])
table(lisbonosm$highway)

st_write(lisbonosm, "D:/GIS/Porto/osm/osm_linesLisboaFILTRO.gpkg", append = T)


lisbonosm_declives = osm_lines_Lisboa %>% 
  dplyr::filter(highway %in% c('primary', 'secondary', 'tertiary', "residential", "cycleway", "living_street",
                               "primary_link", "secondary_link", "tertiary_link", "pedestrian", "steps", "service", "trunk", "trunk_link")) # "footway"?dúvida de remover pedestrian ou footway

