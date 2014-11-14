# Read in complete Smithsonian dataset
individual_data_original = read.csv("all_species.csv")

# Extract mass values for each individual
# 


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
