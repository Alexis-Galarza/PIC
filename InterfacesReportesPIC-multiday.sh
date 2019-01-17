#!/bin/bash

cd /opt/genesys/InterfacesReportesPIC
 

./InterfacesReportesPIC.sh 09/02/2018
./InterfacesReportesPIC.sh 09/03/2018
./InterfacesReportesPIC.sh 09/04/2018
./InterfacesReportesPIC.sh 09/05/2018
./InterfacesReportesPIC.sh 09/06/2018

#for file in *.txt; do zip "$file".zip "$file"; done
#zip `date --date="1 days ago" +%Y%m%d`.zip *.txt
#rm *.txt
