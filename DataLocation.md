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
  * In NMNH database, search for Scientific Name ("Peromyscus maniculatus"), Country ("United States"), Measurements ("Weight"); got 1000+ hits
  * Export as CSV
  * Filter list using "Data Collected" column according to oldest to newest. Date range: 1919-2011
  * Determine how many hits have mass (282), latitude (32), county (915)
  * Need to determine what the spatial spread is like, and how to determine species that have multiple desired information (e.g., how many species have both mass and county info)
  * Have almost 300 specimens that have mass and county or latitude info. Need to determine spatial and temporal spread of this data to determine if this species will suffice. Change county into latitude? Some way to visually display location?
  * Could use specimens from outside of the United States. 300 specimens from Canada and Mexico, may be useful to include. 
2. _Dipodomys ordii_
3. _Sciurus carolinensis_
4. _Tamiasciurus hudsonicus_
5. _Tamias striatus_
