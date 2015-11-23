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

# Exploring taxon rows

taxon_subset = individual_data[1:1000, 153:185]

# How many rows from that column have information in them? 
for (i in 153:185){
  rows_with_info = sum(!is.na(individual_data[1:1000, i]))
  print(c(i, rows_with_info))
}

# What kind of information do the columns with information contain?
col_list = c(161, 174, 176, 178)
for (i in col_list){
  cols_with_info = table(individual_data[,i])
  print(cols_with_info)
}

table(individual_data[,161])
table(individual_data[,174])
table(individual_data[,176])
table(individual_data[,178])

# Want "genus" [174] and "specificepithet" [176] (i.e., species ID) columns
# TODO: Need to put two columns together into one and then remove third word (if there is one)


taxon_subset$genus_species = cbind(taxon_subset$genus, taxon_subset$specificepithet)

cbind(taxon_subset$genus[1,], taxon_subset$specificepithet)











