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

# to view sections of dataframes beyond 1,000 rows
View(dataframe.name[1xxx:2xxx,])


######## get temp v. mass plot for single example species (P. maniculatus) ----------

## convert county info to latitude/longitude using Census information -----------

# read in csv with specimen data
species1 = read.csv('./PeromyscusmanDataNMNH.csv')

# read in county-coordinate table from US Census website http://www.census.gov/geo/maps-data/data/gazetteer2013.html
# need to check entire file to ensure it's output correctly
county_to_coord_data = read.table("CensusFile.txt", sep = "\t", fileEncoding = "latin1", fill = TRUE, stringsAsFactors = FALSE)
# change coordinate columns from character to numeric
county_to_coord_data = transform(county_to_coord_data, V9 = as.numeric(V9))
county_to_coord_data = transform(county_to_coord_data, V10 = as.numeric(V10))

# remove columns that contain unnecessary information
county_to_coord_data = subset(county_to_coord_data, select = c("V1", "V4", "V9", "V10"))
# rename columns
colnames(county_to_coord_data) = c("Abbreviation", "County.Name", "Latitude", "Longitude")

# add column to Census file dataframe that contains entire state name
# create column with full state name for each row
State.Fullname = state.name[match(county_to_coord_data$Abbreviation, state.abb)]
# add this column to Census file dataframe
county_to_coord_data = cbind(county_to_coord_data, State.Fullname)

# use match function to lookup coordinates for each specimen using Census file
final_specimen_coords = county_to_coord_data[match(interaction(species1$Province.State, species1$District.County), interaction(county_to_coord_data$State.Fullname, county_to_coord_data$County.Name)), ]
final_specimen_coords = subset(final_specimen_coords, select = c(Longitude, Latitude))

# change final coordinates from dataframe to matrix to plot it
final_specimen_coords = data.frame(final_specimen_coords, stringsAsFactors = FALSE)
final_specimen_coords = as.matrix(final_specimen_coords)

# check coordinates to make sure they're all in the USA
library(maps)
map('world')
points(final_specimen_coords[,1], final_specimen_coords[,2], col = 'red')
map('usa')
points(final_specimen_coords[,1], final_specimen_coords[,2], col = 'red')

# add final coordinates to specimen data
rownames(final_specimen_coords) = NULL
species1 = cbind(species1, final_specimen_coords)

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

# # loop attempt
# # empty vector
# calc_mass = vector()
# # loop through table with masses & lengths for each specimen
# for (i in 1:nrow(size_values))
#   # determine which specimens have length but not mass
#   if(is.na(size_values[i,1]) & !is.na(size_values[i,2])) {
#     # for those specimens, show 1
#     calc_mass = size_values[,2] * 0.14
#   } else {
#     # for the rest of the specimens, return NA
#     NA
#   }
# 
# # incorporate newly calculated mass values in with provided mass values in "masses"
# 
# 
# # test of loop b/c no specimens have length but not mass
# test_sizes = matrix(c(10,NA,10,NA,NA,10,10,10), nrow = 4)
# test_sizes
# 
# test_length_nomass = sum(is.na(test_sizes[,1]) & !is.na(test_sizes[,2]))
# 
# test_mass = vector()
# for (i in 1:nrow(test_sizes))
#   if(is.na(test_sizes[i,1]) & !is.na(test_sizes[i,2])) {
#     test_mass = test_sizes[,2] * 0.14
#   } else {
#     NA
#   }
# test_mass

# remove everything but year from Date.Collected column
species1$Date.Collected = as.character(species1$Date.Collected)
year = substr(species1$Date.Collected, nchar(species1$Date.Collected)-3, nchar(species1$Date.Collected))

# convert year to stackID (time format used in temperature dataset)
year = as.numeric(year)
stackID = year * 12 - 22793

# initial summary with year, stackID, lat/lon, entire Measurements column
PrelimSummaryTable = cbind(year, stackID, final_specimen_coords, species1[32])
# final summary with year (raster format), coordinates, masses for each specimen
FinalSummaryTable = cbind(stackID, final_specimen_coords, masses)

# remove specimens that lack mass
FinalSummaryTable = na.omit(FinalSummaryTable)
# remove specimens with collection date after 2010 because temp data not available
FinalSummaryTable = subset(FinalSummaryTable, FinalSummaryTable[,1] < 1327)
# turn into dataframe
FinalSummaryTable = data.frame(FinalSummaryTable)

## use temperature data to determine temperatures for lat/lon/date of specimens -------
# code from Dan 4/8/14
library(raster)

# use loop to determine temperature for all specimens
extracted_temps = NULL
for (i in 1:nrow(FinalSummaryTable)){
  temp = raster('air.mon.mean.v301.nc', band=FinalSummaryTable$stackID[i])
  coordinate = cbind(FinalSummaryTable$Longitude[i] + 360, FinalSummaryTable$Latitude[i])
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

