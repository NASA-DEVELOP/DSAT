# global.R
# global variables for both ui.R and server.R
require(shiny)    #web interface
require(raster)   #raster processing
require(leaflet)  #web mapping
require(rgdal)    #geospatial library
require(SPEI)     #for SPI calculation
require(reshape2) #data processing
require(zoo)      #dates
require(ggplot2)  #plotting
require(shinyjs)  #resetting purposes
require(V8)       #for shinyjs

# get current year
currYear <<- as.numeric(format(Sys.time(), format="%Y"))

# read for plotting
agencies <<- readOGR("data/visualize/shapefile/agency.shp", "agency")
chapters <<- readOGR("data/visualize/shapefile/chapter.shp", "chapter")
eco3 <<- readOGR("data/visualize/shapefile/eco3.shp", "eco3")
eco4 <<- readOGR("data/visualize/shapefile/eco4.shp", "eco4")
watershed <<- readOGR("data/visualize/shapefile/water_sheds.shp", "water_sheds")
cities <<- read.csv("data/visualize/citymarkers.csv")

agenciesProc <<- readOGR("data/process/shapefile/agency.shp", "agency")
chaptersProc <<- readOGR("data/process/shapefile/chapter.shp", "chapter")
eco3Proc <<- readOGR("data/process/shapefile/eco3.shp", "eco3")
eco4Proc <<- readOGR("data/process/shapefile/eco4.shp", "eco4")
watershedProc <<- readOGR("data/process/shapefile/water_sheds.shp", "water_sheds")



##### for ui #####
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

# Define the js method that resets the page
jsResetCode <- "shinyjs.reset = function() {history.go();}"
	

source("scripts/spi.r")
source("scripts/zonalspi.r")
source("scripts/downClipCHIRPS.r")
source("scripts/drSevByShp.r")




lab <- c("-3" = "extremely dry \n(-2.00+)",
		 "-2" = "severely dry \n(-1.50 to -1.99)",
		 "-1" = "moderately dry \n(-1.00 to -1.49)",
		 "0" =  "near normal \n(-0.99 to 0.99)",
		 "1" =  "moderately wet \n(1.00 to 1.49)",
		 "2" =  "severely wet \n(1.50 to 1.99)",
		 "3" =  "extremely wet \n(2.00+)")

col <- c("-3" = "#9A0000", 
		 "-2" = "#BC605C", 
		 "-1" = "#DEC0B8", 
		 "0"  = "#F0F0E7", 
		 "1" = "#C1CED9", 
		 "2" = "#638CBE", 
		 "3" = "#054AA3")

leg_col <- c("2" = "#054AA3",
    "1" = "#93afd2",
    "0"  = "#F0F0E7",
    "-1" = "#CB8380", 
    "-2" = "#9A0000")


col_map <- c("#9A0000", "#A82826", "#B6504D", "#C57873", 
			"#D3A09A", "#E1C8C0", "#F0F0E7", "#C8D4DB", "#A1B8D0", 
			"#7A9DC5", "#5381B9", "#2C65AE", "#054AA3")

pal <- colorNumeric(palette=col_map, 
					domain=c(-6, 6),
  					na.color = "transparent")


