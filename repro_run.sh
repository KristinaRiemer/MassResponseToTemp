#run entire project pipeline

#download and clean data
#time:
mkdir -p data
retriever update
Rscript Cleaning_VN.R

#subset data to test

if [ "$1" != "all" ]
then
  echo "Running the example analysis on 500 amphibians..."
  echo "If you want to run the full analysis use: bash repro_run.sh all"
  head -n 501 CompleteDatasetVN.csv > CompleteDatasetVN_temporary.csv
  rm CompleteDatasetVN.csv
  mv CompleteDatasetVN_temporary.csv CompleteDatasetVN.csv
fi

#species relationships for past temperatures
#time: ~42 hours
mkdir -p results_TL
python Analysis_VN_TL.py

#species relationships for current temperature
#time: ~30 minutes
mkdir -p results
python Analysis_VN_CY.py

#current temperature relationship viz
mkdir -p figures
Rscript Visualization_VN_CY.R

#past temperatures relationship viz
Rscript Visualization_VN_CY_supp.R
