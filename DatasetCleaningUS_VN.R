# Using trait extraction data provided by Rob Guralnick

#-------DATASETS----------
library(readr)
individual_data = read_csv("VertnetTraitExtraction.csv")
subset_individual_data = individual_data[1:1000,]

#-------FUNCTIONS---------

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

extract_genus_species = function(dataset_column){
  # Get species and genus from current identification for each individual
  # 
  # Args: 
  #   dataset_column: Column in dataset that contains individuals' identifiers, 
  #   usually genus, species, subspecies
  #
  # Returns: 
  #   Dataset with new column that contains just genus and species of each 
  #   individual, removing subspecies ID and returning NA if only genus available
  list_IDs = c()
  for(current_row in dataset_column){
    word_count = sapply(gregexpr("\\S+", current_row), length)
    if(word_count > 2){
      ID = word(current_row, 1, 2)
    } else if(word_count < 2){
      ID = NA
    } else {
      ID = current_row
    }
    list_IDs = append(list_IDs, ID)
  }
  return(list_IDs)
}

#-----FUNCTIONS ON ENTIRE DATASET----------

# Create column containing only mass value for each individual
subset_individual_data$mass = extract_component(subset_individual_data$normalized_body_mass, "total weight\", ([0-9.]*)" )

# Create column for genus and species identification
subset_individual_data$genus_species = extract_genus_species(subset_individual_data$scientificname)


# Checking taxonomy using EOL Global Names Resolver
library(taxize)

# TODO: Turn identifications that end with spp/sp into NA

#Single individual
tax_test = gnr_resolve(names = subset_individual_data$genus_species[255])
#tax_test = gnr_resolve(names = "Lasiurus borealis")
tax_test_df = as.data.frame(tax_test)

#Several individuals
ptm = proc.time()
tax_test_list = c()
tax_test_list_scores = c()
for (i in 1:200){
  tax_test = gnr_resolve(names = subset_individual_data$genus_species[i])
  #print(tax_test$results$score[1])
  tax_test_list = append(tax_test_list, tax_test)
  tax_test_list_scores = append(tax_test_list_scores, tax_test$score[1])
}
proc.time() - ptm

for (i in 251:260){
  taxonomy_check = gnr_resolve(names = subset_individual_data$genus_species[i])
  if(taxonomy_check$submitted_name[1] == word(taxonomy_check$matched_name[1], 1, 2)){
    print(taxonomy_check$submitted_name[1])
  } else {
    # TODO: test this on case where matched names aren't equal (in 1000 subset)
    first_match = word(taxonomy_check$matched_name[1], 1, 2)
    next_four = word(taxonomy_check$matched_name[2:5], 1, 2)
    number_matches = length(which(next_four %in% first_match))
    if(number_matches == 4){
      print(word(taxonomy_check$matched_name[1], 1, 2))
    } else {
      print(NA)
    }
  }
}


# Example for checking many species IDs from Scott Chamberlain: 
# http://recology.info/2013/01/tnrs-use-case/
library(plyr)
slice <- function(input, by = 2) {
  starts <- seq(1, length(input), by)
  tt <- lapply(starts, function(y) input[y:(y + (by - 1))])
  llply(tt, function(x) x[!is.na(x)])
}
species_split <- slice(subset_individual_data$genus_species, by = 100)

tnrs_safe <- failwith(NULL, tnrs)  # in case some calls fail, will continue
out <- llply(species_split, function(x) tnrs_safe(x, getpost = "POST", sleep = 3))

lapply(out, head)[1:2]

# TODO: Check coordinates
# 2: longitude transformation needed
# TODO: specify which coordinate system data is in and needs to be
# Ranges needed for temp raster
#lat DD: should be -90 to 90 (are -161 to 8841)
  #handful of values are too big or too small
#lon DD: should be -180 to 180 (are -5610 to 180)
  #no values are too big, 5 values are too small
#Need lon range to be 0 to 360
# TODO: turn decimal coordinates that are outside of range into NA

individual_data$decimallatitude[individual_data$decimallatitude > 90 | individual_data$decimallatitude < -90] = NA
individual_data$decimallongitude[individual_data$decimallongitude > 180 | individual_data$decimallongitude < -180] = NA

longitudes = c()
for(current_row in individual_data$decimallongitude){
  if(current_row < 0){
    lon = current_row + 360
  } else {
    lon = current_row
  }
  longitudes = append(longitudes, lon)
}

individual_data$longitude = individual_data$decimallongitude + 360

# TODO: Check collection year

