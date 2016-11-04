# zonalspi
# basically a zonal statistics wrapper to 
# calculate zonal stats
# Inputs:
# 	dir		string, directory containing all tifs
#	shp		string, shapefile path (polygon) defining zones
#	attrib 	string, the attribute field of the shapefile to carry over 
#			(any attr <null> will be left out)

zonalspi <- function(dir, shp, attrib, progress) {
	filelist <- list.files(dir, full.names=TRUE)
	if(length(filelist) == 0) stop("empty directory")
	s <- shapefile(shp)

	# prep the shapefile, leave out <null> attr instances, rasterize

	# Note: this is needed because readOGR ESRI shapefile driver
	# shaves off attribute field names to 10 characters, so need to 
	# do the same here to match it.
	attrib <- substr(attrib, 1, 10)
	if(!(attrib %in% names(s@data))) stop("Attribute given not found in shapefile")
	
	n <- 10
	progress$inc(2/n, detail = paste("Loading shapefile ... "))

	entries <-  c(t(s@data[attrib]))
	entriesRmNA <- entries[!is.na(entries)]
	nullAttr <- which(is.na(entries))
	if(length(nullAttr) > 0) 
		cat(paste("Removing attribute indices: ", nullAttr, "\n"))
	tempRaster <- raster(filelist[1])
	zones <- rasterize(s, tempRaster)
	zones[zones %in% nullAttr] <- NA

	progress$inc(1/n, detail = paste("Loading rasters ... "))

	# zone baby zone. NA values in the raster is removed.
	spiStack <- stack(filelist)
	spiBrick <- brick(spiStack)

	progress$inc(1/n, detail = paste("Calculating statistics ... "))
	
	# make initial df for count and then fill in rest of statistics
	z <- zonal(spiBrick, zones, "count", na.rm=TRUE)
	zdf <- as.data.frame(z)
	zdf$name <- entriesRmNA
	df <- melt(zdf, id=c('name', 'zone'), 
					variable.name='rasters', 
					value.name="count")

	progress$inc(4/n, detail = paste("Calculating statistics ... "))

	
	funcs <- c('mean', 'min', 'max', 'sd')
	l <- lapply(funcs, function(f) {
		z <- zonal(spiBrick, zones, f, na.rm=TRUE)
		zdf <- as.data.frame(z)
		tmpdf <- melt(zdf, id='zone')
		df[f] <<- tmpdf$value #assigning to global variable df
	})

	# had (unresolved) issues with built-in "range" function in the raster package 
	# workaround since min and max values were validated via ArcGIS
	df$range <- df$max - df$min

	progress$inc(2/n, detail = paste("Finished!"))
	return(df)
}
