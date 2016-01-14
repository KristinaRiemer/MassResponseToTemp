# Using trait extraction data provided by Rob Guralnick

#-------DATASETS----------

individual_data = read.csv("VertnetTraitExtraction.csv", na.strings = c("", " ", "null"))

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

#-----FUNCTIONS ON ENTIRE DATASET

# Create column containing only mass value for each individual
individual_data$mass = extract_component(individual_data$normalized_body_mass, "total weight\", ([0-9.]*)" )

gregexpr("\\S+", individual_data$scientificname[1])
sapply(gregexpr("\\S+", individual_data$scientificname[1]), length)


# Some have more or less than just genus and species names
count_check_all = vector()
for (i in 1:1000){
  word_count = sapply(gregexpr("\\S+", individual_data$scientificname[i]), length)
  count_check_all = append(count_check_all, word_count)
}

table(count_check_all)


# Example use from Scott Chamberlain: http://recology.info/2013/01/tnrs-use-case/
library(taxize)

tax_test_list = c()
for (i in 1:10){
  tax_test = gnr_resolve(names = individual_data$scientificname[i])
  tax_test_list = append(tax_test_list, tax_test)
}

tax_test = gnr_resolve(names = individual_data$scientificname[1])
tax_test = gnr_resolve(names = "Reithrodontomys megalatis")



