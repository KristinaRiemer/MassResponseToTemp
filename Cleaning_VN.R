#-------LIBRARIES----------
library(readr)
library(stringr)
library(taxize)
library(spatstat)
library(dplyr)

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

#-----FUNCTIONS ON ENTIRE DATASET----------

# Create or read in cleaned taxonomy file
clean_taxonomy("data/clean_taxonomy.csv", "data/raw.csv")
individual_data = read_csv("data/clean_taxonomy.csv")

# Remove coordinates outside of range and transform longitudes
individual_data$decimallatitude[individual_data$decimallatitude > 90 | individual_data$decimallatitude < -90] = NA
individual_data$decimallongitude[individual_data$decimallongitude > 180 | individual_data$decimallongitude < -180] = NA
individual_data$longitude = ifelse(individual_data$decimallongitude < 0, individual_data$decimallongitude + 360, individual_data$decimallongitude)

#----SUBSETTING DATASET----

# Subset dataset to retain only individuals with collected 1900-2010, has mass, 
# species ID, and coordinates
individual_data = individual_data[(individual_data$year >= 1900 & individual_data$year <= 2010),]
individual_data = individual_data[complete.cases(individual_data$massing),]
individual_data = individual_data[complete.cases(individual_data$clean_genus_species),]
individual_data = individual_data[(complete.cases(individual_data$decimallatitude) & complete.cases(individual_data$longitude)),]
colnames(individual_data)[1] = "row_index"
individual_data$X1_1 = NULL

# Subset dataset to retain only individuals from species with more than 30 individuals, 
# at least 20 years, and at least 5 latitudinal degrees
species_list = individual_data %>%
  group_by(clean_genus_species) %>%
  summarise(
    individuals = n(), 
    year_range = max(year) - min(year), 
    lat_range = max(decimallatitude) - min(decimallatitude)
  ) %>%
  filter(
    individuals >= 30, 
    year_range >= 20, 
    lat_range >= 5
  )

individual_data = individual_data[individual_data$clean_genus_species %in% species_list$clean_genus_species,]

# Removing juveniles

# Adult categories
# skull ossification? 

"adult"
"ad"
"U-Ad."
"U-Ad"
"Adult"
"Ad."
"Ad"
"Aged Adult"
"young adult"
"adult adult"
"suspected adult"
"Aged adult"
"old adult"
"adult; over-winter"
"ADULT"
"adult; young of year"
"Ad. Summer"
"Adult."
"U-AD"

# TODO: if species doesn't have "adult" as an underivedlifestage, there is still one individual left in final
# TODO: include rest of adult classifications as possible threshold
individual_data_sub3 = individual_data %>%
  #filter(clean_genus_species == "Odobenus rosmarus" | clean_genus_species == "Blarina carolinensis") %>%
  group_by(clean_genus_species) %>%
  arrange(massing) %>%
  mutate(firstad = min(which(underivedlifestage == "adult" | row_number() == n())), 
         total_inds = n()) %>%
  filter(row_number() >= firstad) %>%
  summarise(original_inds = mean(total_inds), 
            row_with_adult = mean(firstad), 
            rows_deleted = mean(firstad) - 1)

individual_data_sub3$percent_deleted = individual_data_sub3$rows_deleted / individual_data_sub3$original_inds * 100
individual_data_sub3$diff = individual_data_sub3$original_inds - individual_data_sub3$rows_deleted
individual_data_sub3a = individual_data_sub3[individual_data_sub3$diff != 1,]
plot(individual_data_sub3a$percent_deleted)
hist(individual_data_sub3a$percent_deleted)

write.csv(individual_data, "CompleteDatasetVN.csv")
