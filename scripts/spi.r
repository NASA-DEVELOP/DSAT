# calcspi
# calc 12 - month spi given a directory of precip data.
# INPUTS:
# 	startmo 	starting month (input a number)
# 	startyr 	starting year  (4 digit YYYY)
# 	endyr 		ending year    (4 digit YYYY)
# 	dir 		(optional) directory of the files. Default assumes current
calcspi <- function(startmo, startyr, endyr, scale, dir, progress) {
	if(!require(SPEI)) stop("install the SPEI package.")
	if(!require(raster)) stop("install the raster package.")
	if(nargs() < 5) stop("Not enough args. Usage: startmo, startyr, endyr, dir(optional)")
	
	files <- list.files(dir, pattern="*.tif$", full.names=TRUE)
	subsetfiles <- list.files(pattern="*.tif$")
	fnames <- list.files(dir, pattern="*.tif$", full.names=FALSE)
	rnames <- list.files(dir)
	if("spi" %in% rnames) stop("spi folder already exists, either remove or move it")
	
	lastmo <- length(files)

	n <- 10
	progress$inc(2/n, detail = paste("Loading raster files ... "))
	ref <- raster(files[1])
	s <- stack(files)
	br <- brick(s) # faster, see the raster vignette

	# for each cell, calc spi
	#input  cell:	 timeseries for a cell 
	#		b:	 RasterBrick
	#		yr:		 the num of years
	#		startMonth: starting month (assumed 1)
	#outputs: SPI/SPEI from spei library
	getSPI <- function(cell, b, startYear, startMonth, scale) {
		#format to time series
		timeseries <- ts(c(b[cell]), start=c(startYear, startMonth), frequency=scale)
		return(spi(timeseries, scale, na.rm=TRUE))
	}
	progress$inc(4/n, detail = paste("Calculating SPI ... "))


	l <- lapply(seq(ncell(br)), function(x){
		if(!is.na(br[x][1]) ) {
			return(c(getSPI(x, br, startyr, startmo, scale)$fitted))
		} else {
			#filler for NA cells in the first of the timeseries.
			#assume: if NA in the first cell then NA in the rest (need to check this)
			return(rep(NA, length(files)))
		}
	})

	coordref <- CRS(br@crs@projargs)
	orig <- origin(br)

 
	# range of the months and years of interest (aka the rasters to be written)
	library(lubridate)
	library(stringr)
	# months elapsed since Jan 1981 (start of CHIRPS data), to start date and end date of time range,
	# taking into account data availability within that time range
	# format start month with leading zero
	if (((interval(mdy(01011981), mdy(as.numeric(paste0(startmo, "01", startyr)))) %/% months(1)) + 1) < (scale + 1)) {
		moStarted <- scale + 1
		startmo0 <- sprintf("%02d", as.numeric((scale + 1) %% 12))
		if ((scale + 1) >= 12) {
			startingyr <- startyr + 1
		}
		else {
			startingyr <- startyr
		}
	}
	else {
		moStarted <- ((interval(mdy(01011981), mdy(as.numeric(paste0(startmo, "01", startyr)))) %/% months(1)) + 1)
		startmo0 <- sprintf("%02d", as.numeric(startmo))
		startingyr <- startyr 
	}

    if (((interval(mdy(01011981), mdy(as.numeric(paste0(startmo, "01", endyr)))) %/% months(1)) + 1) < (scale + 1)) {
    	moElapsed <- scale + 1
    	endmo0 <- sprintf("%02d", as.numeric((scale + 1) %% 12))
    	if ((scale + 1) >= 12) {
			endingyr <- endyr + 1
		}
		else {
			endingyr <- endyr
		}
    }
    else if (((interval(mdy(01011981), mdy(as.numeric(paste0(startmo, "01", endyr)))) %/% months(1)) + 1) > lastmo) {
    	moElapsed <- lastmo
    	endmo0 <- sprintf("%02d", as.numeric(lastmo %% 12))
		endingyr <- as.numeric(lastmo %% 12) + startyr 
    }
    else {
    	moElapsed <- (interval(mdy(01011981), mdy(as.numeric(paste0(startmo, "01", endyr)))) %/% months(1)) + 1
    	endmo0 <- sprintf("%02d", as.numeric(startmo))
    	endingyr <- endyr
    }


	
	progress$inc(2/n, detail = paste("Writing out rasters ... "))
	# write them spi rasters to 'spi' folder
	if("spi" %in% rnames) stop("spi folder already exists, either remove or move it")
	dir.create(paste0(dirname(dir), "/spi",
		sprintf("/spi%dmo_%d%s-%d%s", scale, startingyr, startmo0, endingyr, endmo0)))
	outputdir <- paste0(dirname(dir), "/spi",
		sprintf("/spi%dmo_%d%s-%d%s", scale, startingyr, startmo0, endingyr, endmo0))

	vizdir <- paste0(dirname(dirname(dir)), "/visualize/spi") 

	lapply(seq(from=moStarted, to=moElapsed), function(layer) {
		data <- sapply(l, function(x) {
				x[layer]
			})
		r <- ref
		values(r) <- data
		crs(r) <- coordref
		origin(r) <- orig
		fileName <- paste0(outputdir, "/spi_", fnames[layer])
		writeRaster(r, fileName, format="GTiff", overwrite="TRUE")
	})

	#Copy the output spi folders from "/process/spi" folder to the "/visualize/spi" folder
  	file.copy(from=outputdir, to=vizdir, 
          overwrite = TRUE, recursive = TRUE, 
          copy.mode = TRUE)

	progress$inc(2/n, detail = paste("Done!"))
}

