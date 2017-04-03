#run entire project pipeline

#download and clean data
mkdir data
R CMD BATCH Cleaning_VN.R

#species relationships for past temperatures
#time: ~42 hours
mkdir results_TL
python Analysis_VN_TL.py

#species relationships for current temperature
mkdir results
python Analysis_VN_CY.py

#current temperature relationship viz
mkdir figures
R CMD BATCH Visualization_VN_CY.R

#past temperatures relationship viz
R CMD BATCH Visualization_VN_CY_supp.R
