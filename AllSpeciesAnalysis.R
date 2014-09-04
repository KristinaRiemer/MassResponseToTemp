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


#### use collection years & coordinates to determine temperatures for each specimen---

#convert year to correct format for raster function
all_species_clean$Year.Collected = as.numeric(all_species_clean$Year.Collected)
all_species_clean$stackID = all_species_clean$Year.Collected * 12 - 22793

#remove specimens with collection dates after 2010 b/c temp data not available
sum(all_species_clean$stackID > 1315)
#103 specimens
all_species_clean = subset(all_species_clean, all_species_clean$stackID < 1327)

#determine temperature for each specimen
library(raster)

extracted_temperatures = c()
for (i in 1:nrow(all_species_clean)){
  specimen.temperature = raster("air.mon.mean.v301.nc", band = all_species_clean$stackID[i])
  specimen.coordinates = cbind(all_species_clean$Longitude[i] + 360, all_species_clean$Latitude[i])
  specimen.extracted.temperature = extract(specimen.temperature, specimen.coordinates)
  extracted_temperatures = append(extracted_temperatures, specimen.extracted.temperature)
}
#saving extracted temps so this loop doesn't have to be run again (takes ~5 mins)
write.csv(extracted_temperatures, file = "extracted_temperatures.csv")
extracted_temperatures = read.csv("extracted_temperatures.csv")

#add temperatures to final dataset
all_species_clean$Extracted.Temperature = extracted_temperatures[,2]

# #determine which temperatures produced NAs and why
# sum(is.na(all_species_clean$Extracted.Temperature))
# find.NA = subset(FinalSpeciesDataset, is.na(FinalSpeciesDataset$Extracted.Temperature))
# #they're all near water? not sure why no temperatures were returned

#remove specimens with no extracted temperature (i.e., NA)-----------------------
all_species_clean = subset(all_species_clean, !is.na(all_species_clean$Extracted.Temperature))

#need to remove species that now have less than 30 specimens
#create new csv of dataset to actually remove subsetted rows
write.csv(all_species_clean, file = "temporary_all_species_clean.csv")
temporary_all_species_clean = read.csv("temporary_all_species_clean.csv")

#create list of species from dataset and remove those with less than 30 specimens
number_specimens = table(temporary_all_species_clean$Species.Genus)
number_specimens = subset(number_specimens, number_specimens > 29)
number_specimens = data.frame(number_specimens)
number_specimens$Species.Name = rownames(number_specimens)
rownames(number_specimens) = NULL

#update species list to reflect the removed species
species_list = merge(species_list, number_specimens)
species_list$Number.Specimens = NULL

### adding orders to species list---------------------------------------
#this section really needs to be redone
#get orders for each species
orders_list = c()
for(current_species in species_list$Species.Name){
  by_species = subset(all_species_clean, all_species_clean$Species.Genus == current_species)
  orders_list = rbind(orders_list, unique(by_species$Order))
  #orders_list = unique(by_species$Order)
  #orders_list = rbind(orders_list, orders)
}

#change orders identification numbers to order names
orders_list = as.numeric(orders_list)
lookup_orders = matrix(c(1, 2, 3, 4, 5, 6, 7, 8, "Carnivora", "Cetacea", "Chiroptera", "Cingulata", "Didelphimorphia", "Lagomorpha", "Rodentia", "Soricomorpha"), nrow = 8)
orders_list2 = lookup_orders[match(orders_list, lookup_orders[,1]),]
orders_list2 = data.frame(orders_list2)

#add to species list
species_list$Order = orders_list2$X2

#### changes to species list and dataset for later-----------------------
#change mass column name in dataset
colnames(all_species_clean) [46] = "Mass"

#sort species list by order
species_list = species_list[order(species_list$Order),]


### final species list and dataset--------------------------------------------------------

#create finals species list and dataset CSV files
write.csv(all_species_clean, file = "FinalSpeciesDataset.csv")
write.csv(species_list, file = "FinalSpeciesList.csv")

