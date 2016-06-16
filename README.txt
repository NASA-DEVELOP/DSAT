For the tool to run....
1) developnn/data/visualize/spi and developnn/data/process/spi must both have at LEAST one tiff file of the same extent in their folders. They only serve as a place holder.

To update the database to include the latest CHIRPS data
2) go to the download tab and click download!

To calculate SPI....
3) Move data from developnn/data/downloadGPM/clipped to developnn/data/process/precip

To visualize the data...
4) After SPI has been calculated, delete the spi folders located in developnn/data/process and developnn/data/visualization
5) Copy the entire SPI folder from within developnn/data/process/precip to developnn/data/process and developnn/data/visualization (replacing the old folders)
6) Close and restart DSAT. Visualization should now show the most up to date data

Note: when you update the database to include new CHIRPS data, the entire SPI dataset must be recalculated. To reset...
7) delete the developnn/data/process/precip/spi folder
8) Download new files using the download CHIRPS tool
9) move the newly downloaded and clipped CHIRPS data to precip
10)Run the calculate SPI tool
11)Return to step 3