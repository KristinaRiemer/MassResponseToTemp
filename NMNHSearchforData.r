##### useful functions and example data from NMNHfrom meeting w/ Dan 3/21/14
##### NMNH website: http://collections.nmnh.si.edu/search/mammals/

## read in csv with example data from misc California rodents---------------
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

## determine how many rows contain latitude information
species1_lat = which(species1$Centroid.Latitude > 0)
length(species1_lat)

## make county column values into strings, determine how many rows contain county information
species1$District.County = as.character(species1$District.County)
species1_county = which(species1$District.County > 0)
length(species1_county)

## determine how many specimens have lat and county information (using and operator)
species1_latcoun = which(species1$Centroid.Latitude > 0 & species1$District.County > 0)
## specimens with latitude info have county info

## determine how many species have mass and county information
species1_masscoun = grepl('[0-9]g', species1$Measurements) & species1$District.County > 0
length(which(species1_masscoun == TRUE))
## specimens with mass info have county info

## Map records ------------------------------------------------------------------
library(maps)
?map
map('usa')
points(species1$Centroid.Longitude, species1$Centroid.Latitude, col='red', pch=19)
#points(Centroid.Latitude ~ Centroid.Longitude, data=species1, col='red', pch=19)

lm(y ~ x, data) ## formula style

## create county database
counties = map('county', fill=T, plot=F)

sp_counties = paste(species1$Province.State, species1$District.County, sep=',')
sp_counties = tolower(sp_counties)
sp_counties = sub(' county', '', sp_counties)

sum(sp_counties %in% counties$names)
sp_counties[!(sp_counties %in% counties$names)]

## if a county in our county database occurs in the species database make it red
col = ifelse(counties$names %in% sp_counties, 'red', NA)
map('county', fill=T, col=col)

## export to pdf
dir.create('./figs/')
pdf('./figs/species1_county_pres_abs_map.pdf')
map('county', fill=T, col=col)
dev.off()

