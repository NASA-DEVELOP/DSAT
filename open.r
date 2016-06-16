##Open App

#call packages
require(rgdal)
require(leaflet)
require(raster)
require(lubridate)
require(zoo)
require(ggplot2)
require(reshape2)
require(SPEI)
require(shiny)

#install packages
install.packages("leaflet")
install.packages("raster")
install.packages("rgdal")
install.packages("SPEI")
install.packages("zoo")
install.packages("reshape2")
install.packages(“ggplot2”, dependencies = TRUE)
install.packages(“Rcpp”)
install.packages("R.utils")

#call and install this specific package
source("https://bioconductor.org/biocLite.R")
biocLite("rhdf5")
biocLite()

#set working directory, call Shiny, and run Shiny app
setwd(“C:/file_name”) 
require(shiny)
runApp() 


