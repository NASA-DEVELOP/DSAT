require(shiny)    #web interface
require(raster)   #raster processing
require(leaflet)  #web mapping
require(rgdal)    #geospatial library
require(SPEI)     #for SPI calculation
require(reshape2) #data processing
require(zoo)	  #dates
require(ggplot2)  #plotting

#for downClipGPM.r
# list.of.packages <- c("rhdf5", "raster","rgdal","sp","httr","lubridate")
# source("http://bioconductor.org/biocLite.R")
# biocLite("rhdf5")


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
				progress$set(message = "Calculating SPI rasters", value = 0)
				calcspi(startmo=as.numeric(input$SPI_startmo), 
								startyr=as.numeric(input$SPI_startyr), 
								endyr=as.numeric(input$SPI_endyr), 
								dir=input$SPI_dir, 
								TIME_SCALE=as.numeric(input$SPI_timescale),
								progress=progress)

				#complete
				message <- "OK! SPI rasters have finished processing and
										can be found in the directory "
				list(
					div(class="alert alert-info", align="center",
					  span(message, tags$b(paste0(input$SPI_dir, "/spi"))),
					  ". Please make sure to delete/move the newly created spi 
					   folder within the directory before re-running spi calculator."),
					img(src="assets/img/ames.jpg", class="ameslogo", height="432px", width="400px")
				)
			})
		} else {
			list(
				div(h2("Calculate SPI")),
				img(src="assets/img/ames.jpg", class="ameslogo", height="432px", width="400px")
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
					img(src="assets/img/ames.jpg", class="ameslogo", height="432px", width="400px")
				)
			)
		#lazy eval for rendered button BT_ZoneCalc (not yet rendered till BT_ZoneLoadShp pressed)
		if (input$BT_ZoneCalc > 0){
			isolate({
				
				#process
				progress <- shiny::Progress$new()
				on.exit(progress$close())
				progress$set(message = "Calculating Zonal Statistics", value = 0)
				print(paste(input$ZONE_dir, input$ZONE_shp, input$ZONE_SelectedAttr))
				zonedf <<- zonalspi(dir=input$ZONE_dir, 
								 	shp=input$ZONE_shp, 
								 	attrib=input$ZONE_SelectedAttr,
								 	progress=progress)
				output$ZonalTable <- renderDataTable({ zonedf }, options = list(pageLength = 6))

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
				img(src="assets/img/ames.jpg", class="ameslogo", height="432px", width="400px")
			)
		}
	})

	output$ZONE_main <- renderUI({
		if(is.null(input$BT_ZoneCalc)) 
			return(
				list(
					div(h2("Summary Statistics")),
					img(src="assets/img/ames.jpg", class="ameslogo", height="432px", width="400px")
				)
			)
		#lazy eval for rendered button BT_ZoneCalc (not yet rendered till BT_ZoneLoadShp pressed)
		if (input$BT_ZoneCalc > 0){
			isolate({
				
				#process
				progress <- shiny::Progress$new()
				on.exit(progress$close())
				progress$set(message = "Calculating Zonal Statistics", value = 0)
				print(paste(input$ZONE_dir, input$ZONE_shp, input$ZONE_SelectedAttr))
				zonedf <<- zonalspi(dir=input$ZONE_dir, 
								 			 shp=input$ZONE_shp, 
								 			 attrib=input$ZONE_SelectedAttr,
								 			 progress=progress)
				output$ZonalTable = renderDataTable({ zonedf }, options = list(pageLength = 6))

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
				img(src="assets/img/ames.jpg", class="ameslogo", height="432px", width="400px")
			)
		}
	})	

	output$downloadData <- downloadHandler(
	    # This function returns a string which tells the client
	    # browser what name to use when saving the file.
	    filename = function() {
			  return("zonalTable.csv")
			},

	    # This function should write data to a file given to it by
	    # the argument 'file'.
	    content = function(file) {
	      # Write to a file specified by the 'file' argument
	      write.csv(zonedf, file, row.names = FALSE)
	    }
	)

	output$ZONE_shpLoad <- renderUI ({

		input$BT_ZoneLoadShp
		# TODO: check shp loaded successfully
		if (input$BT_ZoneLoadShp > 0) {
			isolate({
				# Load the shapefile given the path to it
				# WARN: check the projection
				s <- shapefile(input$ZONE_shp)
				list(
					HTML('<div class="form-group has-success">'),
					selectizeInput("ZONE_SelectedAttr", 
												 "Select Zonal Attribute Field: ", 
												  names(s@data)),
					HTML('</div>'),
					br(),
					actionButton("BT_ZoneCalc", 
											 "Calculate Zonal Statistics", 
											  style="info", block=TRUE)
				)
			})
		} else {
			div("Click 'Submit' to load the shapefile in 
				 and a dropdown menu will apear to
				 allow you to choose which field designates 
				 your zones.")
		}
	})

	#*********************
	#* Download CHIRPS Data *
	#*********************
	# this is the main panel for downloading GPM tab
	output$DownGPM_Main <- renderUI({
		if(is.null(input$BT_downGPM)) 
			return(
				list(
					div(h2("Download GPM Precipitation Data")),
					img(src="assets/img/ames.jpg", class="ameslogo", height="432px", width="400px")
				)
			)
		#lazy eval for rendered button BT_ZoneCalc (not yet rendered till BT_ZoneLoadShp pressed)
		if (input$BT_downGPM > 0){
			isolate({
				#process
				progress <- shiny::Progress$new()
				on.exit(progress$close())
				progress$set(message = "Downloading CHIRPS Data", value = 0)
				nDownloaded <- downClipGPM(progress)
				#complete
				message <- paste0("OK! ", nDownloaded, " GPM datasets downloaded and clipped. New data, both raw and clipped, 
								   are located in data/downloadGPM/raw and data/downloadGPM/clipped
								   respectively.")
				list(
					div(class="alert alert-info", align="center", 
						span(message)
						# downloadButton("downloadData", "Download Data as CSV", class="btn-block")),
						# dataTableOutput('ZonalTable')
					)
				)
				
			})
		} else {
			list(
				div(h2("Download CHIRPS Precipitation Data")),
				img(src="assets/img/ames.jpg", class="ameslogo", height="432px", width="400px")
			)
		}
	})


	############################
	# 		Visualization	   #
	############################
	# render the map
	output$mymap <- renderLeaflet({
		leaflet(agencies) %>%
		  addProviderTiles("OpenStreetMap.DE"
		  	# "OpenMapSurfer.Roads"
		    # urlTemplate = "http://api.tiles.mapbox.com/v3/developnn.b91b5b31/{z}/{x}/{y}.png",
		    # attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
		  ) %>%
		  setView(lng = -108.80, lat = 36.00, zoom = 7) %>%
		addPolygons(stroke = TRUE,
					opacity = "100", 
					weight="2",
					color="black",
					fill=TRUE,
					fillColor="",
					fillOpacity="0",
					smoothFactor = 0.5,
					popup=~Agency_Nam)
	})

	# update the boundary shapefile shown according to input$VIZselectshp
	observe({
		leafletProxy("mymap", data=chapters) %>%
			clearShapes()
		switch(input$VIZselectshp, 
				"chapters" = {
					leafletProxy("mymap", data=chapters) %>%
						addPolygons(
								stroke = TRUE,
								opacity = "100", 
								weight="2",
								color="black",
								fill=TRUE,
								fillColor="",
								fillOpacity="0",
								smoothFactor = 0.5,
								popup=~Chapter_Na)
				},
				"agencies" = {
					leafletProxy("mymap", data=agencies) %>%
						addPolygons(
								stroke = TRUE,
								opacity = "100", 
								weight="2",
								color="black",
								fill=TRUE,
								fillColor="",
								fillOpacity="0",
								smoothFactor = 0.5,
								popup=~Agency_Nam)
				},
				"eco3" = {
					leafletProxy("mymap", data=eco3) %>%
						addPolygons(
								stroke = TRUE,
								opacity = "100", 
								weight="2",
								color="black",
								fill=TRUE,
								fillColor="",
								fillOpacity="0",
								smoothFactor = 0.5,
								popup=~US_L3NAME)
				},
				"eco4" = {
					leafletProxy("mymap", data=eco4) %>%
						addPolygons(
								stroke = TRUE,
								opacity = "100", 
								weight="1",
								color="black",
								fill=TRUE,
								fillColor="",
								fillOpacity="0",
								smoothFactor = 0.5,
								popup=~US_L4NAME)
				},
				"watersheds" = {
					leafletProxy("mymap", data=watershed) %>%
						addPolygons(
								stroke = TRUE,
								opacity = "100", 
								weight="1",
								color="black",
								fill=TRUE,
								fillColor="",
								fillOpacity="0",
								smoothFactor = 0.5,
								popup=~NAME)
				}
		) #end switch
	})
	

	# returns the selected date from the timeslider
	seldate <- reactive({
		c <- as.numeric(input$VIZslider)
		num <- gsub("[^\\d]+", "", VIZstack[[c]]@data@names, perl=TRUE)
		sd <- as.character(as.yearmon(num, "%Y%m"))
		return(sd)
	})

	# updates the raster image on viz map
	observe({
		c <- input$VIZslider
		leafletProxy("mymap") %>%
			clearImages() %>%
			addRasterImage(VIZstack[[c]], project=FALSE, colors=pal) 
	})

	# label for time slider raste
	output$renderDateLabel <- renderText({ paste0("Currently viewing: ", seldate()) })

	# Search a date given "YYYY/MM"
	output$searchDate <- renderUI({
		textInputBT(inputId="searchDateInput", 
						buttonID = "BT_searchDate", 
						label="Search for a date (YYYY/MM format)", 
						value = "")
		
	})

	searchDateErrorFlag <- reactiveValues()
	# search date, filter input and update slider
	observe({
		if(length(input$BT_searchDate) == 0) return(NULL)
		isolate({
			if(input$BT_searchDate > 0) {
				if(grepl("^[0-9]{4}/[0-9]{2}$", input$searchDateInput, perl=TRUE)) {
					files     <- list.files("data/visualize/spi")
					filesNum  <- gsub("[^\\d]+", "", files, perl=TRUE)
					searchNum <- gsub("[^\\d]+", "", input$searchDateInput, perl=TRUE)
					searchi   <- which(filesNum %in% searchNum)
					if(length(searchi) == 0) {
						searchDateErrorFlag$flag <- TRUE
					} else {
						#found, update slider
						searchDateErrorFlag$flag <- FALSE
						updateSliderInput(session, inputId="VIZslider", value = searchi)
					}
				} else {
					searchDateErrorFlag$flag <- TRUE
				}
			}
		})
	})

	output$searchDateErrorMsg <- renderUI({
		if(is.null(searchDateErrorFlag$flag)) 
			return(NULL)
		else if(searchDateErrorFlag$flag && input$BT_searchDate > 0)
			tags$p(class="text-danger", "Please verify format of search date.")
		else
			return(NULL)
	})

	# clear images button
	observe({
		input$VIZ_clearRas
		leafletProxy("mymap") %>%
			clearImages()
	})

	# CHECKBOX: to control the legend
	observe({
		input$checkControl
		if("timeSliderChecked" %in% input$checkControl) {
			leafletProxy("mymap") %>%
				addLegend("topleft", 
				   colors=col_map,
				   labels=seq(-6, 6),
				   title = "SPI",
				   layerId= "LEGEND")
		} else{
			leafletProxy("mymap") %>%
				removeControl(layerId="LEGEND")
		}	
	})

	# grab the names to choose from in the dropdown
	anames <- as.character(agenciesProc@data$Agency_Nam[!is.na(agenciesProc@data$Agency_Nam)])
	cnames <- as.character(chaptersProc@data$Chapter_Na[!is.na(chaptersProc@data$Chapter_Na)])
	e3names <- as.character(eco3Proc@data$US_L3NAME[!is.na(eco3Proc@data$US_L3NAME)])
	e4names <- as.character(eco4Proc@data$US_L4NAME[!is.na(eco4Proc@data$US_L4NAME)])
	watershednames <- as.character(watershedProc@data$NAME[!is.na(watershedProc@data$NAME)])

	#plot analytic pop up
	output$plt <- renderUI({
		list(
			h4(paste0("Plot Analytics for ", seldate())),
			selectizeInput("PLT_SelectedZone", 
						"Select an Agency to Display Summaries", 
						anames),
			plotOutput("DrSev", height=240, width=540)
		)
	})

	# Generate drought severity bar plot
	DrSevDF <- reactive({
		c <- input$VIZslider
		if(input$VIZselectshp == "chapters") {
			updateSelectizeInput(session, 
								 inputId = "PLT_SelectedZone",
								 label = "Select a Chapter to Display Summaries", 
								 choices = cnames, 
								 )
			return(drSevByShp(shp=chaptersProc, 
							  raster=PROCstack[[c]],
							  aORc="chapter")
			)
		}
		else if(input$VIZselectshp == "agencies") {
			updateSelectizeInput(session, 
								 inputId = "PLT_SelectedZone",
								 label = "Select an Agency to Display Summaries", 
								 choices = anames, 
								 )
			return(drSevByShp(shp=agenciesProc, 
							  raster=PROCstack[[c]],
							  aORc="agency")
			)
		}
		else if(input$VIZselectshp == "eco3") {
			updateSelectizeInput(session, 
								 inputId = "PLT_SelectedZone",
								 label = "Select an Ecoregion to Display Summaries", 
								 choices = e3names, 
								 )
			return(drSevByShp(shp=eco3Proc, 
							  raster=PROCstack[[c]],
							  aORc="eco3")
			)
		}
		else if(input$VIZselectshp == "eco4") {
			updateSelectizeInput(session, 
								 inputId = "PLT_SelectedZone",
								 label = "Select an Ecoregion to Display Summaries", 
								 choices = e4names, 
								 )
			return(drSevByShp(shp=eco4Proc, 
							  raster=PROCstack[[c]],
							  aORc="eco4")
			)
		}
		else if(input$VIZselectshp == "watersheds") {
			updateSelectizeInput(session, 
								 inputId = "PLT_SelectedZone",
								 label = "Select a Watershed to Display Summaries", 
								 choices = watershednames, 
								 )
			return(drSevByShp(shp=watershedProc, 
							  raster=PROCstack[[c]],
							  aORc="water_sheds")
			)
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
    		theme(axis.text.x  = element_text(size=14, angle=30, hjust=1))
	})

})
