## 

dat = read.csv('./ExampleDataNMNH.csv')

str(dat)
dim(dat)

names(dat)

dat$Measurements = as.character(dat$Measurements)

?sub
?substr
?grep
tst = grep('[0-9]g', dat$Measurements)
dat$Measurements[tst][1:5]

