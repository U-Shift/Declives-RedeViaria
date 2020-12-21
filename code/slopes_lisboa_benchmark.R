#declives da rede viária de Lisboa

#importar packages
pkgs = c("sf", "raster", "geodist", "slopes", "tmap")
# uncomment these lines if line 7 doesn't work...
# install.packages(pkgs)
# install.packages("remotes", quiet = TRUE)
remotes::install_cran(pkgs, quiet = TRUE)
remotes::install_github("ITSleeds/slopes") #update slopes to latest

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
RedeLisboa_dadosabertos = sf::st_cast(RedeLisboa_dadosabertos, 'LINESTRING') #para funcionar com o slopes
# st_crs(RedeLisboa_dadosabertos) #WGS84

RedeLisboa_dadosabertosTM = st_transform(RedeLisboa_dadosabertos, 3763) #crs do raster IST


RedeOSM = st_read("D:/GIS/sDNA/RedeViariaLisboa_osm_prepared.shp") #mudar caminho e explicar como foi feita
RedeOSM = st_zm(RedeOSM, drop = T)

RedeOSMtm = st_transform(RedeOSM, 3763)

RedeOSMlimpa = st_read("D:/GIS/Porto/osm/aiagaita.shp")
RedeOSMlimpa = st_zm(RedeOSMlimpa, drop = T)
RedeOSMlimpa = RedeOSMlimpa[RedeOSMlimpa$highway!="service",] #remover as vias de serviço
RedeOSMlimpaTM = st_transform(RedeOSMlimpa, 3763) #crs do raster r1

##ESTES ESTAO COM MA PROJECCAO - REMOVER!!
RedeLisboa2012 = st_read("https://github.com/U-Shift/Declives-RedeViaria/blob/main/shapefiles/RedeViariaLisboa_declives.gpkg?raw=true")
# RedeLisboa2012 = st_zm(RedeLisboa2012, drop = T)
# RedeLisboa2012TM = st_transform(RedeLisboa2012, 3763) #passar de datum 73 para ETRS89, fica com mais falhas!
RedeLisboa2012 = sf::st_cast(RedeLisboa2012, 'LINESTRING') #para funcionar com o slopes
# RedeLisboa2012$declive_class = factor(as.character(RedeLisboa2012$declive_class), levels = c("0-3: plano","3-5: leve","5-8: médio","8-10: exigente","10-20: terrível","20: impossível"))


RedeLisboa2012dropbox = st_read("D:/GIS/Porto/Declives_RedeViariaLisboa_TM06_RF.shp")
RedeLisboa2012dropbox = sf::st_cast(RedeLisboa2012dropbox, 'LINESTRING')

# #Escolher aqui qual se vai usar
# RedeViaria = RedeLisboa_dadosabertos
# RedeViaria = RedeLisboa_dadosabertosTM
# RedeViaria = RedeLisboa_dadosabertosTM
# RedeViaria = RedeAntigaTM
# class(RedeViaria)

#ler raster com altimetria
DEMlxIST = raster("raster/LisboaIST_clip_r1.tif") #com 10m de resolução, em TM
res(DEMlxIST) 
DEMlxIST[is.na(DEMlxIST[])] = 0  #fill nodata com zeros (rio)
summary(values(DEMlxIST))

DEMNASAlx = raster("raster/LisboaNASA_clip.tif") #com 28m de resolução, em WGS84
res(DEMNASAlx)
summary(values(DEMNASAlx))

#Escolher aqui qual se vai usar
# DEM = DEMlisboa
# DEM = DEMNASAlx


#visualizar
raster::plot(DEMNASAlx)
plot(sf::st_geometry(RedeLisboa_dadosabertos), add = TRUE)

raster::plot(DEMlxIST)
plot(sf::st_geometry(RedeOSMlimpaTM), add = TRUE)

raster::plot(DEMlxIST)
plot(sf::st_geometry(RedeLisboa2012TM), add = TRUE)
plot(sf::st_geometry(RedeLisboa2012), add = TRUE) #interesting!

