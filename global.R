# global.R
# global variables for both ui.R and server.R
require(shiny)    #web interface
require(raster)   #raster processing
require(leaflet)  #web mapping
require(rgdal)    #geospatial library
require(SPEI)     #for SPI calculation
require(reshape2) #data processing
require(zoo)    #dates
require(ggplot2)  #plotting

# get current year
currYear <<- as.numeric(format(Sys.time(), format="%Y"))

# get the projected raster images in data/vis folder for visualization
VIZstack <<- stack(list.files("data/visualize/spi", full.names=TRUE))
# VIZstack <<- brick(VIZstack)
PROCstack <<- stack(list.files("data/process/spi", full.names=TRUE))

# read for plotting
agencies <<- readOGR("data/visualize/shapefile/agency.shp", "agency")
chapters <<- readOGR("data/visualize/shapefile/chapter.shp", "chapter")
eco3 <<- readOGR("data/visualize/shapefile/eco3.shp", "eco3")
eco4 <<- readOGR("data/visualize/shapefile/eco4.shp", "eco4")
watershed <<- readOGR("data/visualize/shapefile/water_sheds.shp", "water_sheds")

agenciesProc <<- readOGR("data/process/shapefile/agency.shp", "agency")
chaptersProc <<- readOGR("data/process/shapefile/chapter.shp", "chapter")
eco3Proc <<- readOGR("data/process/shapefile/eco3.shp", "eco3")
eco4Proc <<- readOGR("data/process/shapefile/eco4.shp", "eco4")
watershedProc <<- readOGR("data/process/shapefile/water_sheds.shp", "water_sheds")

## for ui
# additional functions for creating ui

actionButton <- function(inputId, label, 
                         style = "" , 
                         additionalClass = "", 
                         block=FALSE) 
{
  if (style %in% c("primary","info","success","warning","danger","inverse","link")) {
    class.style <- paste("btn",style,sep="-")
  } else class.style = ""
  class <- paste("btn action-button",class.style,additionalClass)
  if(block) class <- paste(class, "btn-block")
  tags$button(id=inputId, type="button", class=class, label)
}

textInputHelp <- function(inputId, label, value = "", help="") 
{
    HTML(paste0(
        '
        <div class="form-group shiny-input-container">
          <label for="', inputId, '">', label , '</label>
          <span class="help-block">', help ,'</span>
          <div class="input-group">
            <input id="', inputId, '" type="text" class="form-control shiny-bound-input" value="', value, '" />
          </div>
        </div>
        '))
}

textInputBT <- function(inputId, buttonID, label, value = "") 
{
    HTML(paste0(
        '
        <div class="form-group shiny-input-container">
          <label for="', inputId, '">', label , '</label>
          <div class="input-group">
            <input id="', inputId, '" type="text" class="form-control shiny-bound-input" value="', value, '" />
            <span class="input-group-btn">
              <button id="', buttonID , '" class="btn btn-default action-button" type="button">Submit</button>
            </span>
          </div>
        </div>
        '))
}

textInputHelpBT <- function(inputId, buttonID, label, value = "", help="") 
{
    HTML(paste0(
        '
        <div class="form-group shiny-input-container">
          <label for="', inputId, '">', label , '</label>
          <span class="help-block">', help ,'</span>
          <div class="input-group">
            <input id="', inputId, '" type="text" class="form-control shiny-bound-input" value="', value, '" />
            <span class="input-group-btn">
              <button id="', buttonID , '" class="btn btn-default action-button" type="button">Submit</button>
            </span>
          </div>
        </div>
        '))
}

#####################
#		Server 		#
#####################
		
source("scripts/spi.r")
source("scripts/zonalspi.r")
source("scripts/downClipGPM.r")
source("scripts/drSevByShp.r")

lab <- c("-3" = "extremely dry",
		 "-2" = "severely dry",
		 "-1" = "moderately dry",
		 "0" =  "near normal",
		 "1" =  "moderately wet",
		 "2" =  "severely wet",
		 "3" =  "extremely wet")

col <- c("-3" = "#9A0000", 
		 "-2" = "#BC605C", 
		 "-1" = "#DEC0B8", 
		 "0"  = "#F0F0E7", 
		 "1" = "#C1CED9", 
		 "2" = "#638CBE", 
		 "3" = "#054AA3")


col_map <- c("#9A0000", "#A82826", "#B6504D", "#C57873", 
			"#D3A09A", "#E1C8C0", "#F0F0E7", "#C8D4DB", "#A1B8D0", 
			"#7A9DC5", "#5381B9", "#2C65AE", "#054AA3")

pal <- colorNumeric(palette=col_map, 
					domain=c(-6, 6),
  					na.color = "transparent")


