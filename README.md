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