#read in final species list and dataset CSV files
FinalSpeciesDataset = read.csv("FinalSpeciesDataset.csv")
FinalSpeciesList = read.csv("FinalSpeciesList.csv")

### remove outliers from (presumably) data entry errors----------------------------------
#found outliers by looking at mass-temperature plots for specimens with unusually high masses
#4 species

#find Sorex trowbridgii outliers
S.trowbridgii.data = subset(FinalSpeciesDataset, FinalSpeciesDataset$Species.Genus == "Sorex trowbridgii")
S.trowbridgii.data = subset(S.trowbridgii.data, S.trowbridgii.data$Mass > 20)
#remove Sorex trowbridgii outliers from dataset
FinalSpeciesDataset = subset(FinalSpeciesDataset, !FinalSpeciesDataset$X.2 == 5552 & !FinalSpeciesDataset$X.2 == 5553)
#check for removal
S.trowbridgii.data.check = subset(FinalSpeciesDataset, FinalSpeciesDataset$Species.Genus == "Sorex trowbridgii")
S.trowbridgii.data.check = subset(S.trowbridgii.data.check, S.trowbridgii.data.check$Mass > 20)

#find Peromyscus leucopus outliers
P.leucopus.data = subset(FinalSpeciesDataset, FinalSpeciesDataset$Species.Genus == "Peromyscus leucopus")
P.leucopus.data = subset(P.leucopus.data, P.leucopus.data$Mass > 40)
#remove Peromyscus leucopus outlier
FinalSpeciesDataset = subset(FinalSpeciesDataset, !FinalSpeciesDataset$X.2 == 757)
#check for removal
P.leucopus.data.check = subset(FinalSpeciesDataset, FinalSpeciesDataset$Species.Genus == "Peromyscus leucopus")
P.leucopus.data.check = subset(P.leucopus.data.check, P.leucopus.data.check$Mass > 40)

#find Perimyotis subflavus outliers
P.subflavus.data = subset(FinalSpeciesDataset, FinalSpeciesDataset$Species.Genus == "Perimyotis subflavus")
P.subflavus.data = subset(P.subflavus.data, P.subflavus.data$Mass > 15)
#remove Perimyotis subflavus outliers
FinalSpeciesDataset = subset(FinalSpeciesDataset, !FinalSpeciesDataset$X.2 == 7467 & !FinalSpeciesDataset$X.2 == 7468)
#check for removal
P.subflavus.data.check = subset(FinalSpeciesDataset, FinalSpeciesDataset$Species.Genus == "Perimyotis subflavus")
P.subflavus.data.check = subset(P.subflavus.data.check, P.subflavus.data.check$Mass > 15)

#find Sorex monticolus outliers
S.monticolus.data = subset(FinalSpeciesDataset, FinalSpeciesDataset$Species.Genus == "Sorex monticolus")
S.monticolus.data = subset(S.monticolus.data, S.monticolus.data$Mass > 12)
#remove Sorex monticolus outlier
FinalSpeciesDataset = subset(FinalSpeciesDataset, !FinalSpeciesDataset$X.2 == 5084)
#check for removal
S.monticolus.data.check = subset(FinalSpeciesDataset, FinalSpeciesDataset$Species.Genus == "Sorex monticolus")
S.monticolus.data.check = subset(S.monticolus.data.check, S.monticolus.data.check$Mass > 12)


#create pdf which contains visualization map of specimens for all species
#set up pdf for plots
pdf("SpecimenLocations.pdf")

#loop to create plots
for(current_species in FinalSpeciesList$Species.Name){
  species_subset = subset(FinalSpeciesDataset, FinalSpeciesDataset$Species.Genus == current_species)
  library(maps)
  map('usa')
  points(species_subset$Longitude, species_subset$Latitude, col = 'red')
  mtext(paste("species:", species_subset$Species.Genus, ",", "order:", species_subset$Order), side = 1)
}