#cálculo dos declives por segmento (em abs).
## Dados Abertos CML + NASA
RedeLisboa_dadosabertos$slopeNASA = 100 * slope_raster(RedeLisboa_dadosabertos, e = DEMNASAlx) # 04m 51s, 05m 04s
RedeLisboa_dadosabertos$declive_class = RedeLisboa_dadosabertos$slopeNASA %>%
  cut(
    breaks = c(0, 3, 5, 8, 10, 20, Inf),
    labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
    right = F
  ) 
# round(prop.table(table(RedeLisboa_dadosabertos$declive_class))*100,1)
# summary(RedeLisboa_dadosabertos$slopeNASA)

## Dados Abertos CML + IST
RedeLisboa_dadosabertosTM$slopeIST = 100 * slope_raster(RedeLisboa_dadosabertosTM, e = DEMlxIST) # 04m 42s, 05m 37s
RedeLisboa_dadosabertosTM$declive_class = RedeLisboa_dadosabertosTM$slopeIST %>%
  cut(
    breaks = c(0, 3, 5, 8, 10, 20, Inf),
    labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
    right = F
  ) 
# round(prop.table(table(RedeLisboa_dadosabertosTM$declive_class))*100,1)
# summary(RedeLisboa_dadosabertosTM$slopeIST)

## Dados OSM limpos  + NASA
RedeOSMlimpa$slopeNASA = 100 * slope_raster(RedeOSMlimpa, e=DEMNASAlx) # 18s
RedeOSMlimpa$declive_class = RedeOSMlimpa$slopeNASA %>%
  cut(breaks = c(0, 3, 5, 8, 10, 20, Inf),
    labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
    right = F) 
# round(prop.table(table(RedeOSMlimpa$declive_class))*100,1)
# summary(RedeOSMlimpa$slopeNASA)

## Dados OSM limpos  + IST
RedeOSMlimpaTM$slopeIST = 100 * slope_raster(RedeOSMlimpaTM, e=DEMlxIST) # 16s
RedeOSMlimpaTM$declive_class = RedeOSMlimpaTM$slopeIST %>%
  cut(breaks = c(0, 3, 5, 8, 10, 20, Inf),
    labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
    right = F) 
# round(prop.table(table(RedeOSMlimpaTM$declive_class))*100,1)
# summary(RedeOSMlimpaTM$slopeIST)

## Dados OSM  + NASA
RedeOSM$slopeNASA = 100 * slope_raster(RedeOSM, e=DEMNASAlx) # 24s
RedeOSM$declive_class = RedeOSM$slopeNASA %>%
  cut(breaks = c(0, 3, 5, 8, 10, 20, Inf),
      labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
      right = F) 
# round(prop.table(table(RedeOSM$declive_class))*100,1)
# summary(RedeOSM$slopeNASA)

## Dados OSM  + IST
RedeOSMtm$slopeIST = 100 * slope_raster(RedeOSMtm, e=DEMlxIST) # 22s
RedeOSMtm$declive_class = RedeOSMtm$slopeIST %>%
  cut(breaks = c(0, 3, 5, 8, 10, 20, Inf),
      labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
      right = F) 
# round(prop.table(table(RedeOSMtm$declive_class))*100,1)
# summary(RedeOSMtm$slopeIST)


## Rede rosa 2012 + IST
RedeLisboa2012$slopeISTdatum = 100 * slope_raster(RedeLisboa2012, e=DEMlxIST) # 52s
RedeLisboa2012$declive_class3 = RedeLisboa2012$slopeISTdatum %>%
  cut(breaks = c(0, 3, 5, 8, 10, 20, Inf),
      labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
      right = F) 
# round(prop.table(table(RedeLisboa2012$declive_class))*100,1)
# round(prop.table(table(RedeLisboa2012TM$declive_class2))*100,1)
# round(prop.table(table(RedeLisboa2012$declive_class3))*100,1)
# summary(RedeLisboa2012$DecliveAbs)
# summary(RedeLisboa2012TM$slopeIST) #este fica com mais falhas!
# summary(RedeLisboa2012$slopeISTdatum)


