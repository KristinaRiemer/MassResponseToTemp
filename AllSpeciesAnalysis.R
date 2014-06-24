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

### determine how many species have at least 100 specimens with mass

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
colnames(year_range) = c("Species", "First.Year", "Last.Year")

#find range of years for each species by doing difference of years
year_range = data.frame(year_range)
year_range$First.Year = as.numeric(as.character(year_range$First.Year))
year_range$Last.Year = as.numeric(as.character(year_range$Last.Year))
year_range$Difference.Years = year_range$Last.Year - year_range$First.Year

#determine how many species have more than 50 years of specimens
year_range = sort(year_range$Difference.Years, decreasing = TRUE)
sort(year_range, by = ~ -Difference.Years, na.last = TRUE)

year_range = data.frame(year_range)
sum(year_range$Difference.Years>2, na.rm = TRUE)
#41 species