#turn pdf device off
dev.off()

##### plot temperature-mass relationships for each species-----------------------
#set up pdf and layout for plots
pdf("FinalPlots.pdf")
par(mfrow = c(2,2))

#loop to create plots
linreg_summary = c()
linreg_rsquared = c()
for(current_species in FinalSpeciesList$Species.Name){
  species_subset = subset(FinalSpeciesDataset, FinalSpeciesDataset$Species.Genus == current_species)
  plot(species_subset$Extracted.Temperature, species_subset$Mass, xlab = "Temperature (*C)", ylab = "Body Mass (g)", col = "red")
  mtext(paste("species:", species_subset$Species.Genus, ",", "order:", species_subset$Order), side = 3)
  linreg = lm(species_subset$Mass ~ species_subset$Extracted.Temperature)
  #linreg_summary = paste(summary(linreg))
  print(summary(linreg))
  linreg_summary = rbind(linreg_summary, summary(linreg)$coefficients)
  linreg_rsquared = rbind(linreg_rsquared, summary(linreg)$r.squared)
  #linreg_summary = print(summary(linreg))
  #linreg_summary = summary(get(paste(current_species, linreg)))
  abline(linreg)
}

#turn pdf device off
dev.off()


### determine lin reg slope types (sign & stat sig) for each species-------------------------

#remove everything from linear regression summary except p-values for each species
#p-value are second value in "Pr(>|t|)" column
rownames(linreg_summary) = NULL
linreg_summary = data.frame(linreg_summary)
even_rows = linreg_summary[c(FALSE, TRUE),]
species_pvalues = even_rows$Pr...t..
species_pvalues = data.frame(species_pvalues)
colnames(species_pvalues) = "Pvalue"

#add p-values to species list
FinalSpeciesList = cbind(FinalSpeciesList, species_pvalues)

#species with statistically significant p-values
sum(FinalSpeciesList$Pvalue < 0.05)
stat_significant = subset(FinalSpeciesList, FinalSpeciesList$Pvalue < 0.05)

#species with non-statistically significant p-values
sum(FinalSpeciesList$Pvalue > 0.05)
not_stat_significant = subset(FinalSpeciesList, FinalSpeciesList$Pvalue > 0.05)

#remove everything from linear regression summary except slopes for each species
#slope is second value in "Estimate" column
species_slopes = even_rows$Estimate
species_slopes = data.frame(species_slopes)
colnames(species_slopes) = "Slope"

#add slopes to species list
FinalSpeciesList = cbind(FinalSpeciesList, species_slopes)

#grouping species according to slope type
for(current_species in FinalSpeciesList$Species.Name){
  not_SS = subset(FinalSpeciesList, FinalSpeciesList$Pvalue > 0.05)
  SS_negative = subset(FinalSpeciesList, FinalSpeciesList$Pvalue < 0.05 & FinalSpeciesList$Slope < 0)
  SS_positive = subset(FinalSpeciesList, FinalSpeciesList$Pvalue < 0.05 & FinalSpeciesList$Slope > 0)
}

#getting counts for each group
slope_counts = c()
slope_counts = nrow(SS_negative)
slope_counts = rbind(slope_counts, nrow(not_SS))
slope_counts = rbind(slope_counts, nrow(SS_positive))
slope_counts = data.frame(slope_counts)
slope_counts$Slope.Type = rbind("negative", "zero", "positive")
slope_counts$Percent.Slope.Type = (slope_counts$slope_counts/sum(slope_counts$slope_counts))*100

#pdf of plot showing effect of temperature on mass
pdf("SlopeTypes.pdf")
barplot(slope_counts$Percent.Slope.Type, xlab = NULL, ylab = "Percent of Species",
        names.arg = c("Negative", "None", "Positive"), ylim = c(0,60), col = c("red", "blue3", "black"))
dev.off()


####figure of r-squared values for each species----------------------------
#pulled out r-squared values in lin reg loop to linreg_rsquared

