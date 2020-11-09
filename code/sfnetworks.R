# https://www.r-spatial.org/r/2019/09/26/spatial-networks.html

sf_to_tidygraph = function(x, directed = TRUE) {
  
  edges <- x %>%
    mutate(edgeID = c(1:n()))
  
  nodes <- edges %>%
    st_coordinates() %>%
    as_tibble() %>%
    rename(edgeID = L1) %>%
    group_by(edgeID) %>%
    slice(c(1, n())) %>%
    ungroup() %>%
    mutate(start_end = rep(c('start', 'end'), times = n()/2)) %>%
    mutate(xy = paste(.$X, .$Y)) %>% 
    mutate(nodeID = group_indices(., factor(xy, levels = unique(xy)))) %>%
    select(-xy)
  
  source_nodes <- nodes %>%
    filter(start_end == 'start') %>%
    pull(nodeID)
  
  target_nodes <- nodes %>%
    filter(start_end == 'end') %>%
    pull(nodeID)
  
  edges = edges %>%
    mutate(from = source_nodes, to = target_nodes)
  
  nodes <- nodes %>%
    distinct(nodeID, .keep_all = TRUE) %>%
    select(-c(edgeID, start_end)) %>%
    st_as_sf(coords = c('X', 'Y')) %>%
    st_set_crs(st_crs(edges))
  
  tbl_graph(nodes = nodes, edges = as_tibble(edges), directed = directed)
  
}

library(tidyverse)
library(sf)
library(stplanr)
library(osmdata)
library(igraph)
library(tidygraph)

PUORTO <- opq(bbox =  st_bbox(PortoLimite)) %>% 
  add_osm_feature(key = 'highway') %>% 
  osmdata_sf() %>% 
  osm_poly2line()
PUORTO <- PUORTO$osm_lines %>% 
  select(highway)
PUORTO
ggplot(data = PUORTO) + geom_sf()


LUISBOA <- opq(bbox =  st_bbox(LisboaLimite)) %>% 
  add_osm_feature(key = 'highway') %>% 
  osmdata_sf() %>% 
  osm_poly2line()
LUISBOA <- LUISBOA$osm_lines %>% 
  select(highway)



PUORTO = PUORTO %>% filter(rownames(PUORTO) %in% RedeOSM_Porto_clean$osm_id) #pegar apenas as da shape limpa no qgis

PUORTOnwt = sf_to_tidygraph(PUORTO, directed = T)


graph <- PUORTOnwt %>%
  activate(edges) %>%
  mutate(length = st_length(geometry))
graph


edgesSF = graph %>%
  activate(edges) %>%
  as_tibble() %>%
  st_as_sf()

nodesSF = graph %>%
  activate(nodes) %>%
  as_tibble() %>%
  st_as_sf()

ggplot() +
  geom_sf(data = edgesSF) + 
  geom_sf(data = nodesSF, size = 0.5)

st_write(edgesSF, "edges_porto.shp")
st_write(nodesSF, "nodes_porto.shp")


teste = stplanr::rnet_breakup_vertices(edgesSF)
st_write(teste, "edges_porto_clean.shp")
#acho que funcionou, apesar de criar bastante mais edges! e manteve o linestring!!


# #QGIS 
# separate brunels (bridges and tunnels)
# v.clean break lines at intersections
# put them together again
# 
# #Arcgis
# planerize lines (all lines)
# or Arc Topology > detect and fix all intersections





#uma vez deu...

RedeOSM_PortoNETWORK = RedeOSM_Porto %>% filter(osm_id %in% RedeOSM_Porto_clean$osm_id)
RedeOSM_PortoNETWORK = st_cast(RedeOSM_PortoNETWORK, "LINESTRING")

# RedeOSM_PortoNETWORK <- RedeOSM_PortoNETWORK$osm_lines %>%
#   select(highway)

PortoSN = sf_to_tidygraph(RedeOSM_PortoNETWORK, directed = T)
PortoSN

graph <- PortoSN %>%
  activate(edges) %>%
  mutate(length = st_length(geometry))

graph

graph <- graph %>%
  activate(nodes) %>%
  mutate(degree = centrality_degree()) %>%
  mutate(betweenness = centrality_betweenness(weights = length)) %>%
  activate(edges) %>%
  mutate(betweenness = centrality_edge_betweenness(weights = length))

ggplot() +
  geom_sf(data = graph %>% activate(edges) %>% as_tibble() %>% st_as_sf(), aes(col = betweenness, size = betweenness)) +
  scale_colour_viridis_c(option = 'inferno') +
  scale_size_continuous(range = c(0,4))

resumo = graph %>%
  activate(edges) %>%
  as_tibble() %>%
  st_as_sf() %>%
  group_by(highway) %>%
  summarise(length = sum(length))

resumo

