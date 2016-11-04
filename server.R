require(shiny)    #web interface
require(raster)   #raster processing
require(leaflet)  #web mapping
require(rgdal)    #geospatial library
require(SPEI)     #for SPI calculation
require(reshape2) #data processing
require(zoo)	  #dates
require(ggplot2)  #plotting


shinyServer(function(input, output, session) {

	#*****************
	#* Calculate SPI *
	#*****************
	output$SPI_main <- renderUI({
		input$BT_calcSPI

		if (input$BT_calcSPI > 0){
			isolate({
				#process
				progress <- shiny::Progress$new()
				on.exit(progress$close())
				progress$set(message="Calculating SPI rasters", value=0)

				startyr <- as.numeric(input$SPI_startyr)
				endyr <- as.numeric(input$SPI_endyr)

				calcspi(startmo=as.numeric(input$SPI_startmo), 
					startyr=as.numeric(input$SPI_startyr), 
					endyr=as.numeric(input$SPI_endyr), 
					scale=as.numeric(input$SPI_timescale),
					dir="./data/process/precip", 
					progress=progress)

				#complete
				message <- sprintf("OK! SPI rasters for the year range %d to %d have finished processing!", 
					startyr, endyr)
				list(
					div(class="alert alert-info", align="center",
					  	"The newly created files can be found in the '/Data/Process/SPI' folder."),
					img(src="assets/img/ames.jpg", class="ameslogo", 
						height="432px", width="400px")
				)
			})
		} else {
			list(
				div(h2("Calculate SPI")),
				img(src="assets/img/ames.jpg", class="ameslogo", 
					height="432px", width="400px")
			)
		}
	})

	#**********************
	#* Summary Statistics *
	#**********************

	output$ZONE_main <- renderUI({
		if(is.null(input$BT_ZoneCalc)) 
			return(
				list(
					div(h2("Summary Statistics")),
					img(src="assets/img/ames.jpg", class="ameslogo", 
						height="432px", width="400px")
				)
			)

		#lazy eval for rendered button BT_ZoneCalc (not yet rendered till BT_ZoneLoadShp pressed)
		if (input$BT_ZoneCalc > 0){
			isolate({
				#process
				progress <- shiny::Progress$new()

				# get full path directory names for the selected SPI dataset and boundary shapefile
				dirname <- paste0(getwd(), "/data/process/spi/", input$ZONE_dir, "/")
				shpdir <- paste0(getwd(), "/data/process/shapefile/", input$ZONE_shp, "/")

				on.exit(progress$close())
				progress$set(message="Calculating Zonal Statistics", value=0)
				print(paste(dirname, shpdir, input$ZONE_SelectedAttr))
				zonedf <<- zonalspi(dir=dirname, 
								 	shp=shpdir, 
								 	attrib=input$ZONE_SelectedAttr,
								 	progress=progress)

				output$ZonalTable <- renderDataTable({zonedf}, options=list(pageLength=6))

				#complete
				message <- paste0("OK! Zonal Statistics have completed. You can view
										the summarized data (regions as defined by the ", input$ZONE_SelectedAttr,
										" attribute). You can save this to disk by pressing the download button below.")
				list(
					div(class="alert alert-info", align="center", 
						span(message),
						downloadButton("downloadData", "Download Data as CSV", class="btn-block")),
						dataTableOutput('ZonalTable')
				)
			})
		} else {
			list(
				div(h2("Summary Statistics")),
				img(src="assets/img/ames.jpg", class="ameslogo", 
					height="432px", width="400px")
			)
		}
	})

	output$ZONE_main <- renderUI({
		if(is.null(input$BT_ZoneCalc)) 
			return(
				list(
					div(h2("Summary Statistics")),
					img(src="assets/img/ames.jpg", class="ameslogo", 
						height="432px", width="400px")
				)
			)

		#lazy eval for rendered button BT_ZoneCalc (not yet rendered till BT_ZoneLoadShp pressed)
		if (input$BT_ZoneCalc > 0){
			isolate({
				#process
				progress <- shiny::Progress$new()

				# get full path directory names for selected SPI dataset and boundary shapefile
				dirname <- paste0(getwd(), "/data/process/spi/", input$ZONE_dir, "/")
				shpdir <- paste0(getwd(), "/data/process/shapefile/", input$ZONE_shp, "/")

				on.exit(progress$close())
				progress$set(message="Calculating Zonal Statistics", value=0)
				print(paste(dirname, shpdir, input$ZONE_SelectedAttr))
				zonedf <<- zonalspi(dir=dirname, 
		 			shp=shpdir, 
		 			attrib=input$ZONE_SelectedAttr,
		 			progress=progress)

				output$ZonalTable=renderDataTable({zonedf}, options=list(pageLength=6))

				#complete
				message <- paste0("OK! Zonal Statistics have completed. You can view
										the summarized data (regions as defined by the ", input$ZONE_SelectedAttr,
										" attribute). You can save this to disk by pressing the download button below.")
				list(
					div(class="alert alert-info", align="center", 
						span(message),
						downloadButton("downloadData", "Download Data as CSV", class="btn-block")),
						dataTableOutput('ZonalTable')
				)
			})
		} else {
			list(
				div(h2("Summary Statistics")),
				img(src="assets/img/ames.jpg", class="ameslogo", 
					height="432px", width="400px")
			)
		}
	})	

	# to download the summary statistics csv
	output$downloadData <- downloadHandler(
	    # the name that the client browser uses when saving the file (MUST OPEN DSAT IN BROWSER WINDOW)
	    filename="summarystats_zonalTable.csv",

	    # writes the summary stats data to a file given to it by the argument 'file'.
	    content=function(file) {
	      write.csv(zonedf, file, row.names = FALSE)
	    }
	)

	output$ZONE_shpLoad <- renderUI ({
		input$ZONE_shp

		# check that a shpfile has been selected and loaded successfully
		if (!is.null(input$ZONE_shp)) {
			# load the shapefile given the path to it
			shpdir <- paste0(getwd(), "/data/process/shapefile/", input$ZONE_shp, "/")
			s <- shapefile(shpdir)

			list(
				selectizeInput("ZONE_SelectedAttr", 
					"Select zonal attribute field: ", 
				 	names(s@data)),
				br(),
				actionButton("BT_ZoneCalc", 
					"Calculate Zonal Statistics", 
					style="info", 
					block=TRUE)
			)
		}
	})

	# update options for SPI data by observing for changes in the tabset panel 
	observeEvent(input$tabset, {
		updateSelectInput(session, 
			"ZONE_dir", 
			label="Select SPI data", 
	 		choices=c("", 
	 			list.files(tools:::file_path_as_absolute("data/process/spi"))))
		})


	#************************
	#* Download CHIRPS Data *
	#************************
	
	output$DownCHIRPS_Main <- renderUI({
		input$BT_downCHIRPS

		#lazy eval for rendered button BT_ZoneCalc (not yet rendered till BT_ZoneLoadShp pressed)
		if (input$BT_downCHIRPS > 0){
			isolate({
				#process
				progress <- shiny::Progress$new()
				on.exit(progress$close())
				progress$set(message="Downloading CHIRPS Data", value=0)
				
				#complete
				nDownloaded <- downClipCHIRPS(progress)
				message <- paste0("OK! ", nDownloaded, " CHIRPS datasets downloaded and clipped. New data, both raw and clipped, 
								   are located in data/downloadCHIRPS/raw and data/downloadCHIRPS/clipped
								   respectively. 
								   An additional copy of the data is located in data/process/precip for subsequent calculation of SPI.")
				list(
					div(class="alert alert-info", align="center", 
						span(message),
						img(src="assets/img/ames.jpg", class="ameslogo", 
							height="432px", width="400px")
					)
				)
			})
		} else {
			list(
				div(h2("Download CHIRPS Precipitation Data")),
				img(src="assets/img/ames.jpg", class="ameslogo", 
					height="432px", width="400px")
			)
		}
	})


	############################
	# 		Visualization	   #
	############################

	# render the map (default is the OSM basemap w/ City Markers layer)
	output$mymap <- renderLeaflet({
		leaflet(cities) %>%
	  	addProviderTiles("OpenStreetMap.DE", group="OSM Base Map") %>%
	  	setView(lng=-108.80, lat=36.00, zoom=7) %>%
	  	addMarkers(~Long, ~Lat, popup=~City, group="City Markers") %>%
	  	addLegend("topleft", 
			colors=leg_col,
			labels=seq(2, -2),
			title="SPI",
			layerId="LEGEND") 
	})

	# render (default/blank) timeline upon opening tool
	# necessary to set VIZtimeline's value to 1 so rasters can be rendered upon hitting "Visualize!"
	output$VIZtimeline <- renderUI({
		sliderInput(inputId="VIZslider", 
			label=br("Select your SPI data and boundary, then click 'Visualize!"),  
			min=1, 
			max=1, 
			value=1,
			step=100, 
			animate=animationOptions(interval = 700),
			pre="Month ")
	})

	# update the options displayed in dropdown for SPI dataset folder selection whenever a tab change is made
	# default option for "Choose Your Tool" in the "Visualize Your Data" window fixed to be "Time Slide"
	observeEvent(input$panels, {
		updateSelectInput(session, "VIZselectspi", label="Select SPI data", 
	 		choices=list.files(tools:::file_path_as_absolute("data/visualize/spi")))
	 	disable("checkControl")
	})

	# once our 'Visualize!' button has been pressed, we can assign VIZstack (aka render rasters)
	# and render the rest of the map/Plot Analytics and Time Slide windows' functionalities
	observeEvent(input$VIZ_ready, {
		# prevent user from re-running "Visualize!"
		# prevent user from changing the spi data source
		#allow user to hide/show Time Slide and Plot Analytics tool windows w/ checkboxes
		disable("VIZselectspi")
		disable("VIZ_ready")
		enable("checkControl")

		# allow Plot to be one of the checkbox options, though Time Slide remains the default
		updateCheckboxGroupInput(session, "checkControl", 
			choices=c("Time Slide"="timeSliderChecked", "Plot"="plotChecked"),
			selected="timeSliderChecked",
    		inline=TRUE)

		if (input$VIZ_ready > 0) {
			VIZlist <- list.files(paste0("data/visualize/spi/", input$VIZselectspi), full.names=FALSE)
			VIZstack <- stack(list.files(paste0("data/visualize/spi/", input$VIZselectspi), full.names=TRUE))
			VIZlayers <- nlayers(VIZstack)

			# update time slider so that it goes from month 1 to the last of the raster stack's time range
			observe({
				updateSliderInput(session, inputId="VIZslider", 
					max=VIZlayers, 
					label="", 
					step=1)
			})

			# reflect changes in boundary shapefiles selected (checkboxes) on map
			observeEvent(input$VIZselectshp, {
				leafletProxy("mymap") %>%
					clearShapes()  
				selectedshp <- input$VIZselectshp
				
				# multiple boundaries may be selected; add as many as necessary
				for (i in (seq(1, length(selectedshp)))) {
					if (selectedshp[i] == "chapters") {
						leafletProxy("mymap", data=chapters) %>%
							addPolygons(
								stroke=TRUE,
								opacity="100", 
								weight="2",
								color="orange",
								fill=TRUE,
								fillColor="",
								fillOpacity="0",
								smoothFactor=0.5,
								popup=~Chapter_Na,
								group="Boundary")
					}
					else if (selectedshp[i] == "agencies") {
						leafletProxy("mymap", data=agencies) %>%
							addPolygons(
								stroke=TRUE,
								opacity="100", 
								weight="2",
								color="black",
								fill=TRUE,
								fillColor="",
								fillOpacity="0",
								smoothFactor = 0.5,
								popup=~Agency_Nam, 
								group="Boundary")
					}
					else if (selectedshp[i] == "eco3") {
						leafletProxy("mymap", data=eco3) %>%
							addPolygons(
								stroke=TRUE,
								opacity="100", 
								weight="2",
								color="brown",
								fill=TRUE,
								fillColor="",
								fillOpacity="0",
								smoothFactor=0.5,
								popup=~US_L3NAME,
								group="Boundary")
					}
					else if (selectedshp[i] == "eco4") {
						leafletProxy("mymap", data=eco4) %>%
							addPolygons(
								stroke=TRUE,
								opacity="100", 
								weight="1",
								color="green",
								fill=TRUE,
								fillColor="",
								fillOpacity="0",
								smoothFactor=0.5,
								popup=~US_L4NAME,
								group="Boundary")
					}
					else if (selectedshp[i] == "watersheds") {
						leafletProxy("mymap", data=watershed) %>%
							addPolygons(
								stroke=TRUE,
								opacity="100", 
								weight="1",
								color="purple",
								fill=TRUE,
								fillColor="",
								fillOpacity="0",
								smoothFactor=0.5,
								popup=~NAME,
								group="Boundary")
					}
				} #end for loop
			})
			
			# add the first raster to map
			observe({
				leafletProxy("mymap") %>% 
				clearImages() %>%
					addRasterImage(VIZstack[[1]], 
						project=FALSE, 
						colors=pal, 
						opacity=1, 
						group="SPI Raster")							
			})

			# updates the raster image on viz map, only necessary if # of layers in our VIZ stack is >1 
			# (ie there is more than a single image/date in our selected spi data)
			# also adds layers legend (user can choose to turn layers on/off)
			observe({
				c <- input$VIZslider
				leafletProxy("mymap") %>%
				clearImages() %>%
					addRasterImage(VIZstack[[c]], 
						project=FALSE, 
						colors=pal, 
						group="SPI Raster") %>%
							addLayersControl(overlayGroups=c("SPI Raster", "City Markers", "Boundary"))
			})
				
			# returns the selected date from the timeslider
			seldate <- reactive({
				if (is.null(input$VIZslider)) {
					num <- gsub("[^\\d]+", "", VIZstack[[1]]@data@names, perl=TRUE)
					sd <- as.character(as.yearmon(num, "%Y%m"))
					return(sd)
				}
				else{
					c <- input$VIZslider
					num <- gsub("[^\\d]+", "", VIZstack[[c]]@data@names, perl=TRUE)
					sd <- as.character(as.yearmon(num, "%Y%m"))
					return(sd)
				}
			})

			# label for time slider
			output$renderDateLabel <- renderText({ paste0("Currently viewing: </br>", seldate()) })

			# Search a date given "YYYY/MM"
			output$searchDate <- renderUI({
				textInputBT(inputId="searchDateInput", 
					buttonID="BT_searchDate", 
					label="Search for a date (YYYY/MM)", 
					value="")
			})

			searchDateErrorFlag <- reactiveValues()
			# search date, filter input and update slider
			observe({
				if(length(input$BT_searchDate) == 0) return(NULL)
				
				isolate({
					if(input$BT_searchDate > 0) {
						if(grepl("^[0-9]{4}/[0-9]{2}$", input$searchDateInput, perl=TRUE)) {
							filesNum  <- gsub("[^\\d]+", "", VIZlist, perl=TRUE)
							searchNum <- gsub("[^\\d]+", "", input$searchDateInput, perl=TRUE)
							searchi   <- which(filesNum %in% searchNum)
							if(length(searchi) == 0) {
								#SPI data unavailable for that date
								searchDateErrorFlag$unavailable <- TRUE
								searchDateErrorFlag$flag <- FALSE
							} else {
								#found, update slider
								searchDateErrorFlag$flag <- FALSE
								searchDateErrorFlag$unavailable <- FALSE
								updateSliderInput(session, inputId="VIZslider", value = searchi)
							}
						} else {
							#wrong formatting of date
							searchDateErrorFlag$flag <- TRUE
						}
					}
				})
			})

			output$searchDateErrorMsg <- renderUI({
				if(!isTRUE(searchDateErrorFlag$flag)) {
					#SPI data unavailable for that date
					if (isTRUE(searchDateErrorFlag$unavailable)) {
						tags$p(class="text-danger", align="right", style="padding-top: 42px", "SPI unavailable.")
					}
					else {
						#found!
						return(NULL)
					}
				}
				#wrong formatting of date
				else if(searchDateErrorFlag$flag && input$BT_searchDate > 0) { 
					tags$p(class="text-danger", align="right", style="padding-top: 23px", "Verify search date format.")
				}
				else {
					#nothing clicked, no message necessary
					return(NULL)
				}
			})

			# clear images button resets the entire thing, bringing user back to "Intorduction" home page
			observeEvent(input$VIZ_clearRas, {
				js$reset()
			})                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       

			# grab the names to choose from in the dropdown for selected boundary type
			anames <- as.character(agenciesProc@data$Agency_Nam[!is.na(agenciesProc@data$Agency_Nam)])
			cnames <- as.character(chaptersProc@data$Chapter_Na[!is.na(chaptersProc@data$Chapter_Na)])
			e3names <- as.character(eco3Proc@data$US_L3NAME[!is.na(eco3Proc@data$US_L3NAME)])
			e4names <- as.character(eco4Proc@data$US_L4NAME[!is.na(eco4Proc@data$US_L4NAME)])
			watershednames <- as.character(watershedProc@data$NAME[!is.na(watershedProc@data$NAME)])
			boundopts <- input$VIZselectshp

			# plot analytic pop up
			output$plt <- renderUI({
				list(
					tags$style(type="text/css", ".shiny-output-error { visibility: hidden; }", ".shiny-output-error:before { visibility: hidden; }"),
					h4(paste0("Plot Analytics for ", seldate())),
					fluidRow(
						column(3, strong("Select from")),
						column(4,
							selectInput("PLT_BoundOpts", 
								choices=c("a boundary" = "", input$VIZselectshp), 
								label=NULL)),
						column(5,
							selectizeInput("PLT_SelectedZone", 
								label=NULL, 
								choices=c("a summary area" = "")), 
							align="left")),
					plotOutput("DrSev", 
						height=240, width=540)
				)
			})

			# generate drought severity bar plot
			DrSevDF <- reactive({
				c <- input$VIZslider

				# update summary area options based on the boundary selected
				# keep the selected boundary
				if(input$PLT_BoundOpts == "chapters") {
					updateSelectInput(session,
						inputId="PLT_BoundOpts",
						selected="chapters")
					updateSelectizeInput(session, 
						inputId="PLT_SelectedZone",
						choices=cnames,
						selected=input$PLT_SelectedZone)
					return(drSevByShp(shp=chaptersProc,
										raster=VIZstack[[c]],	
										aORc="chapter"))
				}
				else if(input$PLT_BoundOpts == "agencies") {
					updateSelectInput(session,
						inputId="PLT_BoundOpts",
						selected="agencies")
					updateSelectizeInput(session, 
						inputId="PLT_SelectedZone",
						choices=anames,
						selected=input$PLT_SelectedZone)
					return(drSevByShp(shp=agenciesProc, 
										raster=VIZstack[[c]],
										aORc="agency"))
				}
				else if(input$PLT_BoundOpts == "eco3") {
					updateSelectInput(session,
						inputId="PLT_BoundOpts",
						selected="eco3")
					updateSelectizeInput(session, 
						inputId="PLT_SelectedZone",
						choices=e3names,
						selected=input$PLT_SelectedZone)
					return(drSevByShp(shp=eco3Proc, 
										raster=VIZstack[[c]],
										aORc="eco3"))
				}
				else if(input$PLT_BoundOpts == "eco4") {
					updateSelectInput(session,
						inputId="PLT_BoundOpts",
						selected="eco4")
					updateSelectizeInput(session, 
						inputId="PLT_SelectedZone",
						choices=e4names,
						selected=input$PLT_SelectedZone)
					return(drSevByShp(shp=eco4Proc, 
										raster=VIZstack[[c]],
										aORc="eco4"))
				}
				else if(input$PLT_BoundOpts == "watersheds") {
					updateSelectInput(session,
						inputId="PLT_BoundOpts",
						selected="watersheds")
					updateSelectizeInput(session, 
						inputId="PLT_SelectedZone", 
						choices=watershednames,
						selected=input$PLT_SelectedZone)
					return(drSevByShp(shp=watershedProc, 
										raster=VIZstack[[c]],
										aORc="water_sheds"))
				}
			})

			labelsForPlot <- reactive({
				selectedforplot <- DrSevDF()[DrSevDF()$name == input$PLT_SelectedZone, ]$Var1
				return(as.character(lab[as.factor(names(lab)) %in% selectedforplot]))	
			})

			colorsForPlot <- reactive({
				selectedforplot <- DrSevDF()[DrSevDF()$name == input$PLT_SelectedZone, ]$Var1
				return(as.character(col[as.factor(names(col)) %in% selectedforplot]))	
			})

			# the plot itself
			output$DrSev <- renderPlot({		
				ggplot(data=DrSevDF()[DrSevDF()$name==input$PLT_SelectedZone,], aes(x=Var1, y=perc)) +
		    		geom_bar(fill=colorsForPlot(), colour="black", stat="identity") + 
		    		ylim(0,100) + 
		    		guides(fill=FALSE) + 
		    		ggtitle(paste("Drought Severity:", input$PLT_SelectedZone, "\n", seldate())) +
		    		xlab(NULL) + 
		    		ylab("Percent of Area Experienced") +
		    		scale_x_discrete(labels=labelsForPlot()) + 
		    		geom_text(aes(label=perclab, y=perc/2), colour="black") +
		    		theme(axis.text.x =element_text(size=14, angle=30, hjust=1))
			})
		}
	})
})

