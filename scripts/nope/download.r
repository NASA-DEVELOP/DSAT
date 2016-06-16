require(RCurl)
url <- "ftp://hydro1.sci.gsfc.nasa.gov/data/s4pa/NLDAS/NLDAS_MOS0125_M.002/"
list <- getURL(url, dirlistonly=T)
files <- strsplit(list, "\r\n")
years <- files[[1]][4:length(files[[1]])]

for (i in seq(length(years))) {
	url_year <- paste0(url, years[i], "/")
	filelist_year <- getURL(url_year, dirlistonly=TRUE)
	filelist_year <- strsplit(filelist_year, "\r\n")[[1]]
	dir.create(years[i])
	for (j in seq(length(filelist_year))) {
		url_year_file <- paste0(url_year, filelist_year[j])
		destfile <- paste0(years[i], "/", filelist_year[j])
		download.file(url_year_file, destfile)
	}
}