#-----DATASETS------

# Read in complete Smithsonian dataset
individual_data_original = read.csv("all_species.csv")

# Create subset of dataset to test functions
test_data_subset = individual_data_original[1:250,]

# Read in coordinate lookup table
# http://www.census.gov/geo/maps-data/data/gazetteer2013.html
county_to_coord_data = read.table("CensusFile.txt", sep="\t", fileEncoding="latin1", 
                                  fill=TRUE, stringsAsFactors=FALSE, header=TRUE)
county_to_coord_data$STATE_NAME = state.name[match(county_to_coord_data$USPS, state.abb)]
county_to_coord_data = county_to_coord_data[!is.na(county_to_coord_data$STATE_NAME),]
names(county_to_coord_data)[10] = "INTPTLONG"


#-----FUNCTIONS------

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

# Does this really need to be a function? I'm only doing it once
# Tried to generalize enough that it could be used in other cases
get_lookup_matches = function(lookup, data_col1, data_col2, lookup_col1, lookup_col2){
  # Get info from lookup for two-column matches between lookup and data
  #
  # Args: 
  #   lookup: Dataframe that contains desired information
  #   data_col1: First column from dataset to match
  #   data_col2: Second column from dataset to match
  #   lookup_col1: First column from lookup to match to data_col1
  #   lookup_col2: Second column from lookup to match to data_col2
  #
  # Returns: 
  #   Lookup information that matches dataset columns
  dataset_info = interaction(data_col1, data_col2)
  lookup_info = interaction(lookup_col1, lookup_col2)
  lookup_matches = lookup[match(dataset_info, lookup_info),]
}

merge_two_cols = function(col1, col2){
  # Combine two columns into a single new column
  # 
  # Args: 
  #   col1: First column to be combined
  #   col2: Second column to be combined
  #
  # Returns:
  #   New column containing values from both chosen columns
  both_cols = cbind(col1, col2)
  combine_cols = rowMeans(both_cols, na.rm = TRUE)
}

remove_values = function(dataset_col, lower_limit, upper_limit){
  # Remove rows that contain values outside of chosen range from column containing NAs
  #
  # Args:
  #   dataset_col: Chosen column
  #   lower_limit: Bottom end of chosen range
  #   upper_limit: Top end of chosen range
  #
  # Returns:
  #   Column with rows that had values outside of chosen range changed to NA
  dataset_col = ifelse(!is.na(dataset_col) & (dataset_col < lower_limit | dataset_col > 
                                                upper_limit), NA, dataset_col)
}


#-----TESTING FUNCTIONS------

# Extract mass values for each individual in test dataset
test_data_subset = extract_individuals_masses(test_data_subset, 
                                              test_data_subset$Measurements)

# Extract genus and species for each individual in test dataset
test_data_subset = extract_individuals_genus_species(test_data_subset, 
                                                     test_data_subset$Current.Identification)

# Get coordinates for individuals in test dataset that have county-level info
testing = get_lookup_matches(county_to_coord_data, test_data_subset$Province.State, 
                                   test_data_subset$District.County, county_to_coord_data$STATE_NAME, 
                                   county_to_coord_data$NAME)
test_data_subset$lat = testing$INTPTLAT
test_data_subset$long = testing$INTPTLONG

# Put all latitudes and longitudes in single column, remove coordinates outside of US
# lat range: 24.52 - 49.38
# long range: -66.95 - -124.77
test_data_subset$lat_all = merge_two_cols(test_data_subset$Centroid.Latitude, test_data_subset$lat)
test_data_subset$long_all = merge_two_cols(test_data_subset$Centroid.Longitude, test_data_subset$long)

test_data_subset$lat_all = remove_values(test_data_subset$lat_all, 24.52, 49.38)
test_data_subset$long_all = remove_values(test_data_subset$long_all, -124.77, -66.95)



