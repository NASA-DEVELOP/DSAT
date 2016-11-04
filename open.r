##Open App
setwd("F:/DSAT 2.0")

myPath <- .libPaths()[1]
toInstall <- c("devtools",
               "R.utils",
               "rgdal", 
               "leaflet", 
               "raster",
               "lubridate",
               "zoo",
               "reshape2",
               "SPEI",
               "shiny", 
               "shinyjs", 
               "V8")
for (i in toInstall) {
  install.packages(i, lib=myPath)
  }



# install.packages("devtools")
# install.packages(c("R.utils", 
#                    "rgdal", 
#                    "leaflet", 
#                    "raster",
#                    "lubridate",
#                    "zoo",
#                    "reshape2",
#                    "SPEI",
#                    "shiny", 
#                    "shinyjs", 
#                    "V8"))
# 


source("http://bioconductor.org/biocLite.R")
biocLite("rhdf5")
biocLite()

require(rgdal)
require(leaflet)
require(raster)
require(lubridate)
require(zoo)
require(reshape2)
require(SPEI)
require(shiny)
require(shinyjs)
require(V8)
require(R.utils)

install.packages("ggplot2", dependencies = TRUE)
require(ggplot2)

runApp()
