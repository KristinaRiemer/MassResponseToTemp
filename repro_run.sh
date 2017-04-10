#run entire project pipeline

#download and clean data
#time: 
mkdir data
R CMD BATCH Cleaning_VN.R

#subset data to test
head -n 501 CompleteDatasetVN.csv > CompleteDatasetVN_temporary.csv
rm CompleteDatasetVN.csv
mv CompleteDatasetVN_temporary.csv CompleteDatasetVN.csv

#species relationships for past temperatures
#time: ~42 hours
mkdir results_TL
python Analysis_VN_TL.py

#species relationships for current temperature
#time: ~30 minutes
mkdir results
python Analysis_VN_CY.py

#current temperature relationship viz
mkdir figures
R CMD BATCH Visualization_VN_CY.R

#past temperatures relationship viz
R CMD BATCH Visualization_VN_CY_supp.R
