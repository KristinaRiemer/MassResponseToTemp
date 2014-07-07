## creating file with all specimens from Smithsonian mammals collection --------
############### only have to read in all_species.csv file now

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

#### determining number of specimens per species in entire dataset--------------------
total_species = unique(all_species$Current.Identification)
occurrences = table(all_species$Current.Identification)
occurrences = data.frame(occurrences)
count_occurrences = sum(occurrences$Freq>200)
# 478 species have more than 200 specimen records without cleaning up species list

### determine how many specimens from the all species list have length but no mass-----

# # loop to remove everything from Measurements column except mass (same code as above)
# # str_match example: http://stackoverflow.com/questions/952275/regex-group-capture-in-r
# library(stringr)
# masses = vector()
# # only change is from "species1$Measurements" to "all_species$Measurements"
# for (current_row in all_species$Measurements){
#   mass_match = str_match(current_row, "Specimen Weight: ([0-9.]*)g")
#   mass = as.numeric(mass_match[2])
#   masses = append(masses, mass)
# }

# # loop to remove total length value from Measurements column
# lengths = vector()
# # only change is from "species1$Measurements" to "all_species$Measurements"
# for (current_row in all_species$Measurements){
#   length_match = str_match(current_row, "Total Length: ([0-9.]*)mm")
#   length = as.numeric(length_match[2])
#   lengths = append(lengths, length)
# }
# 
# # find number of specimens that have length but not mass
# size_values = cbind(masses, lengths)
# length_nomass = sum(is.na(size_values[,1]) & !is.na(size_values[,2]))
# # only ~60,000 out of ~500,000 specimens have length but no mass

### determine how many species have at least 30 specimens with mass

#### extract mass values for each specimen and add to species file-------------
library(stringr)
masses = vector()
# only change is from "species1$Measurements" to "all_species$Measurements"
for (current_row in all_species$Measurements){
  mass_match = str_match(current_row, "Specimen Weight: ([0-9.]*)g")
  mass = as.numeric(mass_match[2])
  masses = append(masses, mass)
}

#create file with masses for all specimens
write.csv(masses, "all_species_masses.csv")
all_species_masses = read.csv("all_species_masses.csv")
all_species_masses = all_species_masses[,2]

#add masses to dataset file
all_species = cbind(all_species, all_species_masses)

#remove specimens with no mass from dataset
all_species = all_species[complete.cases(all_species[,45]),]
#went from ~450,000 to ~80,000 specimens

### clean up genus/species in Current.Identification column-------------------
#change column to character vector
all_species$Current.Identification = as.character(all_species$Current.Identification)
#remove everything but genus and species identifiers (first two words)
Species.Genus = word(all_species$Current.Identification, 1, 2)
#add new identifier to dataset
all_species = cbind(all_species, Species.Genus)

#remove all specimens whose identifiers are "xxx(genus) sp."
all_species$genus.only = grepl(".* sp.", all_species$Current.Identification)
all_species = all_species[all_species$genus.only == FALSE, ]

### limit to US----------------------------------------------
all_species$UnitedStates = grepl("United States", all_species$Country)
all_species = all_species[all_species$UnitedStates == TRUE, ]

#export current dataset as csv to save this form of data
write.csv(all_species, "all_species_clean.csv")
all_species_clean = read.csv("all_species_clean.csv")

#### creating species list-----------------------------------------------------
#determining number of specimens per species in entire dataset
#list of unique species that has mass values
total_species_clean = unique(all_species_clean$Species.Genus)
#how many of these species there are
str(total_species_clean)
#177 species

#how many specimens of each species there are
occurrences_clean = table(all_species_clean$Species.Genus)
#order table from species with most specimens to species with least specimens
occurrences_clean = sort(occurrences_clean, decreasing = TRUE)

occurrences_clean = data.frame(occurrences_clean)
#determine number of species with at least 30 specimens
sum(occurrences_clean$occurrences_clean>29)
#48 species

