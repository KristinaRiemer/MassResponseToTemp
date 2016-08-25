#-------LIBRARIES----------
library(readr)
library(stringr)
library(taxize)
library(spatstat)

#-------FUNCTIONS---------
clean_taxonomy = function(tax_file_path, raw_file_path){ 
  # Clean up species names from raw data
  #
  # Args: 
  #   tax_file_path: file path to check if taxonomy file exists or create it
  #   raw_file_path: file path to raw data
  #
  # Returns: 
  #   If it doesn't already exist, new csv containing raw data plus clean names
  #   column
  if(!file.exists(tax_file_path)){
    individual_data = read_csv(raw_file_path)
    individual_data$genus_species = extract_genus_species(individual_data$scientificname)
    subset_names = data.frame(unique(individual_data$genus_species))
    colnames(subset_names) = "original"
    chunks = chunk_df(subset_names)
    subset_names$checked = check_chunks(chunks, subset_names)
    subset_names[subset_names == "Environmental Halophage"] = NA
    subset_names$checked = gsub("sp\\.", NA, subset_names$checked)
    individual_data$clean_genus_species = subset_names$checked[match(individual_data$genus_species, subset_names$original)]
    write.csv(individual_data, file = tax_file_path)
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

# Create or read in cleaned taxonomy file
ptm = proc.time()
clean_taxonomy("data/clean_taxonomy.csv", "data/raw.csv")
proc.time() - ptm
individual_data = read_csv("data/clean_taxonomy.csv")

# Create columns for mass and length for each individual
individual_data$mass = extract_component(individual_data$normalized_body_mass, "total weight\", ([0-9.]*)" )
individual_data$length = extract_component(individual_data$normalized_total_length, "total length\", ([0-9.]*)" )

# Remove coordinates outside of range and transform longitudes
individual_data$decimallatitude[individual_data$decimallatitude > 90 | individual_data$decimallatitude < -90] = NA
individual_data$decimallongitude[individual_data$decimallongitude > 180 | individual_data$decimallongitude < -180] = NA
individual_data$longitude = ifelse(individual_data$decimallongitude < 0, individual_data$decimallongitude + 360, individual_data$decimallongitude)

#----SUBSETTING DATASET----

# Subset dataset to retain only individuals collected 1900-2010, with species ID, 
# and coordinates
individual_data = individual_data[(individual_data$year >= 1900 & individual_data$year <= 2010),]
individual_data = individual_data[complete.cases(individual_data$clean_genus_species),]
individual_data = individual_data[(complete.cases(individual_data$decimallatitude) & complete.cases(individual_data$longitude)),]

individual_data = individual_data[(complete.cases(individual_data$mass) | complete.cases(individual_data$length)),]

colnames(individual_data)[1] = "row_index"

# Size counts
library(dplyr)
new_species_df = individual_data %>%
  group_by(clean_genus_species) %>%
  summarise(
    num_inds = n(),
    class = str_c(unique(class), collapse = ","),
    num_mass = sum(complete.cases(mass)),
    num_length = sum(complete.cases(length)), 
    year_range = max(year) - min(year), 
    lat_range = max(decimallatitude) - min(decimallatitude)
  ) %>% 
  filter(
    num_mass > 30 | num_length > 30, 
    year_range >= 20, 
    lat_range >= 5
  ) 

# TODO: Add in choosing mass if num_mass = num_length
new_species_df$choose_mass = new_species_df$num_mass > new_species_df$num_length
new_species_df$choose_length = new_species_df$num_mass < new_species_df$num_length

unique_coords = unique(all_individuals[c("map_long", "decimallatitude")])

fish_coords = unique(fishes[c("decimallongitude", "decimallatitude")])
library(rworldmap)
map = getMap(resolution = "high")
plot(map)
points(fish_coords$decimallongitude, fish_coords$decimallatitude, pch = 20, cex = 0.1, col = "red")

points(unique_coords$map_long, unique_coords$decimallatitude, pch = 20, cex = 0.1, col = "red")


# TODO: Subset dataset to retain individuals whose species are in list

# Save dataset as CSV to be used as input for Python code
write.csv(individual_data, "CompleteDatasetVN.csv")
