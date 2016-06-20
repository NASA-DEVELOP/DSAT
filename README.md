# DSAT
Drought Severity Assessment Tool (formerly Drought Severity Assessment - Decision Support Tool)

NASA DEVELOP Summer 2015 | Navajo Nation Climate

##Introduction

The Navajo Nation currently makes drought mitigation decisions based on Western Regional Climate Center SPI values calculated for US State based climate divisions. This does not provide adequate information for proper resource management. This tool will provide SPI rasters for the Navajo Nation, and allow them to calculate their own average SPI values for boundaries of their choice.

##Applications and Scope

The application will be used by Navajo Nation Department of Water Resource Managers for their monthly drought reports and other activities related to drought monitoring within the region. With small adjustments it is possible for the tool to be used in other locations given the user has already downloaded and processed the proper precipitation data.

##Capabilities

This tool calculates 1-, 3-. 6-, 12-, or 24- month SPI values cell by cell from monthly precipitation rasters outputting SPI rasters of the area. These SPI rasters can then be processed using our tool, to output zonal statistics based on user-specified boundary layers. For example, the water managers can use these zonal statistics to calculate average SPI values for agencies (analogous to US states) within the Navajo Nation to create drought severity maps, supporting resource allocation decisions. This customized regional drought assessment was not available before.

##Interfaces

This tool uses the open source statistical program R for the data processing, and the R package Shiny for the user interface. The end user will install and run the software on their desktop.

##Additional Information

###For the tool to run....

1) developnn/data/visualize/spi and developnn/data/process/spi must both have at LEAST one tiff file of the same extent in their folders. They only serve as a place holder.

###To update the database to include the latest CHIRPS data
2) go to the download tab and click download!

###To calculate SPI....
3) Move data from developnn/data/downloadGPM/clipped to developnn/data/process/precip

###To visualize the data...
4) After SPI has been calculated, delete the spi folders located in developnn/data/process and developnn/data/visualization
5) Copy the entire SPI folder from within developnn/data/process/precip to developnn/data/process and developnn/data/visualization (replacing the old folders)
6) Close and restart DSAT. Visualization should now show the most up to date data

###Note: when you update the database to include new CHIRPS data, the entire SPI dataset must be recalculated. To reset...
7) delete the developnn/data/process/precip/spi folder
8) Download new files using the download CHIRPS tool
9) move the newly downloaded and clipped CHIRPS data to precip
10)Run the calculate SPI tool
11)Return to step 3