#remove species w/ less than 30 specimens
species_list = subset(occurrences_clean, occurrences_clean>29)
colnames(species_list) = "Number.Specimens"
species_list$Species.Name = rownames(species_list)
rownames(species_list) = NULL

### find temporal ranges for each species in species_list----------------------
#create column with just collection year

#change Date.Collected column to character vector
all_species_clean = transform(all_species_clean, Date.Collected = as.character(Date.Collected))
#new column with year
all_species_clean$Year.Collected = substr(all_species_clean$Date.Collected, 1, 4)

#determine first and last years of specimens for each species
year_range = c()

for(current_species in species_list$Species.Name){
  species_subset = subset(all_species_clean, all_species_clean$Species.Genus == current_species)
  first_year = min(species_subset$Year.Collected)
  last_year = max(species_subset$Year.Collected)
  year_range = rbind(year_range, c(current_species, first_year, last_year))
}
colnames(year_range) = c("Species.Name", "First.Year", "Last.Year")

#find range of years for each species by doing difference of years
year_range = data.frame(year_range)
year_range$First.Year = as.numeric(as.character(year_range$First.Year))
year_range$Last.Year = as.numeric(as.character(year_range$Last.Year))
year_range$Difference.Years = year_range$Last.Year - year_range$First.Year

#determine how many species have more than 20 years of specimens
#sort by year range
year_range = year_range[order(year_range$Difference.Years, na.last = TRUE, decreasing = TRUE), ]
#count relevant species
sum(year_range$Difference.Years>19, na.rm = TRUE)
#remove species from list with insufficient number of years
year_range = subset(year_range, year_range$Difference.Years>19)

#look at earliest and latest collection years, have temp data for earliest collection years
min(year_range$First.Year, na.rm = TRUE)
max(year_range$First.Year, na.rm = TRUE)
min(year_range$Last.Year, na.rm = TRUE)
max(year_range$Last.Year, na.rm = TRUE)

#add year range info to species list and remove species with insufficient years
species_list = merge(species_list, year_range)
species_list$Number.Specimens = as.numeric(species_list$Number.Specimens)

#remove all but species on species list from datase
all_species_clean = all_species_clean[all_species_clean$Species.Genus %in% species_list$Species.Name,]
#5,991 specimens for 39 species

### find spatial extent of each species in species_list----------------------

#find lat/lon for each specimen in database

#creating lookup table, from NMNHSearchforData.r

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
coords = county_to_coord_data[match(interaction(all_species_clean$Province.State, all_species_clean$District.County), interaction(county_to_coord_data$State.Fullname, county_to_coord_data$County.Name)), ]
coords = subset(coords, select = c(Longitude, Latitude))
all_species_clean = cbind(all_species_clean, coords)

#remove specimens with no coordinates from dataset
all_species_clean = all_species_clean[complete.cases(all_species_clean$Longitude),]

#update species list to remove species that now have insufficient number of specimens
lookat_species = table(all_species_clean$Species.Genus)
lookat_species = sort(lookat_species, decreasing = TRUE)
sum(lookat_species>29)
lookat_species = subset(lookat_species, lookat_species>29)
lookat_species = data.frame(lookat_species)
lookat_species$Species.Name = rownames(lookat_species)
rownames(lookat_species) = NULL
species_list = merge(species_list, lookat_species)
species_list$Number.Specimens = NULL
colnames(species_list) [5] = "Number.Specimens"

#use species list to remove specimens from dataset
all_species_clean = all_species_clean[all_species_clean$Species.Genus %in% species_list$Species.Name,]

#lat/long range

#check all in US
#latitude: 24.52 - 49.38
#longitude: 66.95 - 124.77
coord_extent = c()
coord_extent$Min.Latitude = min(all_species_clean$Latitude)
coord_extent$Max.Latitude = max(all_species_clean$Latitude)
coord_extent$Min.Longitude = min(all_species_clean$Longitude)
coord_extent$Max.Longitude = max(all_species_clean$Longitude)
known_coords = cbind(24.52, 49.38, -124.77, -66.95)
rownames(known_coords) = "Known.US.Coords"
coord_extent = rbind(known_coords, coord_extent)

