# Ficar com uma shapefile dos Concelhos de Portugal continental

# Download da Carta Administrativa Oficial de Portugal em: http://mapas.dgterritorio.pt/ATOM-download/CAOP-Cont/Cont_AAD_CAOP2019.zip

library(dplyr)
library(sf)

CAOP = st_read("D:/GIS/Cont_AAD_CAOP2017/Cont_AAD_CAOP2019.shp")
colnames(CAOP)
CAOP = CAOP[,c("Concelho","geometry")]

ConcelhosPT = CAOP %>% group_by(Concelho) %>% summarise()
ConcelhosPT = st_transform(ConcelhosPT, 4326)

mapview::mapview(ConcelhosPT) #verificar se está ok

st_write(ConcelhosPT, "shapefiles/ConcelhosPT.gpkg", append=F)
