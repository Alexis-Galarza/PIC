#!/bin/sh
#----------------------------------------------------------------------------------------
# Script para obtener reportes historicos PIC. VAG_TOT_15M
# Ejecuta reporte para el dia de ayer
# Ejecucion: ./VAG_TOT_15M.sh ConexionBD     (Formato ConexionBD: usr/pass@DB)
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
varArchivoOut="VAG_TOT_15M_$varFechaArchivo.txt" #--VAG_TOT_15M_YYYYMMDD.txt
	#---------------------------------------
	# Hardcode para test
	#varFechaReporte="10-05-2018"
	#varFechaArchivo="20180508"
	#varArchivoOut="VAG_TOT_15M_20180508.txt"
	#----------------------------------------
cd /opt/genesys/InterfacesReportesPIC
sqlplus -s $varConexionSQL <<EOF > /dev/null
set feedback on verify on heading off colsep '|' termout off ECHO on TRIMOUT on TRIMSPOOL on LINESIZE 32767 WRAP off PAGESIZE 0
SET SPOOL ON
SPOOL $varArchivoOut
select 
		--cal_date Fecha,
		to_char(cal_date, 'dd/mm/yyyy HH24:MI') Fecha,
       resource_name Agente,
       group_name VAG,
       ity.interaction_type,
       mty.media_name,
       AGT.INVITE N_Ring_Dial,
       AGT.ACCEPTED Q_Contestadas,
       nvl(AGT.CONVERSACION_1_9,0) Conversacion_1_9,
       nvl(AGT.CONVERSACION_10_19,0) Conversacion_10_19,
       nvl(AGT.CONVERSACION_20_29,0)Conversacion_20_29,
       AGT.ENGAGE_TIME T_Conversacion,
       AGT.HOLD_TIME T_Hold,
       AGT.INVITE_TIME T_Ring_Dial,
       AGT.WRAP_TIME T_ACW,
       nvl(AGT.ABANDONADAS_HOLD,0) ABANDONADAS_HOLD,
       AGT.TRANSFER_INIT_AGENT N_Transferidas
from a001441.agt_agent_subhr agt 
inner join
    a001441.date_time dt
on 
    DT.DATE_TIME_KEY = AGT.DATE_TIME_KEY
inner join
    a001441.resource_ res
on
    RES.RESOURCE_KEY = agt.RESOURCE_KEY    
inner join
    a001441.resource_group_fact rgf    
on
    RGF.RESOURCE_KEY = RES.RESOURCE_KEY    
inner join
    a001441.group_ gro
on
    GRO.GROUP_KEY = Rgf.GROUP_KEY and DT.DATE_TIME_KEY between RGF.START_DATE_TIME_KEY and RGF.end_DATE_TIME_KEY
inner join
    a001441.interaction_type ity
on
    ITY.INTERACTION_TYPE_KEY = agt.interaction_type_key    
inner join
    a001441.media_type mty
on
    MTY.MEDIA_TYPE_KEY = AGT.MEDIA_TYPE_KEY    
where to_date(to_char(cal_date, 'dd-mm-yyyy'), 'dd-mm-yyyy') between to_date('$varFechaReporte', 'dd-mm-yyyy') and to_date('$varFechaReporte', 'dd-mm-yyyy')
and group_name like 'VAG_R%_Q%'
and media_name = 'Voice'
order by Resource_name,vag, Interaction_type, cal_date  
;
EOF
sed -i "s/ \+|/|/g;s/| \+/|/g;s/^\s*//;s/[ \t]*$//" $varArchivoOut