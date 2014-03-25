##### useful functions and example data from NMNHfrom meeting w/ Dan 3/21/14
##### NMNH website: http://collections.nmnh.si.edu/search/mammals/

## read in csv with example data from misc California rodents
dat = read.csv('./ExampleDataNMNH.csv')

## str function retrieves types of information in each column of dataset
str(dat)

## dim function shows number of rows and columns in dataset
dim(dat)

## names function shows column headers
names(dat)

## use $ to subset Measurements column from dataset
## as.character function turns all data entries into strings
dat$Measurements = as.character(dat$Measurements)


?sub
?substr
?grep

## using grep to show which columns contain mass information by searching for 
## data with format [number]g
tst = grep('[0-9]g', dat$Measurements)

## reads out information from the first five columns that contain mass info
dat$Measurements[tst][1:5]


###### looking at species 1 (Peromyscus maniculatus) from NMNH
## read in csv with data
species1 = read.csv('./PeromyscusmanDataNMNH.csv')

## subset measurements column, determine how many rows contain mass information
species1$Measurements = as.character(species1$Measurements)
species1_mass = grep('[0-9]g', species1$Measurements)
length(species1_mass)

## subset lat column, determine how many rows contain latitude information
species1$Centroid.Latitude = as.character(species1$Centroid.Latitude)
species1_lat = grep('[1-9]', species1$Centroid.Latitude)
length(species1_lat)


## subset county column, determine how many rows contain county information
## there has to be an easier way to do this!
species1$District.County = as.character(species1$District.County)
species1_county = grep('^$', species1$District.County)
length(species1$District.County) - length(species1_county)

