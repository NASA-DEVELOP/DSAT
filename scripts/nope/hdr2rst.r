# hdr2rst
# converts a file containing all ENVI files to rst
# INPUT: 
# dir   (optional) directory path containing all your envi riles to IDRISI
#		the default is that it assumes the current directory
# requires raster package

hdr2rst <- function(dir="current") {
	if(!require(raster)) stop("Install the raster package")
	if(dir == "current") {
		files <- list.files()
		if("rst" %in% files) stop("rst directory exists, delete or move it.")
		dir.create("rst")
	} else {
		files <- list.files(dir)
		if("rst" %in% files) stop("rst directory exists, delete or move it.")
		dir.create(paste0(dir, "/rst"))
	}
	filesNotHdr <- files[grep("*.hdr$", files, invert=T)]
	n <- length(filesNotHdr)
	pb <- winProgressBar(title = "Progress bar", min = 0, max = n, width = 300)
	 
	for (i in seq(n)) {
		if(dir == "current") {
			file <- paste0("rst/", filesNotHdr[i], ".rst")
			r <- raster(filesNotHdr[i])
			writeRaster(r, filename=file, format="IDRISI")
		} else {
			file <- paste0(dir, "rst/", filesNotHdr[i], ".rst")
			r <- raster(paste0(dir, filesNotHdr[i]))
			writeRaster(r, filename=file, format="IDRISI")
		}
		setWinProgressBar(pb, i, title=paste(round(i/n*100, 0), "% done"))
	}
	close(pb)
	cat("Done. They're in the 'rst' folder.\n")
}
