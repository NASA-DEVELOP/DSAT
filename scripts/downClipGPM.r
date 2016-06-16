# downClipGPM.R
# from Anton Surunis (thanks!)
# NASA DEVELOP: Navajo Nation Climate Summer 2015
# 
# checks which gpm data is missing, fetches those missing, and
# clips it to the area of interest.

downClipGPM <- function(progress) { 
  #Checks if required packages are installed. If not, they are installed.
  list.of.packages <- c("rhdf5", "raster","rgdal","sp","httr","lubridate")
  new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
  if(length(new.packages)) install.packages(new.packages)

  #directories
  DIR_RAW     <- "data/downloadGPM/raw/"
  DIR_CLIPPED <- "data/downloadGPM/clipped/"

  #Loads required packages.
  library(rhdf5)
  library(raster)
  library(rgdal)
  library(sp)
  library(httr)
  library(lubridate)

  n <- 10
  progress$inc(1/n, detail = paste("Checking for new GPM Data"))
  enddate=Sys.Date()
  datecheck=format(Sys.Date(), "%d")
  #if (datecheck>27){
  #  enddate=Sys.Date()-days(10)
  #}
  
  #Creates list of dates from CHIRPS start date to current date.
  times <- seq(as.Date("1981-01-01"),enddate,by="1 month") #1981
  #Create function for building file names from given dates.
  make_names <- function(x) {
    strdate <- as.character(x)
    year    <- substring(strdate,1,4)
    month   <- substring(strdate,6,7)
    return(paste0(year,month,"_CHIRPS.tif"))
  }

  #Create list of file names for CHIRPS rasters.
  names <- make_names(times)

  #Function for creating necessary ftp links.
  makeftp_link <- function(x){
    strdate <- as.character(x)
    year    <- substring(strdate,1,4)
    month   <- substring(strdate,6,7)
    result  <- sprintf("ftp://ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/global_monthly/tifs/chirps-v2.0.%s.%s.tif.gz", year, month)
    return(result)
  }

  #Use function on list of dates to make list of links.
  links <- lapply(times, makeftp_link)
  #Check which files need to be downloaded.
  # setwd("C:/2015Su_ARC_NNClimate_FileStructure/GPM Data/Unprocessed Files")
  links <- links[!(substr(links,76,nchar(links))%in%list.files(DIR_RAW))]
  
  progress$inc(1/n, detail = paste("Checking for new data ..."))

  #Downloads all missing files, stopping when the first non-existent file is found.
  numDownloaded <- 0
  for(i in seq(links)) {
    url <- as.character(links[i])
    output_file <- substr(links[i],76,nchar(links[i]))
    output_file <- paste0(DIR_RAW, output_file)
    try({
      if(file.exists(substr(output_file,1,nchar(output_file)-3))=="FALSE"){
        GET(url, write_disk(output_file))
      }
      numDownloaded <- numDownloaded + 1
      progress$inc(0, detail = paste("Downloading", i+1, "of", length(links), "..."))
    }, silent=TRUE)

    #if(file.size(output_file) == 0){
    #  unlink(output_file)
    #  break
    #}
  }
  
  progress$inc(1/n, detail = paste("Finished Downloading ..."))

  #if(numDownloaded == 0)
  #  print("0.1")
  #  return(numDownloaded)
  #  print("0.2")


  progress$inc(2/n, detail = paste("Clipping the data to study area"))

  #List contents of unprocessed GPM folder.
  files <- list.files(DIR_RAW, full.names = TRUE)
  require(R.utils)
  library(R.utils)
  filelen=length(files)
  filecnt=0
  for (i in files) {
    filecnt=filecnt+1
    #if no data in file, delete it
    if(file.size(i)==0){
      file.remove(i)
    } else if(file.size(i)>0){
      if(substr(i,nchar(i)-2,nchar(i))==".gz")
        gunzip(i)
    }
  }
  files <- list.files(DIR_RAW, full.names = TRUE)
  
  GPMProcess <- function(GPMPrecip){
    ##Define boundaries.
    xmin = -180
    xmax = 180
    ymin = -50
    ymax = 50
    
    rast <- raster(GPMPrecip)
    
    #Define extent and projection of raster.
    extent(rast) <- c(xmin,xmax,ymin,ymax)
    projection(rast) <- CRS("+proj=longlat +datum=WGS84")
    #Create cropping boundary and crop raster. 
    e <- extent(c(-113.149999004,-104.349998873,33.2999997512,38.499149))
    cropped_rast <- crop(rast,e)
    return(cropped_rast)
  }
  progress$inc(1/n, detail = paste("Clipping the data to study area ..."))
  
  #Use GPMProcess function to read in hdf5 files, convert them to rasters, define their projections, and crop to a smaller extent.
  cropped <- lapply(files, GPMProcess)

  ##Use function to make names for files and clips to length of files.
  names <- names[1:length(files)]
  times <- times[1:length(files)]
  for(i in seq(length(names))){
    writeRaster(cropped[[i]], filename=paste0(DIR_CLIPPED, names[i]), format="GTiff", overwrite = TRUE)
  }

  progress$inc(4/n, detail = paste("Done."))
  return(numDownloaded)
}
