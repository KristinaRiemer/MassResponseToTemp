#-----DATASETS------

# Read in Vertnet dataset (size metric only)
individual_data = read.csv("Vertnet_size.csv")
individual_data_subset = individual_data[100:300, 151:152]


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

# weight_only = individual_data_subset[grep("weight", individual_data_subset$dynamicproperties), ]




# # How many instances of "weight" are there? Does this match the number of mass values? 
# # Extract mass values for each individual in entire dataset
# individual_data_subset$mass = extract_component(individual_data_subset$dynamicproperties, "weight: ([0-9.]*) g")
# individual_data_subset$mass2 = extract_component(individual_data_subset$dynamicproperties, "weightInGrams: ([0-9.]*)")
# individual_data_subset$mass3 = extract_component(individual_data_subset$dynamicproperties, "weight=([0-9.]*) g")
# individual_data_subset$mass4 = extract_component(individual_data_subset$dynamicproperties, "weight=([0-9.]*)")
# individual_data_subset$mass5 = extract_component(individual_data_subset$dynamicproperties, "weight=([0-9.]*)g")
# individual_data_subset$mass6 = extract_component(individual_data_subset$dynamicproperties, "weight: ([0-9.]*)g")
# 
# # Possible weight combos: "weight: xx g", "weightInGrams: xx", "weight=xx g",  
# 
# "Specimen Weight: ([0-9.]*)g"




working_regex = "weight(?:InGrams)?[:=] ?([0-9.]*)"
individual_data_subset$mass = extract_component(individual_data_subset$dynamicproperties, working_regex)


length(grep("weight", individual_data_subset$dynamicproperties)) - sum(!is.na(individual_data_subset$mass))
sum(grepl("weight", individual_data_subset$dynamicproperties) & is.na(individual_data_subset$mass))

grepl("weight", individual_data_subset$dynamicproperties) & is.na(individual_data_subset$mass)

# Missing two, problem is there's a "weight=[xx]" that's being picked up first, and then a "weight: xx"


