from __future__ import division
import pandas as pd
from osgeo import gdal
import calendar
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import statsmodels.api as sm

# Datasets
individual_data = pd.read_csv("CompleteDatasetUS.csv")
individual_data_subset = individual_data.iloc[0:10]

gdal.AllRegister()
driver = gdal.GetDriverByName("netCDF")
temp_file = "air.mon.mean.v301.nc"

# Functions
def create_month_codes_list(jan_code, dec_code, diff):
    """Create list of month names and corresponding codes
    
    Args: 
        jan_code: Code corresponding to month of January
        dec_code: Code corresponding to month of December
        diff: What value to add/subtract between each month code
    
    Returns: 
        List of month names and codes
    """
    month_names = []
    for each_month in range(1, 13):
        month_names.append(calendar.month_name[each_month])
    month_codes = pd.DataFrame(month_names, columns = ["month"])
    month_codes["code"] = range(jan_code, dec_code, diff)
    return month_codes

def get_stackIDs(current_year, month_code):
    # TODO: incorporate 3 month average option
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

def get_multiple_stackIDs(year_list, code):
    """Get list of stackIDs lists for multiple chosen years for chosen month
    
    Args: 
        year_list: List of chosen years
        code: Chosen month
    
    Returns: List of stackID lists for multiple years
    """
    multiple_stackIDs = []
    for each_year in year_list:
        stackIDs_eachyear = get_stackIDs(each_year, code)
        multiple_stackIDs.append(stackIDs_eachyear)
    return multiple_stackIDs

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

def get_temps_list(stackIDs_list, file_name, coordinates):
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

def get_multiple_temps_lists(all_stackIDs, temps_lookup, coords1, coords2): 
    """Get list of temperatures for each individual nested in a list for all individuals
    
    Args: 
        all_stackIDs: List of list of stackID values
        temps_lookup: File containining temperatures
        coords1: List of first coordinates for all individuals (longitude)
        coords2: List of second coordinates for all individuals (latitude)
    
    Returns: 
        List of list with all past year temperatures for all individuals
    """
    multiple_temps_lists = []
    coords_list = pd.DataFrame([coords1, coords2])
    coords_list = coords_list.T    
    for i in range(len(all_stackIDs)):
        each_temps_list = get_temps_list(all_stackIDs[i], temps_lookup, coords_list.iloc[i])
        multiple_temps_lists.append(each_temps_list)
    return multiple_temps_lists

def create_temp_dataset(number_pastyears, dataset, species_col, mass_col, year_col):
    # TODO: Automate number of past years
    """Put temperature lists into usable Pandas format
    
    Args: 
        number_pastyears: Maximum number of past years with temp data
        dataset: Temperature list of lists dataset
        species_col: Column containing species information for each individual
        mass_col: Column containing mass information for each individual
        year_col: Column containing year information for each individual
    
    Returns: 
        Pandas dataset with columns for species, mass, year, and all past year
        temperatures for each individual
    """
    column_names_test = ["past_year_{}" .format(year) for year in range(number_pastyears)]
    with_column_names = pd.DataFrame(dataset, columns = column_names_test)
    temp_dataset_final = pd.concat([species_col, mass_col, year_col, with_column_names], axis = 1)
    return temp_dataset_final

def plot_linreg(dataset, first_variable, second_vari_list, plot_name):
    # FIXME: RuntimeWarning; didn't help to move location of close
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

def get_r2_list(dataset, first_variable, second_vari_list):
    # TODO: be able to input desired stat to generalize, would eliminate slope fx
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


# List of months with corresponding stackID codes
month_codes = create_month_codes_list(22799, 22787, -1)

# Get all July stackID values for each individual in subset dataset
# TODO: use month_names as lookup table, e.g., month_codes["code"][month_codes["month"] == "July"]
july_code = 22793 
stackIDs_july_subset = get_multiple_stackIDs(individual_data_subset["year"], july_code)

# Get all July temperatures for each individual in subset dataset
temps_july_subset = get_multiple_temps_lists(stackIDs_july_subset, temp_file, individual_data_subset["lon"], individual_data_subset["lat"])

# Create final temperature dataset
final_temps_july_subset = create_temp_dataset(41, temps_july_subset, individual_data_subset["genus_species"], individual_data_subset["mass"], individual_data_subset["year"])

# Group dataset by species and get pdfs of all mass-temp (one for each past year)
# plots for each species
data_by_species = july_yearlag_subset.drop([4]).groupby("genus_species")
for species, species_data in data_by_species:
    species = species.replace(" ", "_")
    linreg_plots = plot_linreg(species_data, species_data["mass"], column_names, species)

# Generate r2 values for each species and past year
# FIXME: remove fourth row restriction, only applies to subset dataset
# TODO: automate past year column length
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

# Generate slope values for each species and past year
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
