# Using trait extraction data provided by Rob Guralnick

#-------DATASETS----------
library(readr)
individual_data = read_csv("VertnetTraitExtraction.csv")
subset_individual_data = individual_data[1:100,]

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

# Remove coordinates outside of range and transform longitudes
subset_individual_data$decimallatitude[subset_individual_data$decimallatitude > 90 | subset_individual_data$decimallatitude < -90] = NA
subset_individual_data$decimallongitude[subset_individual_data$decimallongitude > 180 | subset_individual_data$decimallongitude < -180] = NA
subset_individual_data$longitude = ifelse(subset_individual_data$decimallongitude < 0, subset_individual_data$decimallongitude + 360, subset_individual_data$decimallongitude)


# Create reference table of names for taxonomy resolution
original_names = unique(subset_individual_data$genus_species)
tax_res = data.frame(original_names)

# Check taxonomy of reference names using EOL Global Names Resolver
library(taxize)

ptm = proc.time()

# TODO: Make this loop more readable
# TODO: Refactor this
resolved_IDs = c()
for (i in 1:nrow(tax_res)){
  taxonomy_check = gnr_resolve(names = tax_res$original_names[i]) #lookup possible matching names
  if(sapply(gregexpr("\\S+", taxonomy_check$matched_name[1]), length) > 1){ #limit to submitted names w/ matching names that have at least two words
    if(taxonomy_check$submitted_name[1] == word(taxonomy_check$matched_name[1], 1, 2)){ #where submitted names are same as matching...
      ID = taxonomy_check$submitted_name[1] #...keep these
    } else { #then if they don't match, assume a typo in submitted name
      first_match = word(taxonomy_check$matched_name[1], 1, 2) 
      next_four = word(taxonomy_check$matched_name[2:5], 1, 2)
      number_matches = length(which(next_four %in% first_match))
      if(number_matches == 4){ #this is making sure that the first 5 matching names are identical
        ID = word(taxonomy_check$matched_name[1], 1, 2) #use matching name if so
      } else {
        ID = NA #if 5 matching names don't match
      }
    }
  } else {
    ID = NA #if matching name is only one word (just species probably)
  }
  resolved_IDs = append(resolved_IDs, ID)
}

proc.time() - ptm

count_words = function(name){
  number_words = sapply(gregexpr("\\S+", name), length)
  return(number_words)
}

all_names_match = function(names){
  clean_names = lapply(names, function(x) word(x, 1, 2))
  length(unique(clean_names)) == 1
}

resolved_IDs_new = c()
for (i in 1:nrow(tax_res)){
  taxonomy_check = gnr_resolve(names = tax_res$original_names[i])
  first_match = word(taxonomy_check$matched_name[1], 1, 2)
  if(count_words(first_match) < 2){
    IDs = NA
  } else if(tax_res$original_names[i] == first_match){
    IDs = tax_res$original_names[i]
  } else if(all_names_match(taxonomy_check$matched_name[1:5])){
    IDs = first_match
  }
  print(IDs)
  #resolved_IDs_new = append(resolved_IDs_new, IDs)
}


# Use resolved reference names to get correct names in dataset
tax_res$resolved_names = resolved_IDs
subset_individual_data$res_genus_species = tax_res$resolved_names[match(subset_individual_data$genus_species, tax_res$original_names)]
