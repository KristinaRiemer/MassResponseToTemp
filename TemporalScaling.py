from __future__ import division
import pandas as pd
from osgeo import gdal
import calendar
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import statsmodels.api as sm
import time
import statsmodels.formula.api as smf

def create_month_codes_dict(jan_code, dec_code, diff):
    """Create dict of month names and corresponding codes
    
    Args: 
        jan_code: Code corresponding to month of January
        dec_code: Code corresponding to month of December
        diff: What value to add/subtract between each month code
    
    Returns: 
        Dict of month names and codes
    """
    month_names = []
    for each_month in range(1, 13):
        month_names.append(calendar.month_name[each_month])
    codes = range(jan_code, dec_code, diff)
    month_codes = {}
    for month, code in zip(month_names, codes):
        month_codes[month] = code
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
    all_stackIDs = range(current_stackID, 0, -12)
    return all_stackIDs

def get_temp_at_point(raster_file, coordinates, band):
    """Determine temperature value at chosen coordinates and band of raster
    
    Args:
        raster_file: file name of raster
        coordinates: chosen coordinates, order is longitude and latitude
        band: chosen band (i.e., month)
    
    Returns: 
        Unpacked temperature at coordinates in band
    """
    single_band = raster_file.GetRasterBand(band)
    geotrans_raster = raster_file.GetGeoTransform()
    x = int((coordinates[0] - geotrans_raster[0])/geotrans_raster[1])
    y = int((coordinates[1] - geotrans_raster[3])/geotrans_raster[5])
    band_array = single_band.ReadAsArray()
    packed_temp = band_array[y, x]
    add_offset = single_band.GetOffset()
    scale_factor = single_band.GetScale()
    unpacked_temp = add_offset + (packed_temp * scale_factor)
    return unpacked_temp

def get_temps_list(stackIDs_list, file_name, coords):
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
        each_temp = get_temp_at_point(file_name, coords, current_stackID)
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

def create_temp_dataset(list_of_list, col_names, species_col, mass_col, year_col):
    """Turn list into usable Pandas dataframe with additional columns
    
    Args: 
        dataset: Temperature list of lists dataset
        col_names: Name of columns for original list
        
    
    Returns: 
        Pandas dataset with named columns and added columns
    """
    temp_dataset = pd.DataFrame(list_of_list, columns = col_names)
    temp_dataset_final = pd.concat([species_col, mass_col, year_col, temp_dataset], axis = 1)            
    return temp_dataset_final

def plot_linreg(dataset, first_variable, second_vari_list, plot_name):
    # FIXME: RuntimeWarning; didn't help to move location of close
    # TODO: Create single plot for each species containing lines for each past year
    # TODO: Remove each_combo if it's unnecessary
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
                est = smf.ols(formula = "mass ~ {}".format(each_variable), data = each_combo).fit()  
                plt.figure()
                plt.plot(each_combo.iloc[:,1], each_combo.iloc[:,0], "bo")
                plt.plot(each_combo.iloc[:,1], est.fittedvalues, "r-")
                plt.xlabel("Temperature from "+each_variable)
                plt.ylabel("Mass (g)")
                pp.savefig()
    pp.close()

def create_masstemp_plots (dataset, groupby_col_name, dep_var_name, col_names):
    """Set of plots for each species with each past year temps and masses
    
    Args: 
        dataset: Dataset containing all past years' temperatures for each individual
        groupby_col_name: Name of species column
        dep_var_name: Name of mass column
        col_names: Names of temperature columns
        
    Returns: 
        PDF for each species with mass-temp plots
    """
    data_by_species = dataset.groupby(groupby_col_name)
    for species, species_data in data_by_species: 
        species = species.replace(" ", "_")
        linreg_plots = plot_linreg(species_data, species_data[dep_var_name], col_names, species)
    return linreg_plots

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
            est = smf.ols(formula = "mass~" + each_variable, data = dataset).fit()
            r2 = est.rsquared
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
            est = smf.ols(formula = "mass~" + each_variable, data = dataset).fit()
            slope = est.params[1]
            slope_list.append(slope)
    return slope_list

def get_multiple_stat_lists(stat_fx, max_years, dataset, groupby_col_name, dep_var_name, col_names): 
    # FIXME: remove fourth row restriction, only applies to subset dataset
    """Dataset containing desired stat for each species and each past year
    
    Args: 
        stat_fx: Desired statistic's function
        max_years: Maximum possible number of past years with temp data
        dataset: Dataset containing all past years' temperatures for each individual
        groupby_col_name: Name of species column
        dep_var_name: Name of mass column
        col_names: Names of temperature columns
        
    Returns: 
        Stats dataset
    """
    all_stat = pd.DataFrame(range(max_years))
    species_list = []
    all_stat.columns = ["past_year"]
    data_by_species = dataset.groupby(groupby_col_name)
    for species, species_data in data_by_species:
        species = species.replace(" ", "_")
        species_list.append(species)
        stat_species = stat_fx(species_data, species_data[dep_var_name], col_names)
        stat_species = pd.DataFrame(stat_species)
        stat_species.columns = [species]
        all_stat[species] = stat_species
    return species_list, all_stat

