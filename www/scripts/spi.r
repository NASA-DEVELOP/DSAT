# calcspi
# calc 12 - month spi given a directory of precip data.
# INPUTS:
# 	startmo 	starting month (input a number)
# 	startyr 	starting year  (4 digit YYYY)
# 	endyr 		ending year    (4 digit YYYY)
# 	dir 		(optional) directory of the files. Default assumes current
calcspi <- function(startmo, startyr, endyr, TIME_SCALE=12, dir="current", progress) {
	if(!require(SPEI)) stop("install the SPEI package.")
	if(!require(raster)) stop("install the raster package.")
	if(nargs() < 5) stop("Not enough args. Usage: startmo, startyr, endyr, dir(optional)")
	if(dir=="current") {
		files <- list.files(pattern="*.tif$")
		fnames <- list.files(pattern="*.tif$")
		rnames <- list.files()
		if("spi" %in% rnames) stop("spi folder already exists, either remove or move it")
	} else {
		files <- list.files(dir, pattern="*.tif$", full.names=TRUE)
		fnames <- list.files(dir, pattern="*.tif$", full.names=FALSE)
		rnames <- list.files(dir)
		if("spi" %in% rnames) stop("spi folder already exists, either remove or move it")
	}

	n <- 10
	progress$inc(2/n, detail = paste("Loading raster files ... "))
	ref <- raster(files[1])
	s <- stack(files)
	brick <- brick(s) # faster, see the raster vignette
	# for each cell, calc spi
	nyear <- endyr - startyr + 1

	# # get file names (numbers for the years only)
	# numOnly <- sapply(fnames, function(x) gsub("[A-Za-z]", "", x))
	# names(numOnly) <- NULL

	#input  cell:	 timeseries for a cell 
	#		b:	 RasterBrick
	#		yr:		 the num of years
	#		startMo: starting month (assumed 1)
	#outputs: SPI/SPEI from spei library
	getSPI <- function(cell, b, startYear, startMonth, scale) {
		#format to time series
		timeseries <- ts(c(brick[cell]), start=c(startYear, startMonth))
		return(spi(timeseries, scale, na.rm=TRUE))
	}
	progress$inc(4/n, detail = paste("Calculating SPI ... "))
	l <- lapply(seq(ncell(brick)), function(x){
		if( !is.na(brick[x][1]) ) {
			return(c(getSPI(x, brick, startyr, startmo, TIME_SCALE)$fitted))
		} else {
			#filler for NA cells in the first of the timeseries.
			#assume: if NA in the first cell then NA in the rest (need to check this)
			return(rep(NA, length(files)))
		}
	})

	coordref <- CRS(brick@crs@projargs)
	orig <- origin(brick)

	progress$inc(2/n, detail = paste("Writing out rasters ... "))
	# write them spi rasters to 'spi' folder
	if(dir=="current") {
		if("spi" %in% rnames) stop("spi folder already exists, either remove or move it")
		dir.create("spi")
	} else {
		if("spi" %in% rnames) stop("spi folder already exists, either remove or move it")
		dir.create(paste0(dir, "/spi"))
	}
	lapply(seq(from=TIME_SCALE+1, to=length(files)), function(layer) {
		data <- sapply(l, function(x) {
				x[layer]
			})
		r <- ref
		values(r) <- data
		crs(r) <- coordref
		origin(r) <- orig
		fileName <- paste0(dir,"/spi/", "spi_", fnames[layer])
		writeRaster(r, fileName, format="GTiff")
	})
	progress$inc(2/n, detail = paste("Done!"))
}



#display it in a timeseries (nice hack), uncomment it
# for(layer in seq(length(files))) {
# 	data <- sapply(l, function(x) {
# 			x[layer]
# 		})
# 	r <- ref
# 	values(r) <- data
# 	crs(r) <- coordref
# 	origin(r) <- orig
# 	plot(r)
# 	Sys.sleep(0.2)
# }