#add r-squared to species list
FinalSpeciesList = cbind(FinalSpeciesList, linreg_rsquared)
colnames(FinalSpeciesList) [13] = "R.squared"

#create pdf of histogram of species' r-squared values
pdf("RsquaredHistogram.pdf")
hist(FinalSpeciesList$R.squared, xlab = "R-squared Value", ylab = "Number of Species",
     xlim = c(0,1), col = "blue3", main = NULL, ylim = c(0,20))
dev.off()

###histogram of normalized slopes of each species---------------------

#determine average & SD of mass and temperature for each species
Mass.Average = c()
Mass.SD = c()
Temperature.Average = c()
Temperature.SD = c()

for(current_species in FinalSpeciesList$Species.Name){
  species_subset = subset(FinalSpeciesDataset, FinalSpeciesDataset$Species.Genus == current_species)
  Mass.Average = rbind(Mass.Average, mean(species_subset$Mass))
  Mass.SD = rbind(Mass.SD, sd(species_subset$Mass))
  Temperature.Average = rbind(Temperature.Average, mean(species_subset$Extracted.Temperature))
  Temperature.SD = rbind(Temperature.SD, sd(species_subset$Extracted.Temperature))
}

#put four types of values into species list
FinalSpeciesList = cbind(FinalSpeciesList, Mass.Average, Mass.SD, Temperature.Average, Temperature.SD)

#get species average/SD values for each specimen in dataset
Species.Values.Extract = FinalSpeciesList[match(FinalSpeciesDataset$Species.Genus, FinalSpeciesList$Species.Name),]
FinalSpeciesDataset = cbind(FinalSpeciesDataset, Species.Values.Extract$Mass.Average, Species.Values.Extract$Mass.SD, Species.Values.Extract$Temperature.Average, Species.Values.Extract$Temperature.SD)
colnames(FinalSpeciesDataset) [56] = "Mass.Average.Species"
colnames(FinalSpeciesDataset) [57] = "Mass.SD.Species"
colnames(FinalSpeciesDataset) [58] = "Temperature.Average.Species"
colnames(FinalSpeciesDataset) [59] = "Temperature.SD.Species"

#calculate normalized mass and temp for each specimen using species average/SD values
for(current_specimen in FinalSpeciesDataset$Species.Genus){
  FinalSpeciesDataset$Normalized.Mass = (FinalSpeciesDataset$Mass - FinalSpeciesDataset$Mass.Average.Species)/FinalSpeciesDataset$Mass.SD.Species
  FinalSpeciesDataset$Normalized.Temperature = (FinalSpeciesDataset$Extracted.Temperature - FinalSpeciesDataset$Temperature.Average.Species)/FinalSpeciesDataset$Temperature.SD.Species
}

#using code from previous raw data loop to plot & do lin reg with normalized values

#set up pdf and layout for plots
pdf("NormalizedPlots.pdf")
par(mfrow = c(2,2))

#loop to create plots
normalizedlinreg_summary = c()
for(current_species in FinalSpeciesList$Species.Name){
  species_subset = subset(FinalSpeciesDataset, FinalSpeciesDataset$Species.Genus == current_species)
  plot(species_subset$Normalized.Temperature, species_subset$Normalized.Mass, xlab = "Normalized Temperature", ylab = "Normalized Body Mass")
  mtext(paste("species:", species_subset$Species.Genus, ",", "order:", species_subset$Order), side = 3)
  normalizedlinreg = lm(species_subset$Normalized.Mass ~ species_subset$Normalized.Temperature)
  #linreg_summary = paste(summary(linreg))
  print(summary(normalizedlinreg))
  normalizedlinreg_summary = rbind(normalizedlinreg_summary, summary(normalizedlinreg)$coefficients)
  #linreg_summary = print(summary(linreg))
  #linreg_summary = summary(get(paste(current_species, linreg)))
  abline(normalizedlinreg)
}

