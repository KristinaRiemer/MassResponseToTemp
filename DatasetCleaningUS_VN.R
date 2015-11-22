#-----DATASETS------

# Read in Vertnet dataset (size metric only)
individual_data = read.csv("Vertnet_size.csv")


#-----FUNCTIONS-----

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


#-----FUNCTIONS ON ENTIRE DATASET------

# Extract mass values for each individual that has mass information
mass_regex = "weight(?:InGrams)?(?: in g)?\"?[:=] ?\"?\\[?([0-9.]*)"
individual_data$mass = extract_component(individual_data$dynamicproperties, mass_regex)
length(grep("weight", individual_data$dynamicproperties)) - sum(!is.na(individual_data$mass))
sum(grepl("weight", individual_data$dynamicproperties) & is.na(individual_data$mass))
