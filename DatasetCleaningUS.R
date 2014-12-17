# Read in complete Smithsonian dataset
individual_data_original = read.csv("all_species.csv")

# Create subset of dataset to test functions
test_data_subset = individual_data_original[1:250,]

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
  #   Dataset with new column that holds just genus and species of each individual, 
  #   removes individuals with no species (i.e., "sp.")
  extracted_genus_species = c()
  for(current_row in dataset_column){
    extract_genus_species = word(dataset_column, 1, 2)
    extracted_genus_species = append(extracted_genus_species, extract_genus_species)
    dataset = cbind(dataset, extracted_genus_species)
    dataset_subset = dataset[!grepl(".*sp", dataset$extracted_genus_species),]
    return(dataset_subset)
  }
}

# Test function with example dataset
test_data_subset = extract_individuals_genus_species(test_data_subset, 
                                                     test_data_subset$Current.Identification)


# Does this really need to be a function? I'm only doing it once

# Coordinate lookup table
# http://www.census.gov/geo/maps-data/data/gazetteer2013.html
county_to_coord_data = read.table("CensusFile.txt", sep="\t", fileEncoding="latin1", 
                                  fill=TRUE, stringsAsFactors=FALSE, header=TRUE)
county_to_coord_data$STATE_NAME = state.name[match(county_to_coord_data$USPS, state.abb)]
county_to_coord_data = county_to_coord_data[!is.na(county_to_coord_data$STATE_NAME),]
names(county_to_coord_data)[10] = "INTPTLONG"

get_coords_from_counties = function(data, lookup, data_state, data_county, lookup_state, lookup_county){
  dataset_info = interaction(data_state, data_county)
  lookup_info = interaction(lookup_state, lookup_county)
  dataset_coords = lookup[match(dataset_info, lookup_info),]
}

testing = get_coords_from_counties(test_data_subset, county_to_coord_data, test_data_subset$Province.State, test_data_subset$District.County, county_to_coord_data$STATE_NAME, county_to_coord_data$NAME)
test_data_subset$lat = testing$INTPTLAT
test_data_subset$long = testing$INTPTLONG