#turn pdf device off
dev.off()

#checked that this was correct by comparing to FinalPlots.pdf; they are the same, as they should be

#pulling out slopes from lin reg summary
rownames(normalizedlinreg_summary) = NULL
normalizedlinreg_summary = data.frame(normalizedlinreg_summary)
normalized_even_rows = normalizedlinreg_summary[c(FALSE, TRUE),]
species_normalizedslopes = normalized_even_rows$Estimate
species_normalizedslopes = data.frame(species_normalizedslopes)
colnames(species_normalizedslopes) = "Normalized.Slope"

#add normalized slopes to species list
FinalSpeciesList = cbind(FinalSpeciesList, species_normalizedslopes)

#create histogram of normalized slopes
pdf("NormalizedSlopesHistogram.pdf")
hist(FinalSpeciesList$Normalized.Slope, xlab = "Normalized Slope", col = "red", 
     main = NULL, xlim = c(-1, 1))
dev.off()


#good resource for linear regression and correlation analysis: http://udel.edu/~mcdonald/statregression.html

#creating CSV file of species list to print out
write.csv(FinalSpeciesList, file = "PrintSpeciesList.csv")

#plot of all specimens mass-temperature relationship
plot(FinalSpeciesDataset$Extracted.Temperature, FinalSpeciesDataset$Mass)


### arrange species stats/plots by mass------------------------------------

#already calculated average mass for each species, in species list
#organize species list by ascending average mass
FinalSpeciesList_bymass = FinalSpeciesList[order(FinalSpeciesList$Mass.Average),]

#redo mass-temperature plots for each species using new species list order
#set up pdf and layout for plots
pdf("FinalPlots_bymass.pdf")
par(mfrow = c(2,2))

#loop to create plots
linreg_summary_bymass = c()
linreg_rsquared_bymass = c()
for(current_species in FinalSpeciesList_bymass$Species.Name){
  species_subset = subset(FinalSpeciesDataset, FinalSpeciesDataset$Species.Genus == current_species)
  plot(species_subset$Extracted.Temperature, species_subset$Mass, xlab = "Temperature (*C)", ylab = "Body Mass (g)", col = "red")
  #add in average mass for each species
  mtext(paste("species:", species_subset$Species.Genus, ",", "order:", species_subset$Order), side = 3)
  mtext(paste("mass:", species_subset$Mass.Average.Species), side = 1)
  linreg = lm(species_subset$Mass ~ species_subset$Extracted.Temperature)
  #linreg_summary_bymass = paste(summary(linreg))
  print(summary(linreg))
  linreg_summary_bymass = rbind(linreg_summary_bymass, summary(linreg)$coefficients)
  linreg_rsquared_bymass = rbind(linreg_rsquared_bymass, summary(linreg)$r.squared)
  #linreg_summary_bymass = print(summary(linreg))
  #linreg_summary_bymass = summary(get(paste(current_species, linreg)))
  abline(linreg)
}

#turn pdf device off
dev.off()



#add column to species list that displays slope type for each species
  #"positive" = statistically significant w/ positive slope
  #"negative" = statistically significant w/ negative slope
  #"none" = not statistically significant, regardless of slope

for(current_species in FinalSpeciesList$Species.Name){
  FinalSpeciesList$Slope.Type = ifelse(FinalSpeciesList$Pvalue < 0.05 & 
                                         FinalSpeciesList$Slope < 0, "negative", 
                                       ifelse(FinalSpeciesList$Pvalue < 0.05 &
                                                FinalSpeciesList$Slope > 0, "positive", 
                                              "none"))
}




barplot(FinalSpeciesList_bymass$Mass.Average)

#create plot of species average masses
#bars color-coded according to mass-temp relationship
#red = negative; blue = none; black = positive
#what's started below won't work
# vals = 
# breaks = c(-Inf, )
# cols = c("red", "blue", "black")[findInterval(vals, vec = breaks)]

