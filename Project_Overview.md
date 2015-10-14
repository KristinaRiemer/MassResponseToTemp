### Current Project Summary

Gordon Conference 2014 project (complete):
Determined relationship between mass and temperature for xx mammal species in the United States. Used average July temperature for each individual's collection year. 

Temporal scaling/lag project (in progress):
This is intended to subsume and replace the previous project. Will determine relationship between mass and temperature for mammal species in the US, with possibility of expanding beyond the US and repeating analysis for non-mammal taxa. Currently using average July temperatures for each individual's collection year and each year previous until 1900, which is a yearly summer month lag. 


### Current File Summary

1. Script name: AssembleSmithsonianData.R (not in repo)  
Purpose: Put all Smithsonian mammals collection files (by family) into single csv  
Input files: Family-named files in SmithsonianFamilyData subfolder  
Output files: all_species.csv  

2. Script name: DatasetCleaningUS.R  
Purpose: Retain only individuals from mammals collection data that fulfill all following criteria:
  * Mass
  * Taxonomic ID down to species level
  * Location (latitude and longitude either in data or looked up using US county location)
  * Collection year
  * Is of a species for which there are 30+ individuals
  * Is of a species for which the individuals have 5+ latitudinal degree range
  * Is of a species for which the individuals have 20+ collection year range
   Input files: all_species.csv, CensusFile.txt (US county coordinates)  
   Output files: CompleteDatasetUS.csv  

3. Script name: TemporalScaling.py  
Purpose: Characterize mass-temp relationships for species using current year temperatures and all past years  
Input files: CompleteDatasetUS.csv, air.mon.mean.v301.nc (global temperature data)  
Output files: species mass-temp figures (in subfolder), all_stats_fig.pdf  

*Script name: NMNHSearchforData.r  
Purpose: Determine if Smithsonian mammals collection data will be sufficient for project  

*Script name: AllSpeciesAnalysis.R  
Purpose: Decide criteria for removing individuals and exploratory stats on mass-temp relationships for species using current year temperatures  

*Scripts still in repo but no longer needed
