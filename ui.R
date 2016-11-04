library(shiny)    #web interface
library(raster)   #raster processing
library(leaflet)  #web mapping
library(rgdal)    #geospatial library
library(SPEI)     #for SPI calculation
library(reshape2) #data processing
library(shinyjs)  #refreshing purposes



shinyUI(navbarPage("NASA DEVELOP : Navajo Nation Climate", 
					id="panels",
					theme="assets/css/bootstrap.min.css",
	# INTRODUCTION tab (across top)
	tabPanel("Introduction", id="intropg",
		includeHTML("intro.html")
	),
	
	# PROCESS DATA tab (across top)
	tabPanel("Process Data", id="processpg",
	 fluidPage(
		useShinyjs(),
		inlineCSS(list(.grey="style: default", .danger="style: danger")),
		extendShinyjs(text=jsResetCode),

		sidebarLayout(
			sidebarPanel(width=5, h4("Process Data"),
				tags$head(
    			tags$link(rel="stylesheet", type="text/css", href="assets/css/main.css"),
    			tags$link(rel="stylesheet", type="text/css", href="assets/css/leaflet.css"),
    			tags$script(src="assets/js/leaflet.js")),

				p("Select the tabs below to choose how you would like 
					 to process your climate data."),
				tabsetPanel(id='tabset',
					#************************
					#* Download CHIRPS Data *
					#************************
					tabPanel("Download CHIRPS Data", wellPanel(
						h4("Fetch CHIRPS and Preprocess it from NASA servers"),
						p("The button below will compare the available CHIRPS data from NASA with 
							the data currently downloaded and residing in the folder data/downloadCHIRPS/raw.
							From this, it will determine if new data needs to be downloaded to update the database."), 
						p("Once the downloads are complete, the script will clip the data to the Navajo Nation 
							study region and be saved in the folder data/downloadCHIRPS/clipped. 
							An additional copy of the clipped data will be placed in the folder data/process/precip
							for subsequent calculations of SPI."),
						br(),
						actionButton("BT_downCHIRPS", 
							"Download Newly Available CHIRPS Precipitation Data", 
							style="info", 
							block=TRUE)	
					)),

					
					#*****************
					#* Calculate SPI *
					#*****************
					tabPanel("Calculate SPI", wellPanel(
						p("Calculate the Standard Precipitation Index (SPI)
							 by inputting the following parameters."),

						# timescale
						div(class="inputparam",
							selectizeInput("SPI_timescale", 
								"Time Scale: ", 
								c("1 month"=1, 
									"6 month"=6, 
									"12 month"=12), 
								12)),

						# start (and end) month
						div(class="inputparam",
							selectizeInput("SPI_startmo", 
								"Starting Month of Data: ", 
								c("Jan"=1, "Feb"=2,  "Mar"=3,  "Apr"=4, 
									"May"=5, "Jun"=6,  "Jul"=7,  "Aug"=8,
									"Sep"=9, "Oct"=10, "Nov"=11, "Dec"=12))),

						# start yr
						div(class="inputparam2",
							selectizeInput("SPI_startyr", 
								"Starting Year of Data: ", 
								seq(from=1981, to=currYear), 
								1981)),

						# end yr
						div(class="inputparam2",
							selectizeInput("SPI_endyr", 
								"Ending Year of Data: ", 
								seq(from=1981, to=currYear), 
								currYear)),

						actionButton("BT_calcSPI", 
							"Calculate SPI", 
							style="info", 
							block=TRUE)
					)),


					#**********************
					#* Summary Statistics *
					#**********************
					tabPanel("Summary Statistics", wellPanel(
						p("Generate zonal statistics (count, mean, max, min, range, 
						   standard deviation) for regions as defined by a given shapefile."),

						# folder options for SPI data 
						selectInput("ZONE_dir", 
							"Select SPI data: ", 
							c("",
								list.files(tools:::file_path_as_absolute("data/process/spi"))),
							selected=NULL,
							multiple=FALSE),
						
						# folder options for boundary shapefile 
						selectInput("ZONE_shp", 
							"Select boundary shapefile: ", 
							c("",
								list.files(tools:::file_path_as_absolute("data/process/shapefile"), pattern="\\.shp$")),
							selected="agency.shp",
							multiple=FALSE),

						uiOutput("ZONE_shpLoad")
					))	
				) # end tabsetPanel
			), # end sidebarPanel
		
			mainPanel(width=7, "",
				conditionalPanel(condition="input.tabset=='Calculate SPI'",
					uiOutput("SPI_main")),
				conditionalPanel(condition="input.tabset=='Summary Statistics'",
					uiOutput("ZONE_main")),
				conditionalPanel(condition="input.tabset=='Download CHIRPS Data'",
					uiOutput("DownCHIRPS_Main"))
				)
			) # end SidebarLayout
		)), # end Process Tab Panel (navbar)

		# VISUALIZE tab (across top)
		tabPanel("Visualize", id="vizpg",
		  	div(
	      	tags$head(
	      	tags$link(rel="stylesheet", type="text/css", href="assets/css/map.css")),

	      	# leaflet map; note the legend is in server.r
	      	leafletOutput("mymap"),
	      	
	      	absolutePanel(id="controls", class="panel panel-default", 
	      		fixed=TRUE, draggable=TRUE, 
	      		top=75, left="auto", right=20, bottom="auto",
	      		width=380, height="auto",

	        h4("Visualize Your Data"),

	   		# CHECKBOX: Choose Your Tool (default w/ time slider already checked)
	        checkboxGroupInput(inputId="checkControl", 
			   label="Choose Your Tool", 
			   choices=c("Time Slide"="timeSliderChecked"),
			   selected="timeSliderChecked",
			   inline=TRUE),

	        # selected SPI data to display
	        selectInput("VIZselectspi",
				"Select SPI Data",
				c("",
					list.files(tools:::file_path_as_absolute("data/visualize/spi"))), 
				selected=NULL, 
				multiple=FALSE),

	   		# CHECKBOX: Select Boundary/boundaries (agencies default)
	        checkboxGroupInput(inputId="VIZselectshp", 
				label="Select Boundaries", 
				choices=c("NN Chapters"="chapters",
				  	"NN Agencies"="agencies",
				  	"USGS Watersheds"="watersheds",
				  	"Eco-Region Level 3"="eco3",
				  	"Eco-Region Level 4"="eco4"),
				selected="agencies"),

	      	actionButton("VIZ_ready", 
	      		"Visualize!", 
	      		style="danger", 
	      		block=TRUE),

	        actionButton("VIZ_clearRas", 
	        	"Clear Raster Layer", 
	        	style="danger", 
	        	block=TRUE)
				), # end control absolute Panel

	      	# CHECKBOX: this will show the time slide window
	      	conditionalPanel(condition="input.checkControl.indexOf('timeSliderChecked') != -1",
	      		absolutePanel(id="timeSlide", class="panel panel-default", 
		      		fixed=TRUE, draggable=TRUE, 
		      		top="auto", left="auto", right=20, bottom=5,
		      		width=650, height=170,

		      			# search for a specific date, error if SPI unavailable/date unformatted 
		      			fluidRow(style="padding-top: 11px;  margin-bottom: -10px !important;",
		      			 	column(4,
				        		h4(uiOutput("renderDateLabel"))),
		      			 	column(3, 
				        		uiOutput("searchDateErrorMsg")),
		      			 	column(5,
				        		uiOutput("searchDate"))),
				        fluidRow(		        	
				        	column(12,
				        		tags$head(
				        		tags$style("#VIZtimeline{margin-top: -20px;}")),
			  					uiOutput("VIZtimeline"))))
	      		), # end time slide window 

		    # CHECKBOX: this will show the plotted chart window
		    conditionalPanel(condition="input.checkControl.indexOf('plotChecked') != -1",
		      	absolutePanel(id="timeSlide", class="panel panel-default", 
		      		fixed=TRUE, draggable=TRUE, 
		      		top="auto", left=5, right="auto", bottom=-10,
		      		width=580, height=370,
				    
				    	uiOutput("plt"))
	      		) # end plotted chart window
	    	)
		) # end VISUALIZE tab panel
	)
)