#determine min and max latitudes for each species
species_coord_range = c()
for(current_species in species_list$Species.Name){
  species_subset = subset(all_species_clean, all_species_clean$Species.Genus == current_species)
  max_lat = max(species_subset$Latitude)
  min_lat = min(species_subset$Latitude)
  species_coord_range = rbind(species_coord_range, c(max_lat, min_lat))
}

#add latitudes to species list and find latitude range for each species
species_list = cbind(species_list, species_coord_range)
colnames(species_list) [6] = "Max.Latitude"
colnames(species_list) [7] = "Min.Latitude"
species_list$Difference.Lat = species_list$Max.Latitude - species_list$Min.Latitude

#remove species with less than 5 degrees of latitude from species list and dataset
sum(species_list$Difference.Lat >= 5)
species_list = subset(species_list, species_list$Difference.Lat >= 5)
all_species_clean = all_species_clean[all_species_clean$Species.Genus %in% species_list$Species.Name,]

#create pdf which contains visualization map of specimens for all species
pdf("species.locations.pdf")
for(current_species in species_list$Species.Name){
  species_subset = subset(all_species_clean, all_species_clean$Species.Genus == current_species)
  library(maps)
  map('usa')
  points(species_subset$Longitude, species_subset$Latitude, col = 'red')
  #title(sub = paste("Species", species_subset$Species.Genus))
  mtext(paste("species", species_subset$Species.Genus), side = 1)
}
dev.off()

### final species--------------------------------------------------------

#create and read in final species dataset CSV file
write.csv(all_species_clean, file = "FinalSpeciesDataset.csv")
FinalSpeciesDataset = read.csv("FinalSpeciesDataset.csv")

#create and read in final species list CSV file
write.csv(species_list, file = "FinalSpeciesList.csv")
FinalSpeciesList = read.csv("FinalSpeciesList.csv")

#determine which orders all species are in to get an idea of the taxonomic range
final_orders = table(FinalSpeciesDataset$Order)

#### use temperature data to determine temperatures for each specimen

#convert year to correct format for raster function
FinalSpeciesDataset$stackID = FinalSpeciesDataset$Year.Collected * 12 - 22793

#remove specimens with collection dates after 2010 b/c temp data not available
sum(FinalSpeciesDataset$stackID > 1315)
#103 specimens
FinalSpeciesDataset = subset(FinalSpeciesDataset, FinalSpeciesDataset$stackID < 1327)

#determine temperature for each specimen
library(raster)

extracted_temperatures = c()
for (i in 1:nrow(FinalSpeciesDataset)){
  specimen.temperature = raster("air.mon.mean.v301.nc", band = FinalSpeciesDataset$stackID[i])
  specimen.coordinates = cbind(FinalSpeciesDataset$Longitude[i] + 360, FinalSpeciesDataset$Latitude[i])
  specimen.extracted.temperature = extract(specimen.temperature, specimen.coordinates)
  extracted_temperatures = append(extracted_temperatures, specimen.extracted.temperature)
}

#add temperatures to final dataset
FinalSpeciesDataset$Extracted.Temperature = extracted_temperatures

# #determine which temperatures produced NAs and why
# sum(is.na(FinalSpeciesDataset$Extracted.Temperature))
# find.NA = subset(FinalSpeciesDataset, is.na(FinalSpeciesDataset$Extracted.Temperature))
# #they're all near water? not sure why no temperatures were returned

#remove specimens with no extracted temperature (i.e., NA)
FinalSpeciesDataset$Extracted.Temperature = na.omit(FinalSpeciesDataset$Extracted.Temperature)
sum(is.na(FinalSpeciesDataset$Extracted.Temperature))


