library(shiny)    #web interface
library(raster)   #raster processing
library(leaflet)  #web mapping
library(rgdal)    #geospatial library
library(SPEI)     #for SPI calculation
library(reshape2) #data processing

shinyUI(navbarPage("NASA DEVELOP : Navajo Nation Climate", 
					theme="assets/css/bootstrap.min.css", 
	tabPanel("Introduction", 
		includeHTML("intro.html")
	),

	tabPanel("Process Data", fluidPage(
		sidebarLayout(
			sidebarPanel(width=5, h4("Process Data"),
				tags$head(
    			tags$link(rel = "stylesheet", type = "text/css", href = "assets/css/main.css"),
    			tags$link(rel = "stylesheet", type = "text/css", href = "assets/css/leaflet.css"),
    			tags$script(src="assets/js/leaflet.js")
    		),
				p("Select the tabs below to choose how you would like 
					 to process your climate data."),
				tabsetPanel(id='tabset',
					#*****************
					#* Calculate SPI *
					#*****************
					tabPanel("Calculate SPI", wellPanel(
						p("Calculate the Standard Precipitation Index (SPI)
							 by inputting the following parameters."),

						# get startmo, startyr, endyr
						div(class="inputparam",
							selectizeInput("SPI_timescale", 
										   "Time Scale: ", 
										 c("1 month" = 1, 
										   "6 month" = 6, 
										   "12 month" = 12), 12)),

						div(class="inputparam",
							selectizeInput("SPI_startmo", "Starting Month of Data: ", 
													c("Jan"=1, "Feb"=2,  "Mar"=3,  "Apr"=4, 
														"May"=5, "Jun"=6,  "Jul"=7,  "Aug"=8,
														"Sep"=9, "Oct"=10, "Nov"=11, "Dec"=12))),

						div(class="inputparam2",
							selectizeInput("SPI_startyr", "Starting Year of Data: ", 
												seq(from=1900, to=currYear), 1900)),

						div(class="inputparam2",
							selectizeInput("SPI_endyr", "Ending Year of Data: ", 
												seq(from=1900, to=currYear), currYear)),

						# TODO: a reactive thing here for warning on years.
						textInput("SPI_dir", "Folder containing data (full path): ", 
											 tools:::file_path_as_absolute("data/process/precip")),
						# TODO: a reactive thing here checking the directory path
						actionButton("BT_calcSPI", "Calculate SPI", style="info", block=TRUE)
					)),
					#**********************
					#* Summary Statistics *
					#**********************
					tabPanel("Summary Statistics", wellPanel(
						p("Generate zonal statistics (count, mean, max, min, range, 
						   standard deviation) for regions as defined by a given shapefile."),
						# get dir of tifs, shp, and shapefile attribute (dropdown)
						textInput("ZONE_dir", "Folder containing data (full path): ", 
											 tools:::file_path_as_absolute("data/process/spi")),
						# TODO: a reactive block here checking the directory path
						textInputHelpBT("ZONE_shp", 
										"BT_ZoneLoadShp", 
										"Path to polygon shapefile defining zones (full path): ", 
											 		 tools:::file_path_as_absolute("data/process/shapefile/agency.shp"), 
											 		 help="Please ensure two things: [1] you have the corresponding 
											 		 	   .shx and .dbf file witin the same directory. [2] the 
											 		 	   shapefile and rasters share the same spatial 
											 		 	   reference."),
						uiOutput("ZONE_shpLoad")
					)),
					#*********************
					#* Download CHIRPS Data *
					#*********************
					tabPanel("Download CHIRPS Data", wellPanel(
						h4("Fetch CHIRPS and Preprocess it from NASA servers."),
						p("The button below will compare the available CHIRPS data from NASA with 
							the data currently downloaded and residing in the folder data/downloadGPM/raw.
							From this, it will determine if new data needs to be downloaded to update the database. 
							Once the downloads are complete, the script will clip the data to the Navajo Nation 
							study region and be saved in the folder data/downloadGPM/clipped."),
						br(),
						actionButton("BT_downGPM", 
									 "Download Newly Available CHIRPS Precipitation Data", 
									 style="info", 
									 block=TRUE)
						
					))	
				)
			), # end sidebarPanel
			
			mainPanel(width=7, "",
				conditionalPanel(
						condition = "input.tabset=='Calculate SPI'",
						uiOutput("SPI_main")
				),
				conditionalPanel(
						condition = "input.tabset=='Summary Statistics'",
						uiOutput("ZONE_main")
				),
				conditionalPanel(
						condition = "input.tabset=='Download GPM Data'",
						uiOutput("DownGPM_Main")
				)
			)

		) # end SidebarLayout
	)), # end Process Tab Panel (navbar)

	tabPanel("Visualize", 
	  div(
      	tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "assets/css/map.css")
      ),

      leafletOutput("mymap"),
      absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
        draggable = TRUE, top = 75, left = "auto", right = 20, bottom = "auto",
        width = 380, height = "auto",

        h4("Visualize Your Data"),
        textInputHelpBT("VIZ_path", "VIZ_load",
        			   "Path to folder of SPI rasters", 
        			   "data/process/spi", 
        			  	help=""),
   	
   		# selected boundary to display
        selectInput("VIZselectshp", 
        			"Select Boundary", 
        			c(
        			  "Chapters" = "chapters",
        			  "Agencies" = "agencies",
        			  "Watersheds" = "watersheds",
        			  "Eco-Region Level 3" = "eco3",
        			  "Eco-Region Level 4" = "eco4"
        			),
        			selected="agencies"),

        # CHECKBOX
        checkboxGroupInput(inputId="checkControl", 
        				   label="Choose Your Tool", 
        				   choices=c("Time Slide" = "timeSliderChecked", "Plot" = "plotChecked"),
        				   selected = NULL,
        				   inline = TRUE),
        conditionalPanel(
        	condition="input.checkControl.indexOf('timeSliderChecked') != -1",
      		uiOutput("searchDate"),
      		uiOutput("searchDateErrorMsg")
      	),
        actionButton("VIZ_clearRas", "Clear Raster Layer", style = "danger", block=TRUE)
      ),# end control absolute Panel

      #CHECKBOX: this will show the timeslider window. Note the legend is in server.r
      conditionalPanel(condition="input.checkControl.indexOf('timeSliderChecked') != -1",
      	absolutePanel(id = "timeSlide", class = "panel panel-default", fixed = TRUE,
		        draggable = TRUE, top = "auto", left = "auto", right = 20, bottom = 5,
		        width = "800", height = 130,

		        uiOutput("renderDateLabel"),
		        sliderInput("VIZslider", "Select a Raster", 
		        			min=1, 
		        			max=nlayers(VIZstack), 
		        			value=1,
		        			step=1, 
		        			animate=animationOptions(interval = 700),
		        			pre="Month "
				)

      	)
      ),

      #CHECKBOX: this will show the plotted chart window.
      conditionalPanel(condition="input.checkControl.indexOf('plotChecked') != -1",
      	absolutePanel(id = "timeSlide", class = "panel panel-default", fixed = TRUE,
		        draggable = TRUE, top = "auto", left = 5, right = "auto", bottom = -10,
		        width = 580, height = 370,
		        uiOutput("plt")  
      	)
      )
      

    )
	) #tab Panel Visualize end

))
