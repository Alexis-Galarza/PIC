#!/bin/sh
#----------------------------------------------------------------------------------------
# Script para obtener reportes historicos PIC. AB_TOT_DIA
# Ejecuta reporte para el dia de ayer
# Ejecucion: ./AB_TOT_DIA.sh ConexionBD     (Formato ConexionBD: usr/pass@DB)
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
varArchivoOut="AB_TOT_DIA_$varFechaArchivo.txt" #--AB_TOT_DIA_YYYYMMDD.txt
	#---------------------------------------
	# Hardcode para test
	#varFechaReporte="28-06-2018"
	#varFechaArchivo="20180410"
	#varArchivoOut="AB_TOT_DIA_20180410.txt"
	#----------------------------------------
cd /opt/genesys/InterfacesReportesPIC
sqlplus -s $varConexionSQL <<EOF > /dev/null
set feedback on verify on heading off colsep '|' termout off ECHO on TRIMOUT on TRIMSPOOL on LINESIZE 32767 WRAP off PAGESIZE 0
SET SPOOL ON
SPOOL $varArchivoOut
select 
       resag.resource_name Agente,
       resvq.resource_name VQ,
       group_name GVQ, 
       --cal_date Fecha,
	   to_char(cal_date,'DD/MM/YYYY')  Fecha,
       media_name,
       interaction_type,
       sum(AGQU.ABANDONED_INVITE ) ABN_RING,
       sum(nvl(AGQU.ABN_RING_1_9,0)) ABN_RING_1_9,
       sum(nvl(AGQU.ABN_RING_10_19,0)) ABN_RING_10_19,
       sum(nvl(AGQU.ABN_RING_20_29,0)) ABN_RING_20_29,
       sum(nvl(AGQU.ABN_RING_30_39,0)) ABN_RING_30_39,
       sum(nvl(AGQU.ABN_RING_40_49,0)) ABN_RING_40_49,
       sum(nvl(AGQU.ABN_RING_50_59,0)) ABN_RING_50_59,
       sum(nvl(AGQU.ABN_RING_60_89,0)) ABN_RING_60_89,
       sum(nvl(AGQU.ABN_RING_90_119,0)) ABN_RING_90_119,
       sum(nvl(AGQU.ABN_RING_120_mas,0)) ABN_RING_120_MAS
from   a001441.AGT_AGENT_QUEUE_day agqu
inner join
    a001441.date_time dt
on 
    agqu.DATE_TIME_KEY = DT.DATE_TIME_KEY
inner join
    a001441.interaction_type ity
on
    ity.interaction_type_key = agqu.interaction_type_key
inner join
   a001441.media_type mty
on
    mty.media_type_key = agqu.media_type_key
inner join
    a001441.resource_ resvq
on
     resvq.RESOURCE_KEY = AGQU.queue_RESOURCE_KEY and dt.DATE_TIME_KEY = agqu.DATE_TIME_KEY and agqu.INTERACTION_TYPE_KEY = agqu.INTERACTION_TYPE_KEY  and agqu.INTERACTION_DESCRIPTOR_KEY = AGQU.INTERACTION_DESCRIPTOR_KEY
inner join
    a001441.resource_ resag
on
    resag.resource_key = AGQU.AGENT_RESOURCE_KEY    
inner join
    a001441.resource_group_fact rgf    
on
    RGF.RESOURCE_KEY = RESVQ.RESOURCE_KEY    
inner join
    a001441.group_ gro
on
    GRO.GROUP_KEY = Rgf.GROUP_KEY and DT.DATE_TIME_KEY between RGF.START_DATE_TIME_KEY and RGF.end_DATE_TIME_KEY   
where to_date(to_char(cal_date, 'dd-mm-yyyy'), 'dd-mm-yyyy') = to_date('$varFechaReporte', 'dd-mm-yyyy')
and AGQU.ABANDONED_INVITE > 0
group by resag.resource_name,
         resvq.resource_name,
         group_name,
         cal_date,
         media_name,
         interaction_type 
order by cal_date,resag.resource_name,resvq.resource_name,interaction_type         
;
EOF
sed -i "s/ \+|/|/g;s/| \+/|/g;s/^\s*//;s/[ \t]*$//" $varArchivoOut