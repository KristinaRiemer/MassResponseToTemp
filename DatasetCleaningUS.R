#-----DATASETS------

# Read in complete Smithsonian dataset
individual_data = read.csv("all_species.csv")

# Read in coordinate lookup table
# http://www.census.gov/geo/maps-data/data/gazetteer2013.html
county_to_coord_data = read.table("CensusFile.txt", sep="\t", fileEncoding="latin1", 
                                  fill=TRUE, stringsAsFactors=FALSE, header=TRUE)
county_to_coord_data$STATE_NAME = state.name[match(county_to_coord_data$USPS, state.abb)]
county_to_coord_data = county_to_coord_data[!is.na(county_to_coord_data$STATE_NAME),]
names(county_to_coord_data)[10] = "INTPTLONG"


#-----FUNCTIONS------

library(stringr)
extract_component = function(dataset_column, regex){
  # Pull out numerical component of strings
  #
  # Args: 
  #   dataset_column: Column that contains strings
  #   regex: Regular expression to specify string surrounding numerical component
  #
  # Returns: 
  #   Vector that contains extracted numerical components
  components_list = vector()
  for (current_row in dataset_column){
    component = str_match(dataset_column, regex)
    component = as.numeric(component[,2])
    components_list = append(components_list, component)
    return(components_list)
  }
}

# I don't think it's worth it to generalize this function, it's too specific
# to this problem
extract_individuals_genus_species = function(dataset_column){
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
    extracted_genus_species = gsub(".*sp", NA, extracted_genus_species)
    return(extracted_genus_species)
  }
}

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

extract_year = function(dataset_col){
  # Extract year from date column
  #
  # Args:
  #   dataset_col: Column containing full date
  #
  # Returns:
  #   Column with year
  years = substr(dataset_col, 1, 4)
  years = as.numeric(years)
}

species_crit = function(dataset, for_col, by_col, fx, col_name){
  # Get all minimum or maximum values of one variable for each species
  #
  # Args:
  #   dataset: Dataset that contains individuals' information
  #   for_col: Column that contains desired variable
  #   by_col: Column that contains species ID
  #   fx: Either min or max function
  #   col_name: Desired name for minimum or maximum values
  #
  # Return:
  #   Column containing minimum or maximum variables for each species
  list = aggregate(for_col ~ by_col, dataset, fx)
  colnames(list)[1] = "genus_species"
  colnames(list)[2] = col_name
  return(list)
}

#-----FUNCTIONS ON ENTIRE DATASET------

# Extract mass values for each individual in entire dataset
individual_data$mass = extract_component(individual_data$Measurements, "Specimen Weight: ([0-9.]*)g")

# Extract genus and species for each individual in entire dataset
individual_data$genus_species = extract_individuals_genus_species(individual_data$Current.Identification)

# Get coordinates for individuals that have county-level info in entire dataset
lookup_results = get_lookup_matches(county_to_coord_data, individual_data$Province.State, 
                             individual_data$District.County, county_to_coord_data$STATE_NAME, 
                             county_to_coord_data$NAME)
individual_data$lookup_lat = lookup_results$INTPTLAT
individual_data$lookup_lon = lookup_results$INTPTLONG

# Put all latitudes and longitudes in single column, remove coordinates outside of US
# lat range: 24.52 - 49.38
# long range: -66.95 - -124.77
individual_data$lat = merge_two_cols(individual_data$Centroid.Latitude, 
                                          individual_data$lookup_lat)
individual_data$lon_untrans = merge_two_cols(individual_data$Centroid.Longitude, 
                                           individual_data$lookup_lon)

individual_data$lat = remove_values(individual_data$lat, 24.52, 49.38)
individual_data$lon_untrans = remove_values(individual_data$lon_untrans, -124.77, -66.95)

# Transform longitude to be in correct format for temperature extraction
individual_data$lon = individual_data$lon_untrans + 360

# Get collection year to use for temperature extraction
individual_data$year = extract_year(individual_data$Date.Collected)

#----SUBSETTING DATASET----

# Subset dataset to retain only individuals with mass, species ID, 
# coordinates (in US), and collected 1900-2010
individual_data = individual_data[complete.cases(individual_data$mass),]
individual_data = individual_data[complete.cases(individual_data$genus_species),]
individual_data = individual_data[(complete.cases(individual_data$lat) & complete.cases(individual_data$lon)),]
individual_data = individual_data[(individual_data$year >= 1900 & individual_data$year <= 2010),]

# Create list of species info (number individuals, year range, lat range) needed 
# to later subset based on species ID
species_data = data.frame(table(individual_data$genus_species))
colnames(species_data) = c("genus_species", "individuals")

max_year = species_crit(individual_data, individual_data$year, individual_data$genus_species, max, "max_year")
min_year = species_crit(individual_data, individual_data$year, individual_data$genus_species, min, "min_year")
max_lat = species_crit(individual_data, individual_data$lat, individual_data$genus_species, max, "max_lat")
min_lat = species_crit(individual_data, individual_data$lat, individual_data$genus_species, min, "min_lat")

species_data = merge(species_data, max_year)
species_data = merge(species_data, min_year)
species_data = merge(species_data, max_lat)
species_data = merge(species_data, min_lat)

species_data$year_range = species_data$max_year - species_data$min_year
species_data$lat_range = species_data$max_lat - species_data$min_lat

# Subset dataset to retain individuals whose species has at least 30 individuals, 
# 20 years of data, and 5 latitudinal degrees of data
# Collapse into one line or refactor?
individual_data = individual_data[individual_data$genus_species %in% species_data$genus_species[species_data$individuals >= 30],]
individual_data = individual_data[individual_data$genus_species %in% species_data$genus_species[species_data$year_range >= 20],]
individual_data = individual_data[individual_data$genus_species %in% species_data$genus_species[species_data$lat_range >= 5],]

# Save dataset as CSV to be used as input for Python code
write.csv(individual_data, "CompleteDatasetUS.csv")

