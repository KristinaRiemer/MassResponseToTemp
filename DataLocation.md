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
    - University of Delaware precipitation dataset will probably also work
    - For .nc files, use ~~rgdal package~~ ncdf package to read into R
      - Can use Ncview program (http://meteora.ucsd.edu/~pierce/ncview_home_page.html) to look at and do simple visualizations of .nc netCDF files
      - Description of netCDF files here: https://www.image.ucar.edu/GSP/Software/Netcdf/ 