## Rede rosa 2012 etrs + IST arcgis
RedeLisboa2012dropbox$slopeISTetrs = 100 * slope_raster(RedeLisboa2012dropbox, e=DEMlxIST) # 01m 01s
RedeLisboa2012dropbox$declive_classdropboxR = RedeLisboa2012dropbox$slopeISTetrs %>%
  cut(breaks = c(0, 3, 5, 8, 10, 20, Inf),
      labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
      right = F) 
RedeLisboa2012dropbox$declive_classdropbox = RedeLisboa2012dropbox$Avg_Slope %>%
  cut(breaks = c(0, 3, 5, 8, 10, 20, Inf),
      labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
      right = F) 


### Comparações
RASTER = rbind("NASA" = res(DEMNASAlx), "IST" = res(DEMlxIST))
RASTER[,1]

SEGMENTOS = rbind("Dados Abertos CML" = nrow(RedeLisboa_dadosabertos),
                  "Dados OSM" = nrow(RedeOSM),
                  "Dados OSM limpos" = nrow(RedeOSMlimpa),
                  "Rede 2012" = nrow(RedeLisboa2012),
                  "Rede 2012 dropbox" = nrow(RedeLisboa2012dropbox))
SEGMENTOS

RESUMO = rbind("Dados Abertos CML + NASA" = summary(RedeLisboa_dadosabertos$slopeNASA),
               "Dados OSM  + NASA" = summary(RedeOSM$slopeNASA),
               "Dados OSM limpos  + NASA" = summary(RedeOSMlimpa$slopeNASA),
               "Dados Abertos CML + IST" = summary(RedeLisboa_dadosabertosTM$slopeIST),
               "Dados OSM  + IST" = summary(RedeOSMtm$slopeIST),
               "Dados OSM limpos  + IST" = summary(RedeOSMlimpaTM$slopeIST),
               "Rede 2012 + IST" = summary(RedeLisboa2012$slopeISTdatum),
               "Rede 2012 + IST arcgis" = summary(RedeLisboa2012$DecliveAbs),
               "Rede 2012 + IST dropbox" = summary(RedeLisboa2012dropbox$slopeISTetrs),
               "Rede 2012 + IST arcgis dropbox" = summary(RedeLisboa2012dropbox$Avg_Slope))
RESUMO

CLASSES = rbind("Dados Abertos CML + NASA" = round(prop.table(table(RedeLisboa_dadosabertos$declive_class))*100,1),
                "Dados OSM  + NASA" = round(prop.table(table(RedeOSM$declive_class))*100,1),
                "Dados OSM limpos  + NASA" = round(prop.table(table(RedeOSMlimpa$declive_class))*100,1),
                "Dados Abertos CML + IST"= round(prop.table(table(RedeLisboa_dadosabertosTM$declive_class))*100,1),
                "Dados OSM  + IST" = round(prop.table(table(RedeOSMtm$declive_class))*100,1),
                "Dados OSM limpos  + IST" = round(prop.table(table(RedeOSMlimpaTM$declive_class))*100,1),
                "Rede 2012 + IST" = round(prop.table(table(RedeLisboa2012$declive_class3))*100,1),
                "Rede 2012 + IST arcgis" = round(prop.table(table(RedeLisboa2012$declive_class))*100,1),
                "Rede 2012 + IST dropbox" = round(prop.table(table(RedeLisboa2012dropbox$declive_classdropboxR))*100,1),
                "Rede 2012 + IST arcgis dropbox" = round(prop.table(table(RedeLisboa2012dropbox$declive_classdropbox))*100,1)
                )
CLASSES

cor(RedeLisboa2012old$slopeISTetrs,RedeLisboa2012old$Avg_Slope)
cor(RedeLisboa2012dropbox$slopeISTetrs, RedeLisboa2012dropbox$Avg_Slope)

# mapview::mapview(RedeLisboa2012[RedeLisboa2012$declive_class3=="0-3: plano" |
#                                   RedeLisboa2012$declive_class3==">20: impossível",], zcol= "declive_class3" )
# 
# mapview::mapview(RedeOSMlimpaTM[RedeOSMlimpaTM$declive_class=="0-3: plano" |
#                                   RedeOSMlimpaTM$declive_class==">20: impossível",14], zcol= "declive_class" )

