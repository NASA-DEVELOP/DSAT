lapply(list.files(), function(x) {
  from <- x
  num <- substr(x, 7, nchar(a)-4)
  to <- paste0(num, "_PRISM.tif")
  file.rename(from=from, to=to)
})

#trim prism rasters
files <- list.files("prism/", full.names=TRUE)
nfiles <- list.files("prism/", full.names=FALSE)
ref <- raster(list.files("data/", full.names=TRUE)[1])
ref.extent <- extent(ref)
lapply(files, function(x) {
  t <- trim(raster(x))
  extent(t) <- ref.extent
  name <- substr(x, 7, nchar(x))
  writeRaster(t, paste0("prism_trim/", name), format='GTiff')
})

#reclassify rasters based on drought
files <- list.files("data_spi/", full.names=TRUE)
nfiles <- list.files("data_spi/", full.names=FALSE)
ref <- raster(list.files("data_spi/", full.names=TRUE)[1])
ref.extent <- extent(ref)
lapply(files, function(x) {
  r<-raster(x)
  r[r <= -2.0] <- -3 			#extremely dry
  r[r > -2.0 & r <= -1.5] <- -2 #severely dry
  r[r > -1.5 & r <= -1.0] <- -1 #mod dry
  r[r > -1.0 & r <= 1.0] <- 0 	#near norm
  r[r > 1.0 & r <= 1.5] <- 1 	#mod wet
  r[r > 1.5 & r <= 2.0] <- 2 	#severely wet
  r[r > 2.0] <- 3 				#extremely wet
  name <- substr(x, 10, nchar(x))
  writeRaster(r, paste0("data_spi_class/classed_", name), format='GTiff')
})

files <- list.files("data_spi/", full.names=TRUE)
nfiles <- list.files("data_spi/", full.names=FALSE)
ref <- raster(list.files("data_spi/", full.names=TRUE)[1])
ref.extent <- extent(ref)
lapply(files, function(x) {
  r<-raster(x)
  r[r <= -2.0] <- -3      #extremely dry
  r[r > -2.0 & r <= -1.5] <- -2 #severely dry
  r[r > -1.5 & r <= -1.0] <- -1 #mod dry
  r[r > -1.0 & r <= 1.0] <- 0   #near norm
  r[r > 1.0 & r <= 1.5] <- 1  #mod wet
  r[r > 1.5 & r <= 2.0] <- 2  #severely wet
  r[r > 2.0] <- 3         #extremely wet
  name <- substr(x, 10, nchar(x))
  writeRaster(r, paste0("data_spi_class/classed_", name), format='GTiff')
})

