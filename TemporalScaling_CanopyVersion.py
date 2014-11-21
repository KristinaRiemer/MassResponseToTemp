from __future__ import division

# Read in individual and species data
import pandas as pd
individual_data = pd.read_csv("FinalSpeciesDataset.csv")
species_data = pd. read_csv("FinalSpeciesList.csv")

# Read in temperature data
# http://www.esrl.noaa.gov/psd/data/gridded/data.UDel_AirT_Precip.html
from osgeo import gdal
from osgeo.gdalconst import *
gdal.AllRegister()
driver = gdal.GetDriverByName("netCDF")
temperature_data = gdal.Open("air.mon.mean.v301.nc")

# Useful GDAL commands
cols = temperature_data.RasterXSize
rows = temperature_data.RasterYSize
bands = temperature_data.RasterCount

band_example = temperature_data.GetRasterBand(283)
#data_example = band_example.ReadAsArray(1, 1)

data_example = band_example.ReadAsArray(0, 0, cols, rows)
value_example = data_example[-123.93, 40.71]



band = temperature_data.GetRasterBand(1)

print "Band Type =", gdal.GetDataTypeName(band.DataType)

minimum_value = band.GetMinimum()
maximum_value = band.GetMaximum()

if minimum is None or maximum is None: 
    (minimum, maximum) = band.ComputeRasterMinMax(1)
print "Min=%.3f, Max=%.3f" % (minimum,maximum)

#if band.GetOverviewCount() > 0: 
#    print "Band has ", band.GetOverviewCount(), "overviews."
#
#if not band.GetRasterColorTable() is None:
#    print "Band has a color table with ", \
#    band.GetRasterColorTable().GetCount(), " entries."


print 'Driver: ', temperature_data.GetDriver().ShortName,'/', temperature_data.GetDriver().LongName
print 'Size is ',temperature_data.RasterXSize,'x',temperature_data.RasterYSize, 'x',temperature_data.RasterCount
# print 'Projection is ',temperature_data.GetProjection()


