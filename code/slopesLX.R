#declives da rede viária do Porto

#importar packages
pkgs = c("sf", "raster", "geodist", "slopes", "tmap")
# uncomment these lines if line 7 doesn't work...
# install.packages(pkgs)
# install.packages("remotes", quiet = TRUE)
remotes::install_cran(pkgs, quiet = TRUE)

library(sf)
library(raster)
library(geodist)
library(slopes)
library(terra)
library(tmap)


# ler shapefiles das Redes Viárias
# RedeLisboa_dadosabertos = st_read("https://opendata.arcgis.com/datasets/a557c10e19a44f0e9592c7b63bae8d3b_0.geojson")
RedeLisboa_dadosabertos = st_read("shapefiles/RedeViariaLisboa_dadosabertos.gpkg")
summary(RedeLisboa_dadosabertos$slope)
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 0.000   1.308   2.985   4.361   5.779  92.500 
RedeLisboa_dadosabertos = st_zm(RedeLisboa_dadosabertos, drop = T)
# st_crs(RedeLisboa_dadosabertos) = 4326
RedeLisboa_dadosabertosTM = st_transform(RedeLisboa_dadosabertos, crs(RedeAntiga))
RedeLisboa_dadosabertosTM = st_zm(RedeLisboa_dadosabertosTM, drop = T)

RedeAntiga = st_read("D:\\rosa\\Dropbox\\Public\\Declives_Lisboa\\RedeViaria_Lisboa_Declives\\RedeViariaDeclives.shp")
RedeAntiga = st_transform(RedeAntiga, 4326) 
RedeAntiga = st_zm(RedeAntiga, drop = T)

Rede23k = st_read("shapefiles/lisbon_road_segments_r23k.gpkg")
Rede23k = st_transform(Rede23k, 4326) #nao fazer com r1
Rede23k = st_zm(Rede23k, drop = T)

RedeAntigaTM = st_read("D:/GIS/Porto/ignore/Declives_RedeViariaLisboa_TM06_RF.shp")

RedeOSM = st_read("D:/GIS/sDNA/RedeViariaLisboa_osm_prepared.shp")
RedeOSM = st_zm(RedeOSM, drop = T)

RedeOSMtm = st_transform(RedeOSM, 3763) #crs do raster r1

RedeOSMlimpa = st_read("D:/GIS/Porto/osm/aiagaita.shp")
RedeOSMlimpa = st_zm(RedeOSMlimpa, drop = T)
RedeOSMlimpa = st_transform(RedeOSMlimpa, 3763) #crs do raster r1

#Escolher aqui qual se vai usar
RedeViaria = RedeLisboa_dadosabertos
RedeViaria = RedeAntiga #cpm r1
RedeViaria = Rede23k[,c(1,2,5:12,23:38,41,43,44,52,53)]
RedeViaria = RedeAntigaTM
class(RedeViaria)

#ler raster com altimetria
DEMlisboa = raster("raster/LisboaIST_clip_r1.tif") #com 10m de resolução
# DEMlisboa2 = raster("raster/LisboaIST_clip.tif") #com 12.8m de resolução #funciona com rede23k
# DEMlisboa = raster("raster/LisboaIST_clip_original.tif")
class(DEMlisboa)
res(DEMlisboa) 
DEMlisboa[is.na(DEMlisboa[])] = 0  #fill nodata com zeros (rio)
summary(values(DEMlisboa))

# crs(DEMlisboa) = crs("+init=EPSG:4326")
# DEMlisboa2 = projectRaster(DEMlisboa, crs="+proj=longlat +datum=WGS84")

DEMNASAlx = raster("raster/LisboaNASA_clip.tif")
DEMNASAlxTerra = terra::rast("raster/LisboaNASA_clip.tif")
DEMcml = raster("D:/GIS/Porto/mdt_CML/mdt.tif")
DEMcmlTerra = terra::rast("D:/GIS/Porto/mdt_CML/mdt.tif")
res(DEMcml)

#Escolher aqui qual se vai usar
# DEM = DEMlisboa
# DEM = DEMNASAlx


#visualizar
raster::plot(DEMcml)
plot(sf::st_geometry(RedeLisboa_dadosabertosTM), add = TRUE)

