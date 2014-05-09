Data
=====

Goal: Find appropriate data set for project

Requirements:
-------------
* Multiple individuals/populations of a single species
* Body mass for individuals/populations
* Sufficient temporal resolution (50+ years)
* Sufficient spatial resolution (continent-wide?)



Possible datasets:
--------------
* GBIF: only occurrence data, no mass/body size information
http://www.gbif.org/occurrence

* Berkeley Museum data via Ecoengine API, no mass/body size information? 
http://ropensci.org/blog/2014/01/29/ecoengine/

* Museum of Vertebrate Zoology at Berkely via Berkeley Museum API, no mass/body size information, but it’s difficult to use their collections search 
http://mvz.berkeley.edu/Mammal_Collection.html

* Smithsonian National Museum of Natural History collections via Hallgrimsson & Maiorana (1999), should have body mass, but how to filter by that? Looked at mammal collection. Have mass and location (lat & long) info for some. Can export data as CSV. 
Mammal collection: http://collections.nmnh.si.edu/search/mammals/ 

* The LTER database was recommended by Morgan 3/21/14. Haven't looked at it much yet. 
https://portal.lternet.edu/nis/discover.jsp



R code exploration:
----------------
Purpose: find a species with a sufficient number of individuals from the Smithsonian database by importing CSV files into R and looking for # of occurrences of following things:
* how many with mass 
* how many with decimal degrees (Lat / Long)
* how many with county level or more specific locality info (need county)
* how many with mass and locaality
* distribution of years
* spatial extent


Possible species:
--------------
List from Morgan, email 3/24/14

1. _Peromyscus maniculatus_

   Done:
  * In NMNH database, search for Scientific Name ("Peromyscus maniculatus"), Country ("United States"), Measurements ("Weight"); got 1000+ hits
  * Export as CSV
  * Filter list using "Data Collected" column according to oldest to newest. Date range: 1919-2011
  * Size or location: Determine how many hits have mass (282), latitude (32), county (915)
  * Size and location: Have 282 specimens that have mass and county or latitude info
  * Spatial spread: Create map that shades in counties that have specimens
  * Change county into latitude and longitude, range of latitude is 20*

   To do:
  * Need to determine temporal spread
  * Need to determine if temporal plus spatial spread is sufficient, e.g., can't have only data from 50 years ago in a single location
  * Incorporate specimens from outside United States--300 specimens from Canada and Mexico.

2. _Dipodomys ordii_

3. _Sciurus carolinensis_

4. _Tamiasciurus hudsonicus_

5. _Tamias striatus_


Abiotic data:
-----------
Need temperature data. Requirements: 

1. Determine temperature using latitude/longitude and date?
2. County-level at minimum
3. Need temperature data that goes back to 1950s at minimum
4. Be able to put data into R

Possible temperature sources:
* US Historical Climatology Network http://cdiac.esd.ornl.gov/epubs/ndp/ushcn/ushcn.html 
* List of temperature resources from NOAA: http://www.esrl.noaa.gov/psd/data/faq/
    - Most of these datasets go back 20 years or less
    - Automated weather observing systems (http://www.ncdc.noaa.gov/data-access/land-based-station-data/land-based-datasets/automated-weather-observing-system-awos)has data starting from 1901; have files in .gz format under "Direct FTP Format"
* Looked for datasets with Dan 4/8/14, but didn't work for reasons in parentheses: WorldClim (50 yr average temp), CRU (don't remember), Tree Ring Grid (only Western US)
* NOAA Gridded Climate Datasets listed here: http://www.esrl.noaa.gov/psd/data/gridded/tables/temperature.html
    - GHCN_CAMS seemed right (sufficient spatial and temporal resolution), but dataset doesn't appear to be there, email about it
    - Using University of Delaware temperature dataset: http://www.esrl.noaa.gov/psd/data/gridded/data.UDel_AirT_Precip.html 
    - For .nc files, use ~~rgdal package~~ ~~ncdf package~~ raster to read into R
      - Can use Ncview program (http://meteora.ucsd.edu/~pierce/ncview_home_page.html) to look at and do simple visualizations of .nc netCDF files
      - Description of netCDF files here: https://www.image.ucar.edu/GSP/Software/Netcdf/ 
      - Must download netCDF library to read in netCDF files, first link here (Java library v4): http://www.unidata.ucar.edu/downloads/netcdf/index.jsp

Summer to do:
----------
* Improve existing code from Plant Community Eco project
    - Fix code to find lat/lon from county information with Google function to ensure it's accurate. Some county info lead to wrong lat/lons in England and US, just removed these values from the analysis for presentation but other coordinates could be wrong with no way to tell. 
    - Update code to strip out mass values from Measurements string in the better way
    - Add code to strip out length values if mass not available, use allometric relationship to convert to mass
* Add in Mexico & Canada data for Peromyscus 
* Separate out temporal and spatial scale data
* Repeat with more common species (see "Possible species" list above)
* Plant Community Eco presentation suggestion: average temperatures for locations for more reasonable ecological time period (e.g., 5 years, 10 years?) than just using current time. Organisms will be responding to past temperatures. 

Getting coordinates:
-----------
* Geocode function in R goes through Google Maps, and they limit queries to 2,500 a day. This isn't currently a problem with a single species, but it will be a problem with many species because will definitely exceed that limit. 
* Possible solutions:
    - Combo of createMaps and memoise? Don't quite understand how that would work yet. See third bullet here: http://cran.r-project.org/web/packages/toaster/NEWS 
    - Geonames file and MySQL? See Steve's comment: http://rollingyours.wordpress.com/2013/03/20/geocoding-r-and-the-rolling-stones-part-1/  He also mentions that there are unlimited geocoding services. 
    - Geopy in Python using Yahoo instead because the limit is 50,0000. http://stackoverflow.com/questions/8713309/r-yahoo-bing-or-other-alternatives-to-google-earth-for-geocoding
* Geocode also takes a long time (~15 minutes for ~1,000 queries)
* For now, just used geocode function but added in all location information (just had county before which resulted in a few coordinates outside the US), seems to have fixed the problem. 
    - Still had a few unusual temperatures outputs in the end, with temps below 0*C. These were because the collection date was after the time range available for the temperature. I already put some code in to deal with this but hadn't run it. 




