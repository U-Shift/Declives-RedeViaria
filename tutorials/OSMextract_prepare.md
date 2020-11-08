OSM extract and prepare
================

Usando conjunto de dados abertos, é possível produzir um mapa de declives da rede viária para qualquer localidade em Portugal.
Neste tutorial vou descrever como:

1.  Fazer download da rede do Open Street Maps
2.  Seleccionar e Limpar a rede
3.  Exportar para se produzir o mapa de declives

Fazer download da rede do Open Street Maps
------------------------------------------

Para este passo é necessário usar o [package](https://itsleeds.github.io/osmextract/articles/osmextract.html) `osmextract` que faz download do ficheiro mais actual do [**OpenStreetMap**](https://www.openstreetmap.org/) que esteja disponível em <https://download.geofabrik.de/index.html>
Para Portugal, o ficheiro disponível tem **218MB**. O `osmextract` faz o donwload por região disponível, e converte para o formato `geopackage` (ou .gpkg) (equivalente ao `shapefile`, mas nativo do QGIS).

``` r
# remotes::install_github("ITSLeeds/osmextract")
# remotes::install_github("ropensci/stplanr")
library(osmextract)
library(sf)
library(tidyverse)

portugal_osm = oe_get("Portugal", provider = "geofabrik", stringsAsFactors = FALSE, quiet = FALSE, force_download = TRUE, force_vectortranslate = TRUE) #218 MB!
```

O ficheiro fica guardado na pasta de ficheiros temporários, pode-se mover para outra localização, caso necessário não se ter de fazer donwload novamente.
Para ler o ficheiro `gpkg` já passado para outra directoria:

``` r
portugal_osm = st_read("OSM/geofabrik_portugal-latest.gpkg", layer= "lines")
```

O openStreet maps classifica as vias em varias categorias. Vamos apenas seleccionar as seguintes, deixando de fora os caminhos pedonais, que são aqueles que cortam jardins, por exemplo.
Se quiseremos uma rede mais *leve*, podemos escolher apenas as de categoria primary, secondary e tertiary (e respectivos links), que correspondem aos níveis mais elevados de uma rede viária.

> muitas vezes as vias estão mal classificadas no OSM. Pode-se [ir lá editar](https://www.openstreetmap.org/edit) (é um mapa colaborativo!). Neste caso optei por seleccionar também as `unclassified`.

``` r
table(portugal_osm$highway)
portugal_osm_filtered = portugal_osm %>% 
  dplyr::filter(highway %in% c('primary', "primary_link", 'secondary',"secondary_link", 'tertiary', "tertiary_link", "trunk", "trunk_link", "residential", "cycleway", "living_street", "unclassified", "motorway", "motorway_link", "pedestrian", "steps", "service", "track"))
```

Seleccionar e limpar a rede
---------------------------

#### Seleccionar o Concelho

Imaginando que queremos produzir um mapa de declives para todo o Concelho da **Guarda**.
Na pasta [shapefiles](https://github.com/U-Shift/Declives-RedeViaria/tree/main/shapefiles) encontra-se um ficheiro com todos os concelhos de Portugal continental (ver como foi produzido a partir da Carta Administrativa Oficial de Portugal em [/code](https://github.com/U-Shift/Declives-RedeViaria/blob/main/code/CAOPconcelhos.R)).

``` r
Concelhos = st_read("shapefiles/ConcelhosPT.gpkg")
Concelhos$Concelho  #Ver lista com os nomes dos concelhos disponíveis
ConcelhoLimite = Concelhos %>% filter(Concelho == "GUARDA") #aqui podemos escolher outro qualquer
```

#### Cortar a rede de Portugal com o limite do concelho

Aplica-se um buffer de 100m (pode ser mais) para aquelas vias que muitas vezes estão mesmo no limite do concelho não ficarem cortadas.

``` r
library(stplanr)
osm_lines_Concelho = st_crop(portugal_osm_filtered, ConcelhoLimite) #corta nos bounding boxes, para não ficar tão pesado na operação seguinte
RedeOSM_Concelho = st_intersection(osm_lines_Concelho, geo_buffer(ConcelhoLimite, dist=100)) #clip com um buffer de 100m
```

#### Limpar os segmentos que não estão ligados à rede

Queremos excluir aqueles segmentos que não estão ligados à rede principal. Muitas vezes têm a topologia mal definida (se bem que no OSM a rede já vem corrigida), ou com o filtro inicialmente aplicado perderam-se ligações. este exemplo da rede do Porto mostra aqueles que queremos excluir.
![](figs/DisconnectedIslands.PNG)

Para isso usamos a função [`rnet_group()`](https://docs.ropensci.org/stplanr/reference/rnet_group.html), do package `stplanar`, que vai avaliar a conectividade de cada segmento e atribuir um grupo (uma espécie de cluster). Depois só temos de filtrar aqueles segmentos que fazem parte do grupo principal, que será o que tem mais segmentos ligados.

> Muitas vezes há ciclovias que não estão ligadas à rede, sendo apenas segmentos "soltos".

Isto é um workaround de limpeza da rede, descartando aqueles que não estão ligados. Também podemos abrir no QGIS, correr o pluggin [Disconnected Islands](http://plugins.qgis.org/plugins/disconnected-islands/), e ver em que grupos estão os segmentos, editando as suas ligações se for o caso.

``` r
RedeOSM_Concelho$group = stplanr::rnet_group(RedeOSM_Concelho)
# table(RedeOSM_Concelho$group)
# plot(RedeOSM_Concelho["group"])

RedeOSM_Concelho_clean = RedeOSM_Concelho %>% filter(group == 1) #o que tem mais segmentos
# mapview::mapview(RedeOSM_Concelho_clean) #verificar
```

Todos estes processos fizeram com que o tipo de geometria da rede *limpa* seja `GEOMETRY` ou `MULTILINESTRING`. Como o `slopes` só funciona com `LINESTRING`, vamos novamente pegar na rede OSM original e filtrar pelos `id` que ficaram na rede *limpa*. Poderiamos usar o `sf::st_cass(..., "LINESTRING")`, mas isso iria também partir a rede em todas as intersessções que encontrasse.

``` r
st_geometry(RedeOSM_Concelho_clean)
RedeViaria = portugal_osm_filtered %>% filter(osm_id %in% RedeOSM_Concelho_clean$osm_id) #ficar apenas os segmentos da rede limpa
st_geometry(RedeViaria) #verificar se são LINESTRING
```

#### Resolver interseccões

Por um lado, queremos que os segmentos se partem nos seus nós (`nodes`), para termos um declive memlhor aproximado. Um segmento muito longo irá ter um declive médio atribuído, mas um segmento muito longo pode ser partido nos seus nós e ter um declive próprio em cada parte do segmento.
Vejamos este exemplo da Rua D. João V (Porto), antes e após se partir aquele troço nos seus vértices internos:

<img src="figs/SplitLines_nodes.PNG?raw=true" alt="sem partir" style="width:40.0%" /> <img src="figs/SplitLines_nodes_stplanr.PNG?raw=true" alt="depois de partir" style="width:40.0%" />

Por outro lado, não queremos que sejam criados *nodes* artificiais nos sítios onde duas linhas se cruzam, mesmo tendo elas diferentes níveis **z**, os tais *brunels*: *bridges and tunnels*. O `v.clean` do GRASS (QGIS) acaba por parti-los :/ .O OSM representa as pontes e túneis como linhas que não se interssectam, e convém preservar esse formato.
A função [`rnet_breakup_vertices`]() parte os segmentos nos seus vértices internos, preservando os *brunels*. Irá também aumentar o número de segmentos presentes na rede.

``` r
nrow(RedeViaria)
RedeViaria = stplanr::rnet_breakup_vertices(RedeViaria)
nrow(RedeViaria)
```

Exemplo da rede do Porto, após esta função:
<img src="figs/SplitLines_nodes_stplanrBridge.PNG?raw=true" alt="por baixo da ponte" style="width:40.0%" /> <img src="figs/SplitLines_nodes_stplanrBridge2.PNG?raw=true" alt="nó do viaduto" style="width:40.0%" />

Exportar para se produzir o mapa de declives
--------------------------------------------

Depois disto, a rede está pronta para se criar o mapa de declives!

``` r
library(raster)
library(geodist)
library(slopes)
library(tmap)

DEM = raster("raster/GuardaNASA_clip.tif") #ou outro que tenha sido descarregado do SRTM
class(DEM)
summary(values(DEM))
res(DEM) #verificar a resolução deste raster
raster::plot(DEM)
plot(sf::st_geometry(RedeViaria), add = TRUE) #verificar se coincidem

RedeViaria$slope = slope_raster(RedeViaria, e = DEM) #19s
RedeViaria$declive = RedeViaria$slope*100
RedeViaria$declive_class = RedeViaria$declive %>%
  cut(
    breaks = c(0, 3, 5, 8, 10, 20, Inf),
    labels = c("0-3: plano", "3-5: leve","5-8: médio", "8-10: exigente", "10-20: terrível", ">20: impossível"),
    right = F)
round(prop.table(table(RedeViaria$declive_class))*100,1)
summary(RedeViaria$declive)
# st_write(RedeViaria, "shapefiles/RedeViariaGuarda_declives.gpkg", append=F)

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
    id = "name" #se o computador não conseguir exportar, por falta de memória, apagar esta linha.
  )
# mapadeclives
```

E exportar com mapa interactivo em html:

``` r
tmap_save(mapadeclives, "DeclivesGuarda.html")
```

Resultado para a Guarda pode ser visto em <http://web.tecnico.ulisboa.pt/~rosamfelix/gis/declives/DeclivesGuarda.html>

> 50% das vias têm mais de 5.1% de inclinação!
> 23.4% das vias são planas ou quase planas, e 48% são cicláveis (&lt; 5%).
