#declives da rede viária do Porto

#importar packages
library(sf)
library(raster)
library(geodist)
library(slopes)
library(tmap)


# ler shapefile
RedeViaria = st_read("shapefiles/sentidos_link.shp")
# Reading layer `sentidos_link' from data source `D:\GIS\Porto\sentidos_link.shp' using driver `ESRI Shapefile'
# Simple feature collection with 19854 features and 6 fields
# geometry type:  LINESTRING
# dimension:      XY
# bbox:           xmin: -966257.6 ymin: 5027255 xmax: -950956 ymax: 5034212

#está em coodenadas esféricas, projectar em WGS84
RedeViaria = st_transform(RedeViaria, 4326) 
st_write(RedeViaria, "shapefiles/RedeViariaPorto_wgs84.gpkg") 
class(RedeViaria)

#ler raster com altimetria
DEM = raster("raster/PortoNASA_clip.tif")
class(DEM)
summary(values(DEM))
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# -10.00   24.00   72.00   65.87   97.00  178.00 

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
RedeViaria$declive_class = ">20: impossível"
RedeViaria$declive_class[RedeViaria$declive<=20] = "10-20: terrível"
RedeViaria$declive_class[RedeViaria$declive<=10] = "8-10: exigente"
RedeViaria$declive_class[RedeViaria$declive<=8] = "5-8: médio"
RedeViaria$declive_class[RedeViaria$declive<=5] = "3-5: leve"
RedeViaria$declive_class[RedeViaria$declive<=3] = "0-3: plano"
RedeViaria$declive_class = factor(RedeViaria$declive_class, levels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"))

round(prop.table(table(RedeViaria$declive_class))*100,1)
# 0-3: plano       3-5: leve      5-8: médio  8-10: exigente 10-20: terrível >20: impossível 
#   36.6            24.0            21.0             7.2            10.1             1.1 

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

tmap_save(mapadeclives, "DeclivesPorto.html", append = T)

#exportar shapefile com os declives, em formato GeoPackage (QGIS)
#st_write(RedeViaria, "RedeViariaPorto_declives.gpkg", append=T)