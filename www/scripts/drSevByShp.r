# drSevByShp
# Drought Severity by shapefile zone
# basically a zonal statistics wrapper to 
# calculate zonal stats
# Inputs:
#	shp		SpatialPolygonsDataFrame
#	raster  raster of interest
#	aORc	string, agency or chapter
#	progress object for shiny


drSevByShp <- function(shp, raster, aORc, progress=NULL) {
	if(!require(rgdal)) stop("install rgdal package")
	if(!require(raster)) stop("install raster package")
	# if(!require(reshape2)) stop("install reshape2 package")
	# filelist <- list.files(dir, full.names=TRUE)
	# if(length(filelist) == 0) stop("empty directory")
	# s <- shapefile(shp)

	# prep the shapefile, leave out <null> attr instances, rasterize

	# Note: this is needed because readOGR ESRI shapefile driver
	# shaves off attribute field names to 10 characters, so need to 
	# do the same here to match it.
	# attrib <- substr(attrib, 1, 10)
	# if(!(attrib %in% names(s@data))) stop("Attribute given not found in shapefile")
	
	# s <- shapefile(shp)
	shpDF <- shp@data
	tempRaster <- raster
	r <- raster
	# --- okay --- get zones
	zones <- rasterize(shp, tempRaster, field="OBJECTID")
	# --- prep classes ---  
	r[r <= -2.0] <- -3            #extremely dry
	r[r > -2.0 & r <= -1.5] <- -2 #severely dry
	r[r > -1.5 & r <= -1.0] <- -1 #moderate dry
	r[r > -1.0 & r <= 1.0] <- 0   #near normal
	r[r > 1.0 & r <= 1.5] <- 1    #moderate wet
	r[r > 1.5 & r <= 2.0] <- 2    #severely wet
	r[r > 2.0] <- 3               #extremely wet

	fillname <- shpDF$OBJECTID
	if(aORc == "agency") {
		shpDF$Agency_Nam <- as.character(shpDF$Agency_Nam)
		names(fillname) <- shpDF$Agency_Nam
		rem <- which(is.na(shpDF$Agency_Nam))
	} else if(aORc == "chapter") {
		shpDF$Chapter_NA <- as.character(shpDF$Chapter_Na)
		names(fillname) <- shpDF$Chapter_Na
		rem <- which(is.na(shpDF$Chapter_Na))
	} else if(aORc == "eco3") {
	  shpDF$US_L3NAME <- as.character(shpDF$US_L3NAME)
	  names(fillname) <- shpDF$US_L3NAME
	  rem <- which(is.na(shpDF$US_L3NAME))
	} else if(aORc == "eco4") {
	  shpDF$US_L4NAME <- as.character(shpDF$US_L4NAME)
	  names(fillname) <- shpDF$US_L4NAME
	  rem <- which(is.na(shpDF$US_L4NAME))
	} else if(aORc == "water_sheds") {
	  shpDF$NAME <- as.character(shpDF$NAME)
	  names(fillname) <- shpDF$NAME
	  rem <- which(is.na(shpDF$NAME))
	} 
	
	if(length(rem) != 0)
  		zones[zones==rem] <- NA
	ct <- crosstab(r, zones)

	# remove NA in var1 and var2
	result <- ct[!is.na(ct$Var1) & !is.na(ct$Var2),]

	# get freq to form totals
	shpFREQ <- freq(zones)
	shpFREQ <- as.data.frame(shpFREQ)
	shpFREQ <- shpFREQ[!is.na(shpFREQ$value) & !is.na(shpFREQ$count),]

	#totals
	result$total <- NA
	filltotal <- shpFREQ$count
	names(filltotal) <- shpFREQ$value

	# fill in total pixels for each agency
	for(i in seq(nrow(shpFREQ)))
	  result$total[result$Var2 == as.numeric(names(filltotal)[i])] <- filltotal[i]
	
	result$frac <- result$Freq/result$total
	result$perc <- round(result$frac * 100, digits=1)
	result$perclab <- paste0(as.character(result$perc), "%")

	result$class <- NA
	result$class[result$Var1 == -3] <- "extremely dry"
	result$class[result$Var1 == -2] <- "severely dry"
	result$class[result$Var1 == -1] <- "moderately dry"
	result$class[result$Var1 == 0]  <- "near normal"
	result$class[result$Var1 == 1]  <- "moderately wet"
	result$class[result$Var1 == 2]  <- "severely wet"
	result$class[result$Var1 == 3]  <- "extremely wet"

	result$name <- NA
	for(i in seq(length(fillname))) 
	  result$name[result$Var2 == fillname[i]] <- names(fillname)[i]

	return(result)
	
	# n <- 10
	# progress$inc(2/n, detail = paste("Loading shapefile ... "))

	# # entries <-  c(t(s@data[attrib]))
	# # entriesRmNA <- entries[!is.na(entries)]
	# # nullAttr <- which(is.na(entries))
	# # if(length(nullAttr) > 0) 
	# # 	cat(paste("Removing attribute indices: ", nullAttr, "\n"))
	# # tempRaster <- raster(filelist[1])
	# # zones <- rasterize(s, tempRaster)
	# # zones[zones %in% nullAttr] <- NA

	# progress$inc(1/n, detail = paste("Loading rasters ... "))

	# #------------------------------------------
	# # zone baby zone. NA values in the raster is removed.
	# # spiStack <- stack(filelist)
	# # spiBrick <- brick(spiStack)

	# progress$inc(1/n, detail = paste("Calculating statistics ... "))
	
	# # make initial df for count and then fill in rest of statistics
	# # z <- zonal(spiBrick, zones, "count", na.rm=TRUE)
	# # zdf <- as.data.frame(z)
	# # zdf$name <- entriesRmNA
	# # df <- melt(zdf, id=c('name', 'zone'), 
	# # 				variable.name='rasters', 
	# # 				value.name="count")

	# progress$inc(4/n, detail = paste("Calculating statistics ... "))

	# # funcs <- c('mean', 'min', 'max', 'range', 'sd')
	# # l <- lapply(funcs, function(f) {
	# # 	z <- zonal(spiBrick, zones, f, na.rm=TRUE)
	# # 	zdf <- as.data.frame(z)
	# # 	tmpdf <- melt(zdf, id='zone')
	# # 	df[f] <<- tmpdf$value #assigning to global variable df
	# # })

	# progress$inc(2/n, detail = paste("Finished!"))
	# return(df)
}














