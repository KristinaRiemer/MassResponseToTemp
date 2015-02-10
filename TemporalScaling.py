from __future__ import division

# Read in new individual data
import pandas as pd
individual_data = pd.read_csv("CompleteDatasetUS.csv")
individual_data_subset = individual_data.iloc[0:10]

# Packages for reading in temperature data
# http://www.esrl.noaa.gov/psd/data/gridded/data.UDel_AirT_Precip.html
from osgeo import gdal
from osgeo.gdalconst import *
gdal.AllRegister()
driver = gdal.GetDriverByName("netCDF")

# Temperature dataset
temp_file = "air.mon.mean.v301.nc"

# List of months with corresponding codes for stackID
# stackID = year * 12 - monthcode
import calendar
month_names = []
for each_month in range(1, 13):
    month_names.append(calendar.month_name[each_month])
month_codes = pd.DataFrame(month_names, columns = ["month"])
month_codes["code"] = range(22799, 22787, -1)
#How to use this as a lookup table?
#month_codes["code"][month_codes["month"] == "July"]

# Only monthly average for now, later add 3 month average option
def get_stackIDs(current_year, month_code):
    """Get stackIDs for chosen month in current and previous years until 1900
    
    Args:
        current_year: Collection year for first stackID
        month_code: Code for chosen month
    
    Returns:
        List of stackIDs for chosen month from current year back to 1900
    """
    current_stackID = current_year * 12 - month_code
    all_stackIDs = []
    while current_stackID > 0:
        all_stackIDs.append(current_stackID)
        current_stackID -= 12
    return all_stackIDs

# Get all July stackID values for each individual in subset dataset
july_code = 22793
stackIDs_july_subset = []
for each_year in individual_data_subset["year"]:
    stackIDs_july_eachyear = get_stackIDs(each_year, july_code)
    stackIDs_july_subset.append(stackIDs_july_eachyear)

def get_temp_at_point(raster_file, coordinates, band):
    """Determine temperature value at chosen coordinates and band of raster
    
    Args:
        raster_file: file name of raster
        coordinates: chosen coordinates, order is longitude and latitude
        band: chosen band (i.e., month)
    
    Returns: 
        Unpacked temperature at coordinates in band
    """
    entire_raster = gdal.Open(raster_file)    #opens raster file
    single_band = entire_raster.GetRasterBand(band)    #get desired band from raster stack
    geotrans_raster = entire_raster.GetGeoTransform()    #geotranforms raster to get gt points below
    #entire_raster = None    #closes file, considered good practice, causes to abort?
    x = int((coordinates[0] - geotrans_raster[0])/geotrans_raster[1])    #calculates offset for x
    y = int((coordinates[1] - geotrans_raster[3])/geotrans_raster[5])    #calculates offset for y
    band_array = single_band.ReadAsArray()    #creates array of temperatures for specific band
    packed_temp = band_array[y, x]    #outputs packed temp at offset from that array (short integer)
    add_offset = single_band.GetOffset()    #get offset to unpack
    scale_factor = single_band.GetScale()    #get scale factor to unpack
    unpacked_temp = add_offset + (packed_temp * scale_factor)
    return unpacked_temp

def get_multiple_temps(stackIDs_list, file_name, coordinates):
    """Get all temperature values for list of stackIDs
    
    Args: 
        stackIDs_list: list of stackID values (i.e., months)
        file_name: name of raster file
        coordinates: longitude and latitude of individual
    
    Returns: 
        List containing all respective temperatures for stackIDs in list
    """
    temps_list = []    
    for current_stackID in stackIDs_list: 
        each_temp = get_temp_at_point(file_name, coordinates, current_stackID)
        temps_list.append(each_temp)
    return temps_list

# Get all temps for corresponding July stackIDs for each individual in subset dataset
july_temps_subset = []
for i in range(len(individual_data_subset)):
    individual_temps_subset = get_multiple_temps(stackIDs_july_subset[i], temp_file, 
                                individual_data_subset.iloc[i][["lon", "lat"]])
    july_temps_subset.append(individual_temps_subset)

# Create final dataset
# Need to change range to be automated for greatest length
column_names = ["past_year_{}" .format(year) for year in range(41)]
july_temps_subset = pd.DataFrame(july_temps_subset, columns=column_names)
july_yearlag_subset = pd.concat([individual_data_subset[["genus_species", "mass", 
                                "year"]], july_temps_subset], axis=1)



# Subset dataset by unique species with unique past years, select on those subsets
# with all temps (i.e., no nulls in past year col), graph those subsets and save
# all in single pdf, get pvalue, r2, and slope from lin reg for each subset

# What do do about RuntimeWarning? Moving close around didn't work

