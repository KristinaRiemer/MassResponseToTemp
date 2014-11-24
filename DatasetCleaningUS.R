# Read in complete Smithsonian dataset
individual_data_original = read.csv("all_species.csv")

# Create subset of dataset to test functions
test_data_subset = individual_data_original[1:30,]

# Extract mass values for each individual
library(stringr)
extract_individuals_masses = function(dataset_column){
  extracted_masses = vector()
  for (current_row in dataset_column){
    extracted_mass = str_match(dataset_column, "Specimen Weight: ([0-9.]*)g")
    extracted_mass = as.numeric(extracted_mass[,2])
    extracted_masses = append(extracted_masses, extracted_mass)
    return(extracted_masses)
  }
}

# Test function with example dataset
test_extracted_masses = extract_individuals_masses(test_data_subset$Measurements)

#add masses to dataset file
all_species = cbind(all_species, all_species_masses)

