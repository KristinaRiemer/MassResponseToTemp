## creating file with all specimens from Smithsonian mammals collection --------
# only have to read in all_species.csv file now

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

# loop to remove everything from Measurements column except mass (same code as above)
# str_match example: http://stackoverflow.com/questions/952275/regex-group-capture-in-r
library(stringr)
masses = vector()
# only change is from "species1$Measurements" to "all_species$Measurements"
for (current_row in all_species$Measurements){
  mass_match = str_match(current_row, "Specimen Weight: ([0-9.]*)g")
  mass = as.numeric(mass_match[2])
  masses = append(masses, mass)
}

# loop to remove total length value from Measurements column
lengths = vector()
# only change is from "species1$Measurements" to "all_species$Measurements"
for (current_row in all_species$Measurements){
  length_match = str_match(current_row, "Total Length: ([0-9.]*)mm")
  length = as.numeric(length_match[2])
  lengths = append(lengths, length)
}

# find number of specimens that have length but not mass
size_values = cbind(masses, lengths)
length_nomass = sum(is.na(size_values[,1]) & !is.na(size_values[,2]))
# only ~60,000 out of ~500,000 specimens have length but no mass

### determine how many species have at least 200 specimens with mass

# extract mass values for each specimen and add to species file
library(stringr)
masses = vector()
# only change is from "species1$Measurements" to "all_species$Measurements"
for (current_row in all_species$Measurements){
  mass_match = str_match(current_row, "Specimen Weight: ([0-9.]*)g")
  mass = as.numeric(mass_match[2])
  masses = append(masses, mass)
}

all_species = cbind(all_species, masses)

massed_specimens = c()
for(each_specimen in all_species){
  massed_specimens = subset(all_species$masses !NA)
}

for(i in 1:nrow(all_species)){
  massed_specimens = subset(all_species$masses[i] !NA)
}

