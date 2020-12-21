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
library(tmap)


# ler shapefiles das Redes Viárias
RedePorto = st_read("shapefiles/sentidos_link.shp")
# Reading layer `sentidos_link' from data source `D:\GIS\Porto\sentidos_link.shp' using driver `ESRI Shapefile'
# Simple feature collection with 19854 features and 6 fields
# geometry type:  LINESTRING
# dimension:      XY
# bbox:           xmin: -966257.6 ymin: 5027255 xmax: -950956 ymax: 5034212

#está em coodenadas esféricas, projectar em WGS84
RedePorto = st_transform(RedePorto, 4326) 
st_write(RedePorto, "shapefiles/RedeViariaPorto_wgs84.gpkg") 
class(RedePorto)

RedeLisboa = st_read("https://opendata.arcgis.com/datasets/a557c10e19a44f0e9592c7b63bae8d3b_0.geojson")
summary(RedeLisboa$slope)
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 0.000   1.308   2.985   4.361   5.779  92.500 

#Escolher aqui qual se vai usar
RedeViaria = RedePorto
#RedeViaria = RedeLisboa

#ler raster com altimetria
DEMporto = raster("raster/PortoNASA_clip.tif") #com 27m de resolução
class(DEMporto)
res(DEMporto)
summary(values(DEMporto))
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# -10.00   24.00   72.00   65.87   97.00  178.00 

DEMlisboa = raster("raster/lisbon_north_wgs84.tif") #com 12.8m de resolução
class(DEMlisboa)
res(DEMlisboa)
summary(values(DEMlisboa))

#Escolher aqui qual se vai usar
DEM = DEMporto
#DEM = DEMlisboa

#visualizar
raster::plot(DEM)
plot(sf::st_geometry(RedeViaria), add = TRUE)


#cálculo dos declives por segmento (em abs)
RedeViaria$slope = slope_raster(RedeViaria, e = DEM) #62 segundos

#declive em percentagem
RedeViaria$declive = RedeViaria$slope*100
summary(RedeViaria$declive)
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 0.000   2.176   4.007   5.099   6.795  54.882 

#classes
RedeViaria$declive_class =  RedeViaria$declive %>%
  cut(
    breaks = c(0, 3, 5, 8, 10, 20, Inf),
    labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
    right = F
  ) 
round(prop.table(table(RedeViaria$declive_class))*100,1)
# 0-3: plano       3-5: leve      5-8: médio  8-10: exigente 10-20: terrível >20: impossível 
#   36.6            24.0            21.0             7.2            10.1             1.1 
# stplnr!
# 0-3: plano       3-5: leve      5-8: médio  8-10: exigente 10-20: terrível >20: impossível 
# 34.4            24.0            21.4             7.7            10.8             1.7 


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
    popup.vars = c("Declive: " = "declive",
                   "Classe: " = "declive_class"),
    popup.format = list(digits = 1),
    id = "NAME"
  )
mapadeclives

tmap_save(mapadeclives, "DeclivesPorto.html")

#exportar shapefile com os declives, em formato GeoPackage (QGIS)
#st_write(RedeViaria, "shapefiles/RedeViariaPorto_declives.gpkg", append=T)
#exportar também em kml
st_write(RedePorto, "RedePorto_osm_stplnr.kml")