#### Declives da rede viária, neste caso do Porto                     ####
#### Para qualquer ourtra de Portugal, alterar o Concelho na linha 41 ####
##### Rosa Félix, 8 Novembro 2020                                    #####

#instalar packages
# pkgs = c("sf", "raster", "slopes", "geodist", "tmap", "igraph")
# remotes::install_cran(pkgs, quiet = TRUE)
# uncomment these lines if line 5 doesn't work...
# remotes = c("stplnar", "osmextract")
# install.packages(pkgs)
# install.packages("remotes", quiet = TRUE)
# remotes::install_github("ITSLeeds/osmextract")
# remotes::install_github("ropensci/stplanr")

#importar packages
library(tidyverse)
library(sf)
library(osmextract)
library(stplanr)
library(igraph)
library(raster)
library(geodist)
library(slopes)
library(tmap)


#download da última versão da rede OpenStreetMaps
portugal_osm = oe_get("Portugal", provider = "geofabrik", stringsAsFactors = FALSE, quiet = FALSE, force_download = TRUE, force_vectortranslate = TRUE) #218 MB!
# portugal_osm = st_read("OSM/geofabrik_portugal-latest.gpkg", layer= "lines")

#filtrar pelas categorias que interessam
portugal_osm_filtered = portugal_osm %>% 
  dplyr::filter(highway %in% c('primary', "primary_link", 'secondary',"secondary_link", 'tertiary', "tertiary_link", "trunk", "trunk_link", "residential", "cycleway", "living_street", "unclassified", "motorway", "motorway_link", "pedestrian", "steps", "service", "track"))
# st_write("OSM/oportugal_osm_semFOOTWAY.gpkg")
# saveRDS(portugal_osm_filtered, "OSM/portugal_osm_filtered.Rds")
# portugal_osm_filtered = st_read("OSM/oportugal_osm_semFOOTWAY.gpkg")
# portugal_osm_filtered = readRDS("OSM/portugal_osm_filtered.Rds")

#ir buscar os limites dos concelhos, segundo a CAOP 2019
Concelhos = st_read("shapefiles/ConcelhosPT.gpkg")
Concelhos$Concelho  #Ver lista com os nomes dos concelhos disponíveis
ConcelhoLimite = Concelhos %>% filter(Concelho == "PORTO") #aqui podemos escolher outro qualquer

#Cortar a rede pelo concelho, com uma margenzinha
osm_lines_Concelho = st_crop(portugal_osm_filtered, ConcelhoLimite) #corta nos bounding boxes, para não ficar tão pesado na operação seguinte
RedeOSM_Concelho = st_intersection(osm_lines_Concelho, geo_buffer(ConcelhoLimite, dist=100)) #clip com um buffer de 100m, para as vias não ficarem cortadas

#limpar a rede dos segmentos que nao estão ligados à rede principal
RedeOSM_Concelho$group = stplanr::rnet_group(RedeOSM_Concelho)
table(RedeOSM_Concelho$group)
plot(RedeOSM_Concelho["group"])
RedeOSM_Concelho_clean = RedeOSM_Concelho %>% filter(group == 1) #o que tem mais segmentos
# mapview::mapview(RedeOSM_Concelho_clean) #verificar

#ir buscar à rede OSM Portugal apenas os segmentos com o mesmo id que os limpos
st_geometry(RedeOSM_Concelho_clean)
RedeViaria = portugal_osm_filtered %>% filter(osm_id %in% RedeOSM_Concelho_clean$osm_id) #ficar apenas os segmentos da rede limpa
st_geometry(RedeViaria) #verificar se são LINESTRING

#partir os segmentos nos seus vértices internos, mas deixar os brunels ok
nrow(RedeViaria)
RedeViaria = stplanr::rnet_breakup_vertices(RedeViaria)
nrow(RedeViaria)
# st_write(RedeViaria, "shapefiles/RedeViariaPorto_osm.shp") #convém ser shp porque o gpkg transforma LINESTRING em MULTISTRING. Mas este vai truncar os campos do "other_tags"


# RedeViaria = st_read("shapefiles/RedeViariaPorto_osm.shp")
# RedeViaria = st_cast(RedeViaria, "LINESTRING", do_split=F) #caso seja uma rede em MULTILINESRING
# RedeViaria = st_transform(RedeViaria, 4326) #projectar em WGS84
# class(RedeViaria)

#importar o raster (modelo digital do terreno / digital elevation model)
DEM = raster("raster/PortoNASA_clip.tif") #mudar o raster dependendo do município
class(DEM)
summary(values(DEM))
res(DEM)
raster::plot(DEM)
plot(sf::st_geometry(RedeViaria), add = TRUE) #verificar se coincidem

#calcular os declives de cada segmento (em absoluto)
RedeViaria$slope = slope_raster(RedeViaria, e = DEM)
RedeViaria$declive = RedeViaria$slope*100 #em percentagem
summary(RedeViaria$declive)
RedeViaria$declive_class = RedeViaria$declive %>%
  cut(
    breaks = c(0, 3, 5, 8, 10, 20, Inf),
    labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
    right = F
  )
round(prop.table(table(RedeViaria$declive_class))*100,1)
# exportar shapefile com os declives, em gpkg (QGIS) e kml (GoogleMaps)
# st_write(RedeViaria, "shapefiles/RedeViariaPorto_declives.gpkg", append=F)
# st_write(RedeViaria, "shapefiles/RedeViariaPorto_declives.kml", append=F)

#produzir um mapa interactivo
palredgreen = c("#267300", "#70A800", "#FFAA00", "#E60000", "#A80000", "#730000")
tmap_mode("view")
tmap_options(basemaps = leaflet::providers$CartoDB.Positron) #mapa base
mapadeclives =
  tm_shape(RedeViaria) +
  tm_lines(
    col = "declive_class",
    palette = palredgreen, #palete de cores
    lwd = 2, #espessura das linhas
    title.col = "Declive [%]",
    popup.vars = c("Declive: " = "declive",
                   "Classe: " = "declive_class"),
    popup.format = list(digits = 1),
    # id = "declive"
    id = "name" #se o computaor não conseguir exportar por falta de memória, apagar esta linha.
  )
mapadeclives

tmap_save(mapadeclives, "DeclivesPorto.html") #exportar para html
