#!/bin/bash

#----------------------------------------------------------------------------------------
# Help -h --h -help --help
if test "$1" = "-h" -o "$1" = "--h" -o "$1" = "-help" -o "$1" = "--help" ; then
	echo "Ejecute: ./InterfacesReportesPIC.sh sin parámetros	para ejecutar los reportes correspondiente a la fecha de ayer."; 
	echo "Ejecute: ./InterfacesReportesPIC.sh mm/dd/yyyy		para ejecutar los reportes correspondiente a la fecha indicada."; 
	echo "Ejecute: ./[scriptname].sh \$(date +%m/%d/%Y)			para ejecutar reportes correspondientes al día de hoy."; 
	exit
fi
#----------------------------------------------------------------------------------------

export ORACLE_HOME=/u00/app/oracle/product/12.2.0/DB
export PATH=$PATH:/u00/app/oracle/product/12.2.0/DB/bin
export LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib:/opt/CA/SharedComponents/lib

cd /opt/genesys/InterfacesReportesPIC

echo "ejecutando AB_TOT_15M..." 
./AB_TOT_15M.sh $1

echo "ejecutando AB_TOT_DIA..." 
./AB_TOT_DIA.sh $1

echo "ejecutando CallByCall..."
./CallByCall.sh $1

echo "ejecutando CC_TOT_15M..."
./CC_TOT_15M.sh $1

echo "ejecutando CC_TOT_DIA..."
./CC_TOT_DIA.sh $1

echo "ejecutando HIST_SK_AG..."
./HIST_SK_AG.sh $1

echo "ejecutando LL_EST_REASON_DIA..."
./LL_EST_REASON_DIA.sh $1

echo "ejecutando LL_EST_REASON_15M..."
./LL_EST_REASON_15M.sh $1

echo "ejecutando LL_EST_REASON_DET..."
./LL_EST_REASON_DET.sh $1

echo "ejecutando VAG_TOT_15M..."
./VAG_TOT_15M.sh $1

echo "ejecutando VAG_TOT_DIA..."
./VAG_TOT_DIA.sh $1

echo "ejecutando VQ_TOT_15M..."
./VQ_TOT_15M.sh $1

echo "ejecutando VQ_TOT_DIA..."
./VQ_TOT_DIA.sh $1


#for file in *.txt; do zip "$file".zip "$file"; done
#zip `date --date="1 days ago" +%Y%m%d`.zip *.txt
#rm *.txt
