# variables.path 
# run.name
# setwd(variables.path)
require(raster)


# Create the Data table == == == == == === == == == == === == == === == == == == 

# make var list 
varlist <- list.files(pattern = '*.tif$')
varlist <- varlist[10:length(varlist)]

# get # of pixels from variable folder
forpixels <- raster(varlist[1])
pixels <- nrow(forpixels) * ncol(forpixels)

# initialize prediction table based on those pixels above
unseen.table <- matrix(0, pixels, length(varlist))

# make prediction table
unseen.table <- lapply(seq(length(varlist)), 
	function(a){
		unseen.table[,a] <- c(as.matrix(raster(varlist[a])))
		# unseen.table[,a][is.na(unseen.table[,a])]  <- -99
	}
)
unseen.table <- as.data.frame(do.call('cbind', unseen.table))

# create variable names (remove '.tif')
varnames <- substr(varlist, 1, nchar(varlist) - 4)

# create col headers
for(k in seq(length(varnames))){
	colnames(unseen.table)[k] <- varnames[k]
}
unseen.table[is.na(unseen.table)] <- -99

# Output unseen.table to folder containing variables.path (the rfc folder)
#filename3 <- paste(substr(variables.path, 1, nchar(variables.path) - 3), 'kmcluster.csv' , sep='')
#write.csv(unseen.table, filename3, row.names = FALSE)

# Kmeans Cluster == == == == == === == == == == === == == === == == == == == == 

# kmeans
centers <- 5
km <- kmeans(as.matrix(unseen.table), centers = centers)

# .. to raster
# km.raster <- raster(matrix(km$cluster, nrow = nrow(forpixels), ncol=ncol(forpixels), byrow=FALSE))
vals <- matrix(km$cluster, nrow = nrow(forpixels), ncol=ncol(forpixels), byrow=FALSE)
# km.raster <- c(km.raster) 
km.raster <- forpixels
values(km.raster) <- vals

# Get raster sample for the proj and extent from var list first entry
raster.sample <- raster(varlist[1])
extent(km.raster) <- c(raster.sample@extent@xmin, raster.sample@extent@xmax, raster.sample@extent@ymin, raster.sample@extent@ymax)
projection(km.raster) <- CRS(raster.sample@crs@projargs)

# output raster in folder containing variables.path
outrastername <- paste('temp_cluster.tif' , sep='')
writeRaster(km.raster, outrastername, formats = 'GTiff', overwrite=TRUE)

# --------------------------
# make the line graph by class
# --------------------------
require(reshape2)
require(ggplot2)

nclasses <- 5
linedf <- data.frame( matrix(rep(NA, nclasses*length(varlist)), ncol=nclasses) )
classlist <- lapply(seq(length(varlist)), function(x) {
	classes <- c()
	for(i in seq(nclasses)) {
		classes <- c(classes, mean(getValues(brick[[x]])[getValues(km.raster) == i]))
	}
	return(classes)
})

for(i in seq(nclasses)) {
	class <- sapply(classlist, function(x) {
		x[i]
	})
	linedf[i] <- class
}
linedf$id <- seq(length(varlist)) 
linedflong <- melt(linedf, id="id")
ggplot(data=linedflong, aes(x=id, y=value, colour=variable)) + geom_line()


write.table(linedf, "classes.txt",sep="\t",row.names=FALSE)