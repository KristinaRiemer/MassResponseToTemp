# Using trait extraction data provided by Rob Guralnick

#-------DATASETS----------
library(readr)
individual_data = read_csv("VertnetTraitExtraction.csv")
subset_individual_data = individual_data[1:2175,]

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

count_words = function(string){
  # Count the number of words in a string
  #
  # Args: 
  #   string: The string for which the number of words is desired
  #
  # Returns: 
  #   Number of words in the string
  number_words = sapply(gregexpr("\\S+", string), length)
  return(number_words)
}

all_names_match = function(strings){
  # Determine if multiple strings are identical after extracting first two words
  # of each
  # 
  # Args: 
  #   strings: The strings that are cleaned and matched
  #
  # Returns: 
  #   TRUE if all strings match, FALSE if any of them do not
  clean_names = lapply(strings, function(x) word(x, 1, 2))
  length(unique(clean_names)) == 1
}

library(taxize)
resolve_names = function(names_list){
  # Check and clean up taxonomic names
  #
  # Args: 
  #   names_list: List of taxonomic names
  #
  # Returns: 
  #   List where NAs are names that only had genus, original name is retained if
  #   correct, and new name if original name had typo
  resolved_names = c()
  for (i in 1:length(names_list)){
    tax_out = gnr_resolve(names = names_list[i])
    if(count_words(tax_out$matched_name[1]) < 2){
      name = NA
    } else if(tax_out$submitted_name[1] == word(tax_out$matched_name[1], 1, 2)){
      name = tax_out$submitted_name[1]
    } else if(all_names_match(tax_out$matched_name[1:5])){
      name = word(tax_out$matched_name[1], 1, 2)
    }
    resolved_names = append(resolved_names, name)
  }
  return(resolved_names)
}

#-----FUNCTIONS ON ENTIRE DATASET----------

# Create column containing only mass value for each individual
subset_individual_data$mass = extract_component(subset_individual_data$normalized_body_mass, "total weight\", ([0-9.]*)" )
#individual_data$mass = extract_component(individual_data$normalized_body_mass, "total weight\", ([0-9.]*)" )

# Create column containing only genus and species
subset_individual_data$genus_species = extract_genus_species(subset_individual_data$scientificname)
#ptm = proc.time()
#individual_data$genus_species = extract_genus_species(individual_data$scientificname)
#proc.time() - ptm

#write.csv(individual_data, file = "VN_taxonomy.csv")
#individual_data_taxonomy = read_csv("VN_taxonomy.csv")

# Check and fix taxonomic names using EOL Global Names Resolver
original_names = unique(individual_data_taxonomy$genus_species)
unique_names = data.frame(original_names)
###############
unique_names$resolved_names = resolve_names(unique_names$original_names)
subset_individual_data$clean_genus_species = unique_names$resolved_names[match(subset_individual_data$genus_species, unique_names$original_names)]

### Chunking dataset to avoid overloading taxize API
subset_names = data.frame(unique(subset_individual_data$genus_species))
colnames(subset_names) = "original"

# One function, to chunk dataset by 100s
chunk_num = seq(100, round(nrow(subset_names), digits = -2), 100)
chunks = lapply(seq_along(chunk_num), function(i) subset_names[(chunk_num-99)[i]:chunk_num[i], ])

# Second function, to check tax of chunks and remove NAs from bottom
checked_chunks = lapply(chunks, function(x) {y = resolve_names(x); Sys.sleep(3); return(y)})
checked_chunks = unlist(checked_chunks)
checked_chunks = checked_chunks[1:nrow(subset_names)]
subset_names$checked = checked_chunks

# Remove coordinates outside of range and transform longitudes
subset_individual_data$decimallatitude[subset_individual_data$decimallatitude > 90 | subset_individual_data$decimallatitude < -90] = NA
subset_individual_data$decimallongitude[subset_individual_data$decimallongitude > 180 | subset_individual_data$decimallongitude < -180] = NA
subset_individual_data$longitude = ifelse(subset_individual_data$decimallongitude < 0, subset_individual_data$decimallongitude + 360, subset_individual_data$decimallongitude)
