## useful functions and example data from NMNHfrom meeting w/ Dan 3/21/14 -------
# NMNH website: http://collections.nmnh.si.edu/search/mammals/

## read in csv with example data from misc California rodents--------------------
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




###### looking at species 1 (Peromyscus maniculatus) from NMNH -------------------

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
species1_masscoun = which(species1_masscoun == TRUE)
## specimens with mass info have county info

## mapping species 1 to determine spatial spread ------------------------------
# read in libary for maps
library(maps)

# map to show all locations of specimens w/ latitude and longitude
map('usa')
points(species1$Centroid.Longitude, species1$Centroid.Latitude, col='red', pch=19)
# alternative way to do this
# points(Centroid.Latitude ~ Centroid.Longitude, data=species1, col='red', pch=19)

lm(y ~ x, data) ## formula style

## create county database that is in correct format for map 
counties = map('county', fill=T, plot=F)
# put state and county columns together, separate by comma
sp_counties = paste(species1$Province.State, species1$District.County, sep=',')
# lowercase all
sp_counties = tolower(sp_counties)
# remove "county" at end
sp_counties = sub(' county', '', sp_counties)
# determine how many counties from NMNH list are in maps county list
sum(sp_counties %in% counties$names)
# use ! to show how many counties from NMNH list are NOT in maps county list
sp_counties[!(sp_counties %in% counties$names)]

## if a county in our county database occurs in the species database make it red
col = ifelse(counties$names %in% sp_counties, 'red', NA)
map('county', fill=T, col=col)

## export to pdf
dir.create('./figs/')
pdf('./figs/species1_county_pres_abs_map.pdf')
map('county', fill=T, col=col)
# why?
dev.off()


## convert county info to latitude/longitude -----------------------------------
library(ggmap)
latlon = geocode(species1$District.County, output = 'latlon')
write.table(latlon, "LatLonSpecies1.csv", sep = ",")
LatLonSpecies1 = read.csv("./LatLonSpecies1.csv")

# failed attempt to map specimen locations based on latitude and longitude
#map(LatLonSpecies1[1], LatLonSpecies1[2], col = 'red')


## add collection date to county fill map ---------------------------------------
#library(mapplots)
# something similar to add.pie, see http://uchicagoconsulting.wordpress.com/2011/04/18/how-to-draw-good-looking-maps-in-r/


## summary matrix of relevant info (lat/long, date, mass) ---------------------
# need to strip everything but mass value from species1 'Measurements' column
# use function gsub -- regular expressions, replacement = '[0-9]g', but what is pattern?
# pattern = '^Specimen Weight:', or 'Specimen.'
# regular expressions website http://www.zytrax.com/tech/web/regex.htm 

# Dan recommended splitting up the Measurements column by its separator and then searching
# for the mass info
species1mass = agrep('Specimen', 'HAHAHA', species1$Measurements)
species1mass = gsub('Specimen.', 'HAHAHA', species1$Measurements, fixed = F, ignore.case = T)
species1mass = gsub("", if('[0-9]g',NA), species1$Measurements)

SummaryTable = cbind(species1[13], LatLonSpecies1, species1[32])

## getting temperature data ----------------------------------------------------
# use University of Delaware air temp data? 
# use rgdal package to read in .nc file
library(rdgal)

# code from Dan to get temp from lat/lon/date summary table info 4/8/14
library(raster)
extract(bioStack, cbind(datTemp$Longitude,datTemp$Latitude))