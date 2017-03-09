mkdir data
R CMD BATCH Cleaning_VN.R
mkdir results
python Analysis_VN_CY.py

#depends on having TL data
#R CMD BATCH Visualization_VN_CY.R