par(mfrow=c(1,2))
plot(RedeLisboa2012[RedeLisboa2012$declive_class3=="0-3: plano" |
                   RedeLisboa2012$declive_class3==">20: impossível",33])
plot(RedeOSMlimpaTM[RedeOSMlimpaTM$declive_class=="0-3: plano" |
                    RedeOSMlimpaTM$declive_class==">20: impossível",14])


# tentativa com terra::
# DEMlxISTterra = terra::rast(DEMlxIST) #para comparar se melhora a performance
# DEMNASAlxterra = terra::rast(DEMNASAlx)
# RedeLisboa_dadosabertosTM$slopeISTerra = slope_raster(RedeLisboa_dadosabertosTM, e = DEMlxISTterra,  terra = T) # 04m 53s
# RedeLisboa_dadosabertos$slopeNASAterra = slope_raster(RedeLisboa_dadosabertos, e = DEMNASAlxterra,  terra = T) # 05m 30s

## tentar fazer smoth das linhas do shp da CML




# 
# 
# RedeViaria$declive_class =  RedeViaria$declive %>% 
#   cut(
#     breaks = c(0, 3, 5, 8, 10, 20, Inf),
#     labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
#     right = F
#   ) 
# round(prop.table(table(RedeViaria$declive_class))*100,1)
# 
# 





# RedeLisboa_dadosabertosTM$slopeCML = slope_raster(RedeLisboa_dadosabertosTM, e = DEMcml) #62 segundos porto, 58 segundos lisboa, 7min lisboa CML
# RedeLisboa_dadosabertosTM$slopeCML = slope_raster(RedeLisboa_dadosabertosTM, e = DEMcmlTerra, terra = T)
# RedeLisboa_dadosabertos$slopeNASA = slope_raster(RedeLisboa_dadosabertos, e = DEMNASAlx) #62 segundos porto, 58 segundos lisboa
# RedeLisboa_dadosabertos$slopeNASA = slope_raster(RedeLisboa_dadosabertos, e = DEMNASAlxTerra, terra = T) #4m37s
# RedeOSM$slopeNASA = slope_raster(RedeOSM, e=DEMNASAlx) #39seg
# RedeOSMtm$slopeIST = slope_raster(RedeOSMtm, e=DEMlisboa) #37seg > ESTE ESTÁ ÓPTIMO! Mas é preciso algumas vias de 1º grau
# RedeOSMlimpa$slopeIST = slope_raster(RedeOSMlimpa, e=DEMlisboa) #38s > mas vendo bem, tem falhas grandes marcando com declives elevados ruas planoas
# 

# raster::plot(DEMNASAlx)
# plot(sf::st_geometry(Rede23k), add = TRUE)
# Rede23k$slopeNASA = slope_raster(Rede23k, e = DEMNASAlxTerra, terra = T) #weired results
# Rede23k$slopeNASAnoTerra = slope_raster(Rede23k, e = DEMNASAlx) 

#declive em percentagem
# RedeViaria$declive = RedeViaria$slope*100
# summary(RedeViaria$declive)
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

# summary(RedeViaria$Avg_Slope) #bate quase certo com o nao projectado
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 0.000   1.444   3.165   4.440   5.807  79.608 

#classes
# RedeViaria$declive_class =  RedeViaria$declive %>% 
#   cut(
#     breaks = c(0, 3, 5, 8, 10, 20, Inf),
#     labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
#     right = F
#   ) 
# round(prop.table(table(RedeViaria$declive_class))*100,1)
# # Porto
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

# RedeViaria$declive_classOriginal =  RedeViaria$Avg_Slope %>% #mudar para declive
#   cut(
#     breaks = c(0, 3, 5, 8, 10, 20, Inf),
#     labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
#     right = F
#   ) 
# round(prop.table(table(RedeViaria$declive_classOriginal))*100,1)
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
st_write(RedeLisboa2012dropbox[,c(2,5:11,17:20,23:34,38,38,43,44,57,52,56,54,55,53)], "shapefiles/RedeViariaLisboa2012_declives_etrs89.gpkg", append=T)


mapview::mapview(RedeLisboa2012dropbox, zcol="declive_classdropboxR")