def create_stats_fig(fig_name, sp_list, r2_list, slope_list, ind_var_name):
    """Plot of past year and stats (r2 & slope) for each species
    
    Args: 
        fig_name: Desired name of final PDF
        sp_list: List of species names
        r2_list: Dataset containing r2 values for all species
        slope_list: Dataset containing slope values for all species
        ind_var_name: Name of independent variable (i.e., past year)
        
    Returns: 
        PDF with stats plot for each species
    """
    pp = PdfPages(fig_name)
    for each_species in sp_list: 
        species_r2 = r2_list[[col for col in r2_list.columns if col == each_species]]
        species_slope = slope_list[[col for col in slope_list.columns if col == each_species]]
        plt.figure()
        plt.plot(r2_list[ind_var_name], species_r2, color = "purple", marker = "o", linestyle = "None")
        plt.axhline(y = 1, color = "purple", linestyle = "--", linewidth = 3)
        plt.plot(slope_list[ind_var_name], species_slope, color = "yellow", marker = "o", linestyle = "None")
        plt.axhline(y = 0, color = "yellow", linestyle = "--", linewidth = 3)
        plt.xlabel("Past Year")
        plt.ylabel("R^2")
        plt.title(each_species)
        pp.savefig()
    pp.close()


gdal.AllRegister()
driver = gdal.GetDriverByName("netCDF")
temp_file = "air.mon.mean.v301.nc"

# List of months with corresponding stackID codes
month_codes = create_month_codes_dict(22799, 22787, -1)

# Get all July stackID values for each individual in subset dataset
stackIDs_july_subset = [get_stackIDs(year, month_codes["July"]) for year in individual_data["year"]]

# Get all July temperatures for each individual in subset dataset
open_temp_file = gdal.Open(temp_file)
temps_july_subset = get_multiple_temps_lists(stackIDs_july_subset, open_temp_file, 
                    individual_data["lon"], individual_data["lat"])
open_temp_file = None

# Create past year names list
max_past_years = individual_data["year"].max() - 1899
past_year_names = ["past_year_{}" .format(year) for year in range(max_past_years)]

# Create final temperature dataset
final_temps_july_subset = create_temp_dataset(temps_july_subset, past_year_names, 
                        individual_data["genus_species"], individual_data["mass"], 
                        individual_data["year"])

# Dataset of individuals with missing temp data (i.e., ~3276.7) to check
# FIXME: remove when no longer useful
removed_individuals = final_temps_july_subset[(final_temps_july_subset["past_year_0"] 
                        > 3276) & (final_temps_july_subset["past_year_0"] < 3277)]

# Remove individuals with missing temp data (i.e., ~3276.7) in current year temp
final_temps_july_subset = final_temps_july_subset[(final_temps_july_subset["past_year_0"] 
                        < 3276) | (final_temps_july_subset["past_year_0"] > 3277)]

# Individual mass-temp plots for each past year for each species
create_masstemp_plots(final_temps_july_subset, "genus_species", "mass", 
                      past_year_names)

# Generate r2 values for each species and past year
species_list, final_r2 = get_multiple_stat_lists(get_r2_list, max_past_years, 
                        final_temps_july_subset, "genus_species", "mass", 
                        past_year_names)

# Generate slope values for each species and past year
species_list, final_slope = get_multiple_stat_lists(get_slope_list, max_past_years, 
                            final_temps_july_subset, "genus_species", 
                            "mass", past_year_names)

# Create PDF containing fig for each species of past year and r2 value/slope
create_stats_fig("all_stats_fig.pdf", species_list, final_r2, final_slope, "past_year")


# DATA RESTRUCTURE
# TODO: Incorporate all previous code using new dataset

def duplicate_rows(dataset, formula): 
    """Duplicate each row of dataset using number in created column
    
    Args: 
        dataset: Pandas dataframe to be duplicated
        formula: Used to create column that specifies number of duplicates
    
    Returns: 
        Dataframe with rows duplicated specified number of times
    """
    dataset["number_duplicates"] = formula
    duplicates_dataset = dataset.loc[np.repeat(dataset.index.values, dataset["number_duplicates"])]
    return duplicates_dataset

# Create iterative column based on number of row duplicates

def create_lag_column(dataset): 
    """Add column that starts at zero and adds one for each set of duplicates
    
    Args: 
        dataset: Pandas dataframe to add column to
    
    Returns: 
        Dataframe with new lag column
    """
    lag_dataset = pd.DataFrame()
    grouped_by_duplicate = dataset.groupby(level = 0)
    for duplicate, duplicate_data in grouped_by_duplicate: 
        duplicate_data["lag"] = np.asarray(range(len(duplicate_data)))
        lag_dataset = lag_dataset.append(duplicate_data)
    return lag_dataset

# Datasets
import pandas as pd
import numpy as np

# Create subset of 4 individuals to work with
individual_data = pd.read_csv("CompleteDatasetUS.csv")
subset = individual_data.iloc[0:4]

# Duplicate individual rows based on number of years between 1900 and collection year
duplicates_subset = duplicate_rows(subset, subset["year"] - 1899)

# Create year lag column for each individual
lag_subset = create_lag_column(duplicates_subset)   

# Add year for temperature lookup
lag_subset["temp_year"] = lag_subset["year"] - lag_subset["lag"]