raster::plot(DEMNASAlx)
plot(sf::st_geometry(RedeLisboa_dadosabertos), add = TRUE)

#cálculo dos declives por segmento (em abs)
RedeLisboa_dadosabertosTM$slopeCML = slope_raster(RedeLisboa_dadosabertosTM, e = DEMcml) #62 segundos porto, 58 segundos lisboa, 7min lisboa CML
RedeLisboa_dadosabertosTM$slopeCML = slope_raster(RedeLisboa_dadosabertosTM, e = DEMcmlTerra, terra = T)
RedeLisboa_dadosabertos$slopeNASA = slope_raster(RedeLisboa_dadosabertos, e = DEMNASAlx) #62 segundos porto, 58 segundos lisboa
RedeLisboa_dadosabertos$slopeNASA = slope_raster(RedeLisboa_dadosabertos, e = DEMNASAlxTerra, terra = T) #4m37s
RedeOSM$slopeNASA = slope_raster(RedeOSM, e=DEMNASAlx) #39seg
RedeOSMtm$slopeIST = slope_raster(RedeOSMtm, e=DEMlisboa) #37seg > ESTE ESTÁ ÓPTIMO! Mas é preciso algumas vias de 1º grau
RedeOSMlimpa$slopeIST = slope_raster(RedeOSMlimpa, e=DEMlisboa) #38s > mas vendo bem, tem falhas grandes marcando com declives elevados ruas planoas


raster::plot(DEMNASAlx)
plot(sf::st_geometry(Rede23k), add = TRUE)
Rede23k$slopeNASA = slope_raster(Rede23k, e = DEMNASAlxTerra, terra = T) #weired results
Rede23k$slopeNASAnoTerra = slope_raster(Rede23k, e = DEMNASAlx) 

#declive em percentagem
RedeViaria$declive = RedeViaria$slope*100
summary(RedeViaria$declive)
#Porto
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 0.000   2.176   4.007   5.099   6.795  54.882 
#Lisboa
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 0.000   1.520   3.262   4.535   5.920  68.813 
#Liisboa nao projectado
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 0.000   1.443   3.163   4.429   5.805  79.608 
#Lisboa com Rede dados abertos e NASA
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 0.000   3.588   5.853   7.114   9.113  56.181
#Lisboa OSM com NASA
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 0.000   2.664   5.025   6.459   8.558  65.832 
# Lisboa OSM com r1 IST
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 0.000   1.002   2.595   3.883   5.146  77.639 
# Lisboa OSM limpa com r1 IST
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 0.000   1.035   2.642   3.913   5.193  77.639 

summary(RedeViaria$Avg_Slope) #bate quase certo com o nao projectado
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 0.000   1.444   3.165   4.440   5.807  79.608 

#classes
RedeViaria$declive_class =  RedeViaria$declive %>% 
  cut(
    breaks = c(0, 3, 5, 8, 10, 20, Inf),
    labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
    right = F
  ) 
round(prop.table(table(RedeViaria$declive_class))*100,1)
# Porto
# 0-3: plano       3-5: leve      5-8: médio  8-10: exigente 10-20: terrível >20: impossível 
#   36.6            24.0            21.0             7.2            10.1             1.1 
# Lisboa, com slope()
# 0-3: plano       3-5: leve      5-8: médio  8-10: exigente 10-20: terrível >20: impossível 
# 46.8            21.6            16.5             5.9             7.6             1.6 
# Lisboa, com nao projectado
# 0-3: plano       3-5: leve      5-8: médio  8-10: exigente 10-20: terrível >20: impossível 
# 47.9            21.4            16.2             5.6             7.4             1.5 
# Lisboa, com o calculado no ArcGIS
# 0-3: plano       3-5: leve      5-8: médio  8-10: exigente 10-20: terrível >20: impossível 
# 54.8            18.1            14.0             5.0             6.7             1.4 
# Lisboa, com rede 23k e NASA - péssimo!
# 0-3: plano       3-5: leve      5-8: médio  8-10: exigente 10-20: terrível >20: impossível 
# 18.4            22.4            27.6            10.8            18.1             2.8 
# Lisboa, com rede OSM e NASA....
# 0-3: plano       3-5: leve      5-8: médio  8-10: exigente 10-20: terrível >20: impossível 
# 28.9            20.8            22.4             8.9            16.0             3.0 
# Lisboa, com rede OSM e IST !!!
# 0-3: plano       3-5: leve      5-8: médio  8-10: exigente 10-20: terrível >20: impossível 
# 55.0            19.0            14.2             4.6             5.9             1.3
# Lisboa, com rede OSM limpa e IST !!!
# 0-3: plano       3-5: leve      5-8: médio  8-10: exigente 10-20: terrível >20: impossível 
# 54.4            19.2            14.4             4.7             6.0             1.3 

