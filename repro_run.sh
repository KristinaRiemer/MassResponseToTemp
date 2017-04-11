#run entire project pipeline

#download and clean data
#time: 
mkdir data
retriever ls
Rscript Cleaning_VN.R

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
Rscript Visualization_VN_CY.R

#past temperatures relationship viz
Rscript Visualization_VN_CY_supp.R
