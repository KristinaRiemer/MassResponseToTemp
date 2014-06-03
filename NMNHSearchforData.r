######## useful functions from meeting w/ Dan 3/21/14 -------

## str function retrieves types of information in each column of dataset
str(dat)

## dim function shows number of rows and columns in dataset
dim(dat)

## names function shows column headers
names(dat)

## use $ to subset Measurements column from dataset
## as.character function turns all data entries into strings
dat$Measurements = as.character(dat$Measurements)


######## get temp v. mass plot for single example species (P. maniculatus) ----------
# read in csv with data
species1 = read.csv('./PeromyscusmanDataNMNH.csv')

## convert county info to latitude/longitude using geocode, only run last line ---------------
# improve accuracy by including state name with geocode function
# improve accuracy even more by using state & county to get FIPS and then get coordinates
library(ggmap)
# Google limits use of geocode to 2,500 queries per day--could be a problem later on, see
# markdown file about this
latlon = geocode(paste(species1$Country, species1$Province.State, species1$District.County), output = 'latlon')
write.table(latlon, "LatLonSpecies1.csv", sep = ",")
LatLonSpecies1 = read.csv("./LatLonSpecies1.csv")

# check coordinates to make sure they're all in the USA
library(maps)
map('world')
points(LatLonSpecies1, col = 'red')
map('usa')
points(LatLonSpecies1, col = 'red')

## convert county info to latitude/longitude using Census information -----------
# read in county-coordinate table from US Census website http://www.census.gov/geo/maps-data/data/gazetteer2013.html
# need to check entire file to ensure it's output correctly
county_to_coord_data = read.table("CensusFile.txt", sep = "\t", fileEncoding = "latin1", fill = TRUE)
county_to_coord_data = subset(county_to_coord_data, select = c("V1", "V4", "V9", "V10"))

# add column to specimen dataframe that contains state abbreviations, returns NA if no state
State.Abbreviation = state.abb[match(species1$Province.State, state.name)]
species1 = cbind(species1, State.Abbreviation)

# use data.table package to lookup coordinates for specimens from Census file
lookup_specimen = data.table(species1, key = "State.Abbreviation,District.County")
lookup_coord = data.table(county_to_coord_data, key = "V1,V4")
end_coord = merge(lookup_specimen, lookup_coord, all = TRUE)

## summary matrix of relevant info (lat/long, date, mass) ---------------------

# loop to remove everything from Measurements column except mass
# str_match example: http://stackoverflow.com/questions/952275/regex-group-capture-in-r
library(stringr)
masses = vector()
for (current_row in species1$Measurements){
  mass_match = str_match(current_row, "Specimen Weight: ([0-9.]*)g")
  mass = as.numeric(mass_match[2])
  masses = append(masses, mass)
}

# loop to remove total length value from Measurements column
lengths = vector()
for (current_row in species1$Measurements){
  length_match = str_match(current_row, "Total Length: ([0-9.]*)mm")
  length = as.numeric(length_match[2])
  lengths = append(lengths, length)
}

# find specimens that have length but not mass
size_values = cbind(masses, lengths)

# loop attempt
# empty vector
calc_mass = vector()
# loop through table with masses & lengths for each specimen
for (i in 1:nrow(size_values))
  # determine which specimens have length but not mass
  if(is.na(size_values[i,1]) & !is.na(size_values[i,2])) {
    # for those specimens, show 1
    calc_mass = size_values[,2] * 0.14
  } else {
    # for the rest of the specimens, return NA
    NA
  }

# incorporate newly calculated mass values in with provided mass values in "masses"


# test of loop b/c no specimens have length but not mass
test_sizes = matrix(c(10,NA,10,NA,10,10), nrow = 3)
test_sizes

test_mass = vector()
for (i in 1:nrow(test_sizes))
  if(is.na(test_sizes[i,1]) & !is.na(test_sizes[i,2])) {
    test_mass = test_sizes[,2] * 0.14
  } else {
    NA
  }
test_mass

# remove everything but year from Date.Collected column
species1$Date.Collected = as.character(species1$Date.Collected)
year = substr(species1$Date.Collected, nchar(species1$Date.Collected)-3, nchar(species1$Date.Collected))

# convert year to stackID (time format used in temperature dataset)
year = as.numeric(year)
stackID = year * 12 - 22793

# final summary with year, stackID, lat/lon, mass
PrelimSummaryTable = cbind(year, stackID, LatLonSpecies1, species1[32])
FinalSummaryTable = cbind(stackID, LatLonSpecies1, masses)
# remove specimens that lack mass
FinalSummaryTable = na.omit(FinalSummaryTable)
# remove specimens with collection date after 2010 because temp data not available
FinalSummaryTable = subset(FinalSummaryTable, FinalSummaryTable$stackID < 1327)

## use temperature data to determine temperatures for lat/lon/date of specimens -------
# code from Dan 4/8/14
library(raster)

# use loop to determine temperature for all specimens
extracted_temps = NULL
for (i in 1:nrow(FinalSummaryTable)){
  temp = raster('air.mon.mean.v301.nc', band=FinalSummaryTable$stackID[i])
  coordinate = cbind(FinalSummaryTable$lon[i] + 360, FinalSummaryTable$lat[i])
  single_specimen_temp = extract(temp, coordinate)
  extracted_temps = append(extracted_temps, single_specimen_temp)
}


## plot temperature-mass relationship -----------------------------------------
# create matrix with temps and corresponding masses
plot_table = cbind(extracted_temps, FinalSummaryTable$masses)

# plot this
plot(plot_table, xlab = "Temperature (*C)", ylab = "Body Mass (g)")

# plot linear regression of temp and mass
linreg = lm(plot_table[,2] ~ plot_table[,1])
summary(linreg)
abline(linreg)

## creating file with all specimens from Smithsonian mammals collection --------

# combine individual family files into single file

# change directory to SmithsonianFamilyData folder
setwd("/Users/kristinariemer/Documents/Documents/Graduate School/Year 1/BergRuleClimateProject/SmithsonianFamilyData/")
# create list of all family file names in SmithsonianFamilyData folder
family_filenames = list.files()
# read in all family files and concatenate into single file
# threw error when all_species_data.csv was being put into SmithsonianFamilyData folder
all_species_data = do.call("rbind", lapply(family_filenames, read.csv, header = TRUE, row.names = NULL))

# change directory back to BergRuleClimateProject folder to put new .csv file there
setwd("/Users/kristinariemer/Documents/Documents/Graduate School/Year 1/BergRuleClimateProject/")
# create dataframe containing all species files info
# write.table removes rows, but write.csv does not
write.csv(all_species_data, file = "all_species.csv")
# read in dataframe
all_species = read.csv("all_species.csv")

  