RedeViaria$declive_classOriginal =  RedeViaria$Avg_Slope %>% #mudar para declive
  cut(
    breaks = c(0, 3, 5, 8, 10, 20, Inf),
    labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
    right = F
  ) 
round(prop.table(table(RedeViaria$declive_classOriginal))*100,1)
# 0-3: plano       3-5: leve      5-8: médio  8-10: exigente 10-20: terrível >20: impossível 
# 47.9            21.4            16.1             5.6             7.4             1.5 

#palete de cores
palredgreen = c("#267300", "#70A800", "#FFAA00", "#E60000", "#A80000", "#730000")

#ver mapa
tmap_mode("view")
tmap_options(basemaps = leaflet::providers$CartoDB.Positron)
mapadeclives =
tm_shape(RedeViaria) +
  tm_lines(
    col = "declive_class",
    palette = palredgreen, #palete de cores
    lwd = 2, #espessura das linhas
    title.col = "Declive [%]",
    popup.vars = c("Declive: " = "DecliveAbs",
                   "Classe: " = "declive_class"),
    popup.format = list(digits = 1)
    # id = "NAME"  #ele crasha com demasiada info
  )
mapadeclives

mapadecliveslxnovo =
  tm_shape(RedeViaria) +
  tm_lines(
    col = "declive_class",
    palette = palredgreen, #palete de cores
    lwd = 2, #espessura das linhas
    title.col = "Declive [%]",
    popup.vars = c("Declive: " = "declive",
                   "Classe: " = "declive_class"),
    popup.format = list(digits = 1)
    # id = "NAME"
  )
mapadecliveslxnovo

mapadeclivesoriginal =
  tm_shape(RedeViaria) +
  tm_lines(
    col = "declive_class",
    palette = palredgreen, #palete de cores
    lwd = 2, #espessura das linhas
    title.col = "Declive [%]",
    popup.vars = c("Declive: " = "declive",
                   "Classe: " = "declive_class"),
    popup.format = list(digits = 1)
    # id = "NAME"
  )
mapadeclivesoriginal

mapadecliveslxosm =
  tm_shape(RedeOSMlimpa[,c(2,11,12,13)]) +
  tm_lines(
    col = "declive_class",
    palette = palredgreen, #palete de cores
    lwd = 2, #espessura das linhas
    title.col = "Declive [%]",
    popup.vars = c("Declive: " = "declive",
                   "Classe: " = "declive_class"),
    popup.format = list(digits = 1),
    id = "NAME"
  )
mapadecliveslxosm


tmap_save(mapadeclives, "DeclivesLisboa.html") #ficheiro com declives originais do ArcGIS 2012
tmap_save(mapadecliveslxnovo, "DeclivesLisboa_slope.html") #com claculo do slopes, rede 23k, rastr projectado em WGS84
tmap_save(mapadeclivesoriginal, "DeclivesLisboa_orgin.html") #com calculo do slopes, rede 23k, raster original
tmap_save(mapadecliveslxosm, "DeclivesLisboa_osm.html") 
#nao deu com a shp original, porque fica de fora do dem? no arcgis dá.

#exportar shapefile com os declives, em formato GeoPackage (QGIS)
#st_write(RedeViaria, "shapefiles/RedeViariaLisboa_declives.gpkg", append=T)
st_write(RedeAntiga[,c(1,6:12,24:41,54,44:47,51,53,52)], "shapefiles/RedeViariaLisboa_declives.gpkg", append=T)


