# Using trait extraction data provided by Rob Guralnick

#-------DATASETS----------
library(readr)
individual_data = read_csv("VertnetTraitExtraction.csv")

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
  clean_names = lapply(strings, function(x) try(word(x, 1, 2), silent = TRUE))
  length(unique(clean_names)) == 1
}

chunk_df = function(df){
  # Split dataframe up into chunks of 100 rows
  # 
  # Args: 
  #   df: Dataframe to be split up
  #
  # Returns: 
  #   Lists of 100 rows of entire dataframe
  chunk_nums = seq(100, round(nrow(df), digits = -2), 100)
  chunks = lapply(seq_along(chunk_nums), function(x) df[(chunk_nums - 99)[x]:chunk_nums[x],])
  return(chunks)
}

library(taxize)
library(spatstat)
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
    if(is.empty(tax_out)){
      name = NA
    } else if(count_words(tax_out$matched_name[1]) < 2){
      name = NA
    } else if(tax_out$submitted_name[1] == word(tax_out$matched_name[1], 1, 2)){
      name = tax_out$submitted_name[1]
    } else if(all_names_match(tax_out$matched_name[1:5])){
      name = word(tax_out$matched_name[1], 1, 2)
    } else {
      name = NA
    }
    print(name)
    resolved_names = append(resolved_names, name)
  }
  return(resolved_names)
}

check_chunks = function(chunks_list, names_list){
  # Run taxonomy resolution fx on all chunks and clean up output
  # 
  # Args: 
  #   chunks_list: Chunks of dataframe
  # 
  # Returns: 
  #   List of all clean names that can be combined with original names
  checked_chunks = lapply(chunks_list, function(x) {y = resolve_names(x) 
                                                    Sys.sleep(3)
                                                    print(y)
                                                    return(y)})
  checked_chunks = unlist(checked_chunks)
  checked_chunks = checked_chunks[1:nrow(names_list)]
  return(checked_chunks)
}

#-----FUNCTIONS ON ENTIRE DATASET----------

ptm = proc.time()
# Create column containing only mass value for each individual
individual_data$mass = extract_component(individual_data$normalized_body_mass, "total weight\", ([0-9.]*)" )
proc.time() - ptm

ptm = proc.time()
# Create column containing only genus and species
individual_data$genus_species = extract_genus_species(individual_data$scientificname)
proc.time() - ptm

ptm = proc.time()
# Fix taxonomic names using EOL Global Names Resolver, chunk dataset to not overload API
subset_names = data.frame(unique(individual_data$genus_species))
colnames(subset_names) = "original"
chunks = chunk_df(subset_names)
checked_names = check_chunks(chunks, subset_names)
proc.time() - ptm

#######################
subset_names$checked = checked_names
individual_data$clean_genus_species = subset_names$checked[match(individual_data$genus_species, subset_names$original)]

# Remove coordinates outside of range and transform longitudes
individual_data$decimallatitude[individual_data$decimallatitude > 90 | individual_data$decimallatitude < -90] = NA
individual_data$decimallongitude[individual_data$decimallongitude > 180 | individual_data$decimallongitude < -180] = NA
individual_data$longitude = ifelse(individual_data$decimallongitude < 0, individual_data$decimallongitude + 360, individual_data$decimallongitude)
