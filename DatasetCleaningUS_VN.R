# Using trait extraction data provided by Rob Guralnick

#-------DATASETS----------

individual_data = read.csv("VertnetTraitExtraction.csv", na.strings = c("", " ", "null"))
subset_individual_data = individual_data[1:200,]

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

#Single individual
tax_test = gnr_resolve(names = subset_individual_data$genus_species[1], best_match_only = TRUE)
#tax_test = gnr_resolve(names = "Lasiurus borealis")
tax_test_df = as.data.frame(tax_test)

#Several individuals
tax_test_list = c()
for (i in 1:10){
  tax_test = gnr_resolve(names = subset_individual_data$genus_species[i])
  tax_test_list = append(tax_test_list, tax_test)
}

tax_test_list_df = as.data.frame(tax_test_list)

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
# 1: change to numeric values from factors
# 2: longitude transformation needed
# TODO: specify which coordinate system data is in and needs to be
latitude = as.numeric(levels(subset_individual_data$decimallatitude))[subset_individual_data$decimallatitude]
range(latitude, na.rm = TRUE)

longitude = as.numeric(as.character(subset_individual_data$decimallongitude))
longitude2 = as.numeric(levels(subset_individual_data$decimallongitude))[subset_individual_data$decimallongitude]
longitude3 = as.numeric(levels(subset_individual_data$decimallongitude))[as.integer(subset_individual_data$decimallongitude)]
range(longitude, na.rm = TRUE)

longitude = longitude + 360

# TODO: Check collection year

