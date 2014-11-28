# Read in complete Smithsonian dataset
individual_data_original = read.csv("all_species.csv")

# Create subset of dataset to test functions
test_data_subset = individual_data_original[1:30,]

# Extract mass values for each individual
library(stringr)
extract_individuals_masses = function(dataset, dataset_column){
  # Extract mass values from individual measurements and place in new column
  #
  # Args: 
  #   dataset: Dataset that contains measurements and will have new mass column
  #   dataset_column: Column in dataset that contains measurements for each 
  #   individuals, e.g., length
  #
  # Returns: 
  #   Dataset with new column that holds individuals' mass values
  extracted_masses = vector()
  for (current_row in dataset_column){
    extracted_mass = str_match(dataset_column, "Specimen Weight: ([0-9.]*)g")
    extracted_mass = as.numeric(extracted_mass[,2])
    extracted_masses = append(extracted_masses, extracted_mass)
    dataset = cbind(dataset, extracted_masses)
    return(dataset)
  }
}

# Test function with example dataset
test_data_subset = extract_individuals_masses(test_data_subset, 
                                              test_data_subset$Measurements)

# Run entire dataset through functions
individual_data_original = extract_individuals_masses(individual_data_original, 
                                                      individual_data_original$Measurements)


# Extract genus and species for each individual
extract_individuals_genus_species = function(dataset, dataset_column){
  # Get species and genus from current identification for each individual
  #
  # Args:
  #   dataset: Dataset that contains individuals' identifiers
  #   dataset_column: Column in dataset that contains individuals' identifiers, 
  #   usually genus, species, subspecies
  #
  # Returns: 
  #   Dataset with new column that holds just genus and species of each individual
  extracted_genus_species = c()
  for(current_row in dataset_column){
    extract_genus_species = word(dataset_column, 1, 2)
    extracted_genus_species = append(extracted_genus_species, extract_genus_species)
    dataset = cbind(dataset, extracted_genus_species)
    return(dataset)
  }
}

# Test function with example dataset
test_data_subset2 = extract_individuals_genus_species(test_data_subset, test_data_subset$Current.Identification)

# Return NA for individuals with unknown species
find_incomplete_identification = function(dataset_column){
  for(current_row in dataset_column){
    if((grep(".* sp.", dataset_column)) == TRUE){
      NA
    }
  }
}

# Test function with example dataset
test_data_subset3 = find_incomplete_identification(test_data_subset2$extracted_genus_species)

#remove all specimens whose identifiers are "xxx(genus) sp."
all_species$genus.only = grepl(".* sp.", all_species$Current.Identification)
all_species = all_species[all_species$genus.only == FALSE, ]




