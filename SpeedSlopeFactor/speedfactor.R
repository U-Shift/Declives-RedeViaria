#Speed - slope factor
#Aim: make a function to adjust cycling speed reagrding the gradient of the segment, 
#based on fidings from R Félix (2012), Gestão da Mobilidade Urbana em Bicicleta: o caso de Lisboa - chapter 4.2.1.

#import libraries
library(tidyverse)
library(sf)
library(slopes)

#use example from slopes()
DATA = slopes::lisbon_road_segments
DATA$slope = slope_raster(DATA, dem = dem_lisbon_raster)
DATA$slope_class = DATA$slope %>% 
  cut(
    breaks = c(0, .03, .05, .08, .10, .20, Inf),
    labels = c("0-3: flat", "3-5: mild", "5-8: medium", "8-10: hard", "10-20: extreme", ">20: impossible"),
    right = F
  )
tmap_mode("view")
tm_shape(DATA) +
  tm_lines(
    col = "slope_class",
    palette = palredgreen, #palete de cores
    lwd = 2) #espessura das linhas
    

DATA$length = st_length(DATA)


#direction of slope, for the purpose of the example
DATA$direction = "FT"
DATA$direction[(DATA$z0 - DATA$z1) < 0] = "TF"

mapview::mapview(DATA["direction"])

DATA$slope[DATA$direction == "TF"] = -(DATA$slope[DATA$direction == "TF"])



#apply a speed factor

g = function(slope, length){
  ifelse((slope > 3 & slope <= 5 & length > 120), 6, 
    ifelse((slope > 5 & slope <= 8 & length > 60), 5, 
      ifelse((slope > 8 & slope <= 10 & length > 30), 4.5,
        ifelse((slope > 10 & slope <= 13 & length > 15), 4,
               7))))
}

plot(g) #is there a way to make it continuous?

# speedfactor = function(slope, length, g){
#    ifelse((slope < -30), 1.5, #try with 1.5 and -30 instead of 0.75 and -25
#     ifelse(slope < 0, 1+(0.7/13)*2*slope + 0.7/(13^2)*slope^2, #try with 0.7 instead of 0.9
#        ifelse((slope > 20), 10,
#           ifelse((slope >=0 & slope <= 20), 1+(slope/g)^2,
#               ifelse((slope >13 & length >15), 10,
#                     # ifelse((slope >18 & length > 120), 10,
#                     #        ifelse((slope >8 & length > 60), 10,
#                     #               ifelse((slope >5 & length > 120), 10,
# 
#                    NA)))))
#   # )))
#   # if (speedfactor > 10){speedfactor = 10 }
# }

speedfactor = function(slope, length, g) {
  ifelse((ifelse((slope < -30),
                 1.5,
                 ifelse(
                   slope < 0,
                   1 + (0.7 / 13) * 2 * slope + 0.7 / (13 ^ 2) * slope ^ 2,
                   ifelse((slope > 20), 10,
                          ifelse((slope >= 0 &
                                    slope <= 20), 1 + (slope / g) ^ 2,
                                 ifelse((slope > 13 &
                                           length > 15), 10,
                                        NA)
                          ))
                 )
  )) > 10, 10, ifelse((slope < -30),
                      1.5,
                      ifelse(
                        slope < 0,
                        1 + (0.7 / 13) * 2 * slope + 0.7 / (13 ^ 2) * slope ^ 2,
                        ifelse((slope > 20), 10,
                               ifelse((slope >=
                                         0 & slope <= 20), 1 + (slope / g) ^ 2,
                                      ifelse((slope >
                                                13 & length > 15), 10,
                                             NA)
                               ))
                      )
  ))
}


speedfactor(slope =12, length=15, g=g(slope, length))
speedfactor(slope =19, length=120)


curve(expr = speedfactor(slope = x, g= 7, length = 120), from = -35, to = 25, log="y", col="blue", lwd=3, xlab="slope [%]", ylab="speed factor")
curve(expr = speedfactor(slope = x, g= 4, length = 120), from = 10, to = 25, log="y", col="purple", lwd=2, lty=5, add = T)
curve(expr = speedfactor(slope = x, g= 4.5, length = 120), from = 8, to = 25, log="y", col="grey", lwd=2, lty=4, add = T)
curve(expr = speedfactor(slope = x, g= 5, length = 120), from = 5, to = 25, log="y", col="green", lwd=2, lty=3, add = T)
curve(expr = speedfactor(slope = x, g= 6, length = 120), from = 3, to = 25, log="y", col="red", lwd=2, lty=2, add = T)
curve(expr = speedfactor(slope = x, g= 7, length = 120), from = -35, to = 25, log="y", col="blue", lwd=2, add = T)
abline(h=1, v=0, lty=3)
title(main = "Slope-Speed function")
legend(-30, 8, legend=c("speed factor (base)", "slope >3%, length >120 m", "slope >5%, length >60 m",
                        "slope >8%, length >30 m", "slope >10%, length >15 m"),
       col=c("blue", "red", "green", "grey", "purple"), lty=1:2, cex=0.9,
       lwd=c(3,2,2,2,2),
       box.lty=0)


slope = 100*DATA$slope
length = units::drop_units(DATA$length)
g = g(slope, length)

spf = speedfactor(slope, length, g)

plot(spf, log="y")
DATA$speedfactor = spf


#set speed
speed = 16 #set here in km/h
# speed = speed/3.6 #convert to m/s

DATA$speed = speed / DATA$speedfactor
DATA$time = length / DATA$speed*3.6

mapview::mapview(DATA["speed"])
mapview::mapview(DATA["time"])


