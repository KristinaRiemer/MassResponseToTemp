# Using Vernet mammal dataset downloaded from KNB repository
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

# # How many rows from that column have information in them? 
# for (i in 153:185){
#   rows_with_info = sum(!is.na(individual_data[1:1000, i]))
#   print(c(i, rows_with_info))
# }
# 
# # What kind of information do the columns with information contain?
# col_list = c(161, 174, 176, 178)
# for (i in col_list){
#   cols_with_info = table(individual_data[,i])
#   print(cols_with_info)
# }
# 
# table(individual_data[,161])
# table(individual_data[,174])
# table(individual_data[,176])
# table(individual_data[,178])

# Want "genus" [174] and "specificepithet" [176] (i.e., species ID) columns
# TODO: Need to put two columns together into one (no third word, but check for it)

# wordCount_list = vector()
# for (i in 1:nrow(individual_data)){
#   word_count = sapply(gregexpr("\\S+", individual_data[i, 24]), length)
#   wordCount_list = append(wordCount_list, word_count)
# }
# 
# wordCount_list_test = vector()
# for (i in 1:nrow(taxon_subset)){
#   word_count = sapply(gregexpr("\\S+", taxon_subset[i, 9]), length)
#   wordCount_list_test = append(wordCount_list_test, word_count)
# }

genus_species = vector()
for (i in 1:nrow(taxon_subset)){
  combined_name = paste(taxon_subset[i, 22], taxon_subset[i, 24])
  genus_species = append(genus_species, combined_name)
}

taxon_subset$genus_species = genus_species

count_check = vector()
for (i in 1:nrow(taxon_subset)){
  word_count = sapply(gregexpr("\\S+", taxon_subset[i, 34]), length)
  count_check = append(count_check, word_count)
}

# If 1, 3, or 4 return NA
table(count_check)



genus_species_all = vector()
for (i in 1:nrow(individual_data)){
  combined_name = paste(individual_data[i, 174], individual_data[i, 176])
  genus_species_all = append(genus_species_all, combined_name)
}

individual_data$genus_species = genus_species_all

count_check_all = vector()
for (i in 1:nrow(individual_data)){
  word_count = sapply(gregexpr("\\S+", individual_data[i, 187]), length)
  count_check_all = append(count_check_all, word_count)
}

table(count_check_all)

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


