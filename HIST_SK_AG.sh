#!/bin/sh
#----------------------------------------------------------------------------------------
# Script para obtener reportes historicos PIC. HIST_SK_AG
# Ejecuta reporte para el dia de ayer
# Ejecucion: ./HIST_SK_AG.sh ConexionBD     (Formato ConexionBD: usr/pass@DB)
#----------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------
# Help -h --h -help --help
if test "$1" = "-h" -o "$1" = "--h" -o "$1" = "-help" -o "$1" = "--help" ; then
	echo "Ejecute: ./[scriptname].sh sin parámetros    para ejecutar el reporte correspondiente a la fecha de ayer."; 
	echo "Ejecute: ./[scriptname].sh mm/dd/yyyy        para ejecutar el reporte correspondiente a la fecha indicada."; 
	echo "Ejecute: ./[scriptname].sh \$(date +%m/%d/%Y)        para ejecutar reportes correspondientes al día de hoy."; 
	exit
fi
#----------------------------------------------------------------------------------------

source /opt/genesys/InterfacesReportesPIC/setenv.sh

#varConexionSQL="$1"  #--segundo parametro. Conexion BD. Formato usr/pass@DB
varConexionSQL=`/Seguridad/tpcryptcl -s -g pic pgim -n`/`/Seguridad/tpcryptcl -s -g pic pgim -p`@PGIM

#varFechaReporte=`date --date="1 days ago" +%d-%m-%Y` #--Fecha de ayer formateada para condicion SQL.
#varFechaArchivo=`date --date="1 days ago" +%Y%m%d` #--Fecha de ayer formateada para condicion SQL.
if [ -z "$1" ]; then 
	varFechaReporte=$(date --date="1 days ago" +%d-%m-%Y) 	#--Fecha de ayer formateada para condicion SQL.
	varFechaArchivo=$(date --date="1 days ago" +%Y%m%d)   	#--Fecha de ayer formateada para nombre de archivo.
else
	varFechaReporte=$(date --date=$1 +%d-%m-%Y)			  	#--Fecha de ayer formateada para condicion SQL.
	varFechaArchivo=$(date --date=$1 +%Y%m%d)   			#--Fecha de ayer formateada para nombre de archivo.
fi
varHoraArchivo=`date -d now +%H%m` #--Hora formateada para nombre de archivo TXT.
varArchivoOut="HIST_SK_AG_$varFechaArchivo.txt" #--HIST_SK_AG_YYYYMMDD.txt
	#---------------------------------------
	# Hardcode para test
	#varFechaReporte="10-04-2018"
	#varFechaArchivo="20180410"
	#varArchivoOut="HIST_SK_AG_20180410.txt"
	#----------------------------------------
cd /opt/genesys/InterfacesReportesPIC
sqlplus -s $varConexionSQL <<EOF > /dev/null
set feedback on verify on heading off colsep '|' termout off ECHO on TRIMOUT on TRIMSPOOL on LINESIZE 32767 WRAP off PAGESIZE 0
SET SPOOL ON
SPOOL $varArchivoOut
select 
	   to_char(to_date('1970-01-01','YYYY-MM-DD') + (dt.date_time_day_key/86400)-3/24,'dd/mm/yyyy') Fecha,
       to_char(to_date('1970-01-01','YYYY-MM-DD') + (dt.date_time_key/86400)-3/24, 'dd/mm/yyyy HH24:MI') Intervalo,
        resource_name Agente,
        skill_name Skill,
        Skill_level Nivel,
        case when rsf.active_flag = 1
             then 'Activo'
             else 'No Activo'
        end Estado,
        to_char(to_date('1970-01-01','YYYY-MM-DD') + (rsf.start_ts/86400)-3/24, 'dd/mm/yyyy HH24:MI') Fecha_Inicio,
        to_char(to_date('1970-01-01','YYYY-MM-DD') + (rsf.end_ts/86400)-3/24, 'dd/mm/yyyy HH24:MI') Fecha_Fin
from a001441.resource_skill_fact_ rsf
inner join
    a001441.resource_ resag
on
    resag.resource_key = rsf.resource_key
inner join
    a001441.skill ski
on
    SKI.SKILL_KEY = rsf.skill_key
inner join
    a001441.date_time dt
on
    dt.date_time_key = RSF.START_DATE_TIME_KEY
where to_date(to_char(cal_date, 'dd-mm-yyyy'), 'dd-mm-yyyy') between to_date('$varFechaReporte', 'dd-mm-yyyy') and to_date('$varFechaReporte', 'dd-mm-yyyy')
order by resource_name,rsf.start_ts, rsf.end_ts
;
EOF
sed -i "s/ \+|/|/g;s/| \+/|/g;s/^\s*//;s/[ \t]*$//" $varArchivoOut
