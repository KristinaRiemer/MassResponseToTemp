from __future__ import division

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import statsmodels.api as sm

# Read in new individual data
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

# Function to create PDF for each species containing individual plots for mass 
# and each previous year's temperature

# What do do about RuntimeWarning? Moving close around didn't work
def plot_linreg(dataset, first_variable, second_vari_list, plot_name):
    """Get scatterplots of first and second variables with linear reg line, where
    second variable is across many lags or scales
    
    Args:
        dataset: Dataset that contains both variables
        first_variable: Column that contains values of first variable
        second_vari_list: List of names of columns that contain values of second
        variable
        plot_name: Desired name of pdf
    
    Returns:
        PDF with all scatterplots of first and second variables, with first on
        x-axis and second on y-axis
    """
    pp = PdfPages(plot_name+"_linreg.pdf")
    for each_variable in second_vari_list:
            each_vari_subset = dataset[[col for col in dataset.columns if col == each_variable]]
            each_combo = pd.concat([first_variable, each_vari_subset], axis=1)
            if np.all(pd.notnull(each_combo.iloc[:,1])):
                linreg = sm.regression.linear_model.OLS(each_combo.iloc[:,0], each_combo.iloc[:,1])
                linreg_results = linreg.fit()   
                plt.figure()
                plt.plot(each_combo.iloc[:,1], each_combo.iloc[:,0], "bo")
                plt.plot(each_combo.iloc[:,1], linreg_results.fittedvalues, "r-")
                plt.xlabel("Temperature from "+each_variable)
                plt.ylabel("Mass (g)")
                pp.savefig()
    pp.close()

# Group dataset by species and get pdfs of all mass-temp (one for each past year)
# plots for each species
data_by_species = july_yearlag_subset.drop([4]).groupby("genus_species")
for species, species_data in data_by_species:
    species = species.replace(" ", "_")
    linreg_plots = plot_linreg(species_data, species_data["mass"], column_names, species)

# Function to get r2 values list for any particular species for all mass/past 
# year temp combos
# To generalize, will be able to input desired stat
# See dir(linreg_results) for all possible parts of lin reg summary
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
        if np.all(pd.notnull(each_vari_subset)):
            linreg = sm.regression.linear_model.OLS(first_variable, each_vari_subset)
            linreg_results = linreg.fit()
            r2 = linreg_results.rsquared
            r2_list.append(r2)
    return r2_list

# Group dataset by species and apply r2 function to each species group to get
# list containing all r2 values for each species

# Have to temporarily remove the fourth row, species with one individual in subset
# Automate past year column length somehow? 
all_r2 = pd.DataFrame(range(41))
species_list = []
all_r2.columns = ["past_year"]
data_by_species = july_yearlag_subset.drop([4]).groupby("genus_species")
for species, species_data in data_by_species:
    species = species.replace(" ", "_")
    species_list.append(species)
    r2_species = get_r2_list(species_data, species_data["mass"], column_names)
    r2_species = pd.DataFrame(r2_species)
    r2_species.columns = [species]
    all_r2[species] = r2_species

# Repeat function and code for r2 list but for slope instead
def get_slope_list(dataset, first_variable, second_vari_list):
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
    slope_list = []
    for each_variable in second_vari_list:
        each_vari_subset = dataset[[col for col in dataset.columns if col == each_variable]]
        if np.all(pd.notnull(each_vari_subset)):
            linreg = sm.regression.linear_model.OLS(first_variable, each_vari_subset)
            linreg_results = linreg.fit()
            slope = linreg_results.params[0]
            slope_list.append(slope)
    return slope_list

all_slope = pd.DataFrame(range(41))
species_list = []
all_slope.columns = ["past_year"]
data_by_species = july_yearlag_subset.drop([4]).groupby("genus_species")
for species, species_data in data_by_species:
    species = species.replace(" ", "_")
    species_list.append(species)
    slope_species = get_slope_list(species_data, species_data["mass"], column_names)
    slope_species = pd.DataFrame(slope_species)
    slope_species.columns = [species]
    all_slope[species] = slope_species

# Create PDF containing fig for each species of past year and r2 value/slope
pp = PdfPages("all_stats_figs.pdf")
for each_species in species_list: 
    species_r2 = all_r2[[col for col in all_r2.columns if col == each_species]]
    species_slope = all_slope[[col for col in all_slope.columns if col == each_species]]
    plt.figure()
    plt.plot(all_r2["past_year"], species_r2, "bo")
    plt.plot(all_slope["past_year"], species_slope, "ro")
    plt.xlabel("Past Year")
    plt.ylabel("R^2")
    plt.title(each_species)
    pp.savefig()
pp.close()
