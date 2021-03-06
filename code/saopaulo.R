#### Declives da rede vi�ria, neste caso de S�o Paulo                   ####
##### Rosa F�lix, 6 Janeiro 2021                                    #####

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
library(raster)
library(geodist)
library(slopes)
library(tmap)


## download da �ltima versão da rede OpenStreetMaps
#na d�vida de qual o ficheiro a sacar, ir a https://download.geofabrik.de/
sudeste_osm = oe_get("sudeste", provider = "geofabrik", stringsAsFactors = FALSE, quiet = FALSE, force_download = TRUE, force_vectortranslate = TRUE) #218 MB!

#filtrar pelas categorias que interessam
sudeste_osm_filtered = sudeste_osm %>% 
  dplyr::filter(highway %in% c('primary', "primary_link", 'secondary',"secondary_link", 'tertiary', "tertiary_link", "trunk", "trunk_link", "residential", "cycleway", "living_street", "unclassified", "motorway", "motorway_link", "pedestrian", "steps", "service", "track"))


##ir buscar o limite de São Paulo 
url_sp = "http://dados.prefeitura.sp.gov.br/dataset/af41e7c4-ae27-4bfc-9938-170151af7aee/resource/9e75c2f7-5729-4398-8a83-b4640f072b5d/download/layerdistrito.zip"
temp = tempfile()
download.file(url_sp, temp)
unzip(temp, exdir = "shapefiles")
SaoPaulo = st_read("shapefiles/LAYER_DISTRITO/DEINFO_DISTRITO.shp")
SaoPaulo = st_transform(SaoPaulo, 4326) #projectar em WGS84
SaoPauloLimite = SaoPaulo %>% st_union() #dissolver os concelhos em apenas 1 pol�gono

#Cortar a rede pelo limite, com uma margenzinha
osm_lines_SaoPaulo = st_crop(sudeste_osm_filtered, SaoPauloLimite) #corta nos bounding boxes, para n�o ficar t�o pesado na operação seguinte
RedeOSM_SaoPaulo = st_intersection(osm_lines_SaoPaulo, geo_buffer(SaoPauloLimite, dist=100)) #clip com um buffer de 100m, para as vias não ficarem cortadas

#limpar a rede dos segmentos que nao estão ligados � rede principal
RedeOSM_SaoPaulo$group = stplanr::rnet_group(RedeOSM_SaoPaulo)
table(RedeOSM_SaoPaulo$group)
# plot(RedeOSM_SaoPaulo["group"])
RedeOSM_SaoPaulo_clean = RedeOSM_SaoPaulo %>% filter(group == 1) #o que tem mais segmentos
# mapview::mapview(RedeOSM_Concelho_clean) #verificar

#ir buscar � rede OSM sudeste apenas os segmentos com o mesmo id que os limpos
st_geometry(RedeOSM_SaoPaulo_clean)
RedeViaria = sudeste_osm_filtered %>% filter(osm_id %in% RedeOSM_SaoPaulo_clean$osm_id) #ficar apenas os segmentos da rede limpa
st_geometry(RedeViaria) #verificar se são LINESTRING

#partir os segmentos nos seus v�rtices internos, mas deixar os brunels ok
nrow(RedeViaria)
RedeViaria = stplanr::rnet_breakup_vertices(RedeViaria)
nrow(RedeViaria)
# st_write(RedeViaria, "shapefiles/RedeViariaSaoPaulo_osm.shp") #conv�m ser shp porque o gpkg transforma LINESTRING em MULTISTRING. Mas este vai truncar os campos do "other_tags"
# RedeViaria = st_read("shapefiles/RedeViariaSaoPaulo_osm.shp")


#importar o raster (modelo digital do terreno / digital elevation model)
DEM = raster("raster/SPauloNASA_clip.tif") #tinha tirado da NASA com o QGIS
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
    labels = c("0-3: plano", "3-5: leve","5-8: m�dio", "8-10: exigente", "10-20: terr�vel", ">20: imposs�vel"),
    right = F
  )
round(prop.table(table(RedeViaria$declive_class))*100,1)
RedeViaria$length = st_length(RedeViaria)

# exportar shapefile com os declives, em gpkg (QGIS) e kml (GoogleMaps)
st_write(RedeViaria, "shapefiles/RedeViariaSPaulo_declives.gpkg", append=F)
# st_write(RedeViaria, "shapefiles/RedeViariaSPaulo_declives.gpkg", append=F)

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
    popup.vars = c("Tipo: " = "highway",
                   "Comprimento" = "length",
                   "Declive: " = "declive",
                   "Classe: " = "declive_class"),
    popup.format = list(digits = 1),
    # id = "declive"
    id = "name" #se o computaor n�o conseguir exportar por falta de mem�ria, apagar esta linha.
  )
mapadeclives

tmap_save(mapadeclives, "html/DeclivesSaoPaulo.html") #exportar para html
