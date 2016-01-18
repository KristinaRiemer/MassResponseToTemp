# Using trait extraction data provided by Rob Guralnick

#-------DATASETS----------

individual_data = read.csv("VertnetTraitExtraction.csv", na.strings = c("", " ", "null"))
subset_individual_data = individual_data[1:100000,]

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


# Checking genus and species
# Example use from Scott Chamberlain: http://recology.info/2013/01/tnrs-use-case/
library(taxize)

tax_test_list = c()
for (i in 1:10){
  tax_test = gnr_resolve(names = individual_data$scientificname[i])
  tax_test_list = append(tax_test_list, tax_test)
}

tax_test = gnr_resolve(names = individual_data$scientificname[1])
tax_test = gnr_resolve(names = "Reithrodontomys megalatis")