# See dir(linreg_results) for all possible parts of lin reg summary

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import statsmodels.api as sm
#all_of_them = []
#pp = PdfPages("all_figs.pdf")
##linreg_stats = []
#species_r2 = []
#for unique_species in july_yearlag_subset["genus_species"].unique()[0], july_yearlag_subset["genus_species"].unique()[-1]:
    ##print unique_species
    #unique_species_data = july_yearlag_subset[july_yearlag_subset["genus_species"] == unique_species]
    ##print unique_species_data
    #for current_past_year in column_names:
        #unique_year_data = unique_species_data[[col for col in unique_species_data.columns if col == current_past_year]]
        #unique_year_mass = pd.concat([unique_species_data["mass"], unique_year_data], axis=1)
        #all_of_them.append(unique_year_mass)
        #if np.all(pd.notnull(unique_year_mass.iloc[:,1])):
             ## doing linear regression
            #linreg = sm.regression.linear_model.OLS(unique_year_mass.iloc[:,0], unique_year_mass.iloc[:,1])
            #linreg_results = linreg.fit()
            #r2 = linreg_results.rsquared
            #pval = linreg_results.pvalues
            #slope = linreg_results.params
            ##linreg_stats.append([pval, r2, slope])
            #species_r2.append([current_past_year, r2])
            ## plotting points, one figure per species per past year
            #plt.figure()
            #plt.plot(unique_year_mass.iloc[:,1], unique_year_mass.iloc[:,0], "bo")
            #plt.plot(unique_year_mass.iloc[:,1], linreg_results.fittedvalues, "r-")
            #pp.savefig() 
#pp.close()

# Redo what was done above with just a single species (Myodes gapperi), purpose
# is to get a figure of r2 values for each past year for that species

# Get single species subset
single_species = july_yearlag_subset[july_yearlag_subset["genus_species"] == "Myodes gapperi"]

# For single species, do lin reg and plot mass and each past year temp, get
# list of r2 values for each combination
pp2 = PdfPages("single_species_plots.pdf")
r2_single_list = []
for each_year in column_names:
    each_year_temp = single_species[[col for col in single_species.columns if col == each_year]]
    mass_temp = pd.concat([single_species["mass"], each_year_temp], axis=1)
    if np.all(pd.notnull(mass_temp.iloc[:,1])):
        #print mass_temp
        linreg_single = sm.regression.linear_model.OLS(mass_temp.iloc[:,0], mass_temp.iloc[:,1])
        linreg_results_single = linreg_single.fit()
        r2_single = linreg_results_single.rsquared
        r2_single_list.append(r2_single)
        plt.figure()
        plt.plot(mass_temp.iloc[:,1], mass_temp.iloc[:,0], "ro")
        plt.plot(mass_temp.iloc[:,1], linreg_results_single.fittedvalues, "r-")
        pp2.savefig()
pp2.close()
r2_single_list = pd.DataFrame(r2_single_list)
r2_single_list.columns = ["myodes_gapperi"]

# Need function to create subsets for each species in dataset

# Function to get r2 values list for any particular species for all mass/past 
# year temp combos
# Don't know how to generalize this to be able to input any desired stat, so 
# particular to r2 currently 
def get_r2_list(dataset, first_variable, second_vari_list):
    """Get R^2 values for linear regression of one variable with a second 
    variable across many scales or lags
    
    Args:
        dataset: Dataset that contains both variables
        first_variable: Column that contains values of the first variable
        second_vari_list: List of names of columns that contain values of second
        variable
    
    Returns:
        List containing R^2 values for each first and second variable combination
    """
    r2_list = []
    for each_variable in second_vari_list:
        each_vari_subset = dataset[[col for col in dataset.columns if col == each_variable]]
        each_combo = pd.concat([first_variable, each_vari_subset], axis=1)
        if np.all(pd.notnull(each_combo.iloc[:,1])):
            linreg = sm.regression.linear_model.OLS(each_combo.iloc[:,0], each_combo.iloc[:,1])
            linreg_results = linreg.fit()
            r2 = linreg_results.rsquared
            r2_list.append(r2)
    return r2_list

testing_r2_fx = get_r2_list(single_species, single_species["mass"], column_names)


###############
past_year = pd.DataFrame(range(29))
past_year.columns = ["past_year"]

r2_single_list = pd.concat([past_year, r2_single_list], axis = 1)

plt.figure()
plt.plot(r2_single_list["past_year"], r2_single_list["myodes_gapperi"], "bo")
plt.show()

## Using pandas groupby, what is the benefit? 
#by_species = july_yearlag_subset.groupby("Species.Genus")
#for species, species_data in by_species:
    #avg_mass = np.mean(species_data["Mass"])
    #print "Avg mass of {} is {}" .format(species, avg_mass)

#pp2 = PdfPages("all_figs_2.pdf")
#by_species = july_yearlag_subset.groupby("Species.Genus")
#for species, species_data in by_species:
    #for current_past_year in column_names:







