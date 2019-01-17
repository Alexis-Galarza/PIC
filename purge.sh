#!/bin/sh
#----------------------------------------------------------------------------------------
# Script para eliminar archivos antiguos de reportes historicos PIC.
# Elimina archivos que cumplan con las siguientes condiciones ( AND ): 
#     archivos *.gz o *.txt
#     en carpeta /opt/genesys/InterfacesReportesPIC/enviados
#     con fecha de modificacion mayor a 60 dias
# Ejecucion: ./purge.sh
#----------------------------------------------------------------------------------------

find /opt/genesys/InterfacesReportesPIC/enviados -maxdepth 1 -type f \( -name "*.gz" -or -name "*.txt" \) -mtime +60 -exec rm {} \;

