# DSAT
Drought Severity Assessment Tool (formerly Drought Severity Assessment - Decision Support Tool)

NASA DEVELOP Summer 2016 | Navajo Nation Climate

##Introduction

The Navajo Nation currently makes drought mitigation decisions based on Western Regional Climate Center SPI values calculated for US State based climate divisions. This does not provide adequate information for proper resource management. This tool will provide SPI rasters for the Navajo Nation, and allow them to calculate their own average SPI values for boundaries of their choice.

##Applications and Scope

The application will be used by Navajo Nation Department of Water Resource Managers for their monthly drought reports and other activities related to drought monitoring within the region. With small adjustments it is possible for the tool to be used in other locations given the user has already downloaded and processed the proper precipitation data.

##Capabilities

This tool calculates 1-, 6-, or 12- month SPI values cell by cell from monthly precipitation rasters outputting SPI rasters of the area. These SPI rasters can then be processed using our tool, to output zonal statistics based on user-specified boundary layers. DSAT 2.0 provides streamlined functionality and improved an user-interface design. For example, the water managers can use these zonal statistics to calculate average SPI values for agencies (analogous to US states) within the Navajo Nation to create drought severity maps, supporting resource allocation decisions. This customized regional drought assessment was not available before.

##Interfaces

This tool uses the open source statistical program R for the data processing, and the R package Shiny for the user interface. The end user will install and run the software on their desktop.

##Additional Information

###For the tool to run....

To get started, it is recommended that you first read through the manual for step-by-step instructions and more in-depth descriptions of the DSAT's functionalities. The manual is located in the DSAT 2.0 branch. 

###For a quick start-up
1) Ensure that the DSAT 2.0 folder are dragged to your computer's C:/ drive
2) Ensure that you have downloaded Rstudio version at least 3.3.0
3) Open the Open.R file (located in the DSAT 2.0 folder) within Rstudio
4) Click "Run App"
5) Continue with the installation instructions detailed in the manual

From there, you ca
1) Download the latest CHIRPS data
2) Calculate SPI for a specific time period and time scale using the CHIRPS data
3) Generate summary statistics for the SPI data
4) Visualize the SPI data
