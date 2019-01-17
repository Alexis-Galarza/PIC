#!/bin/sh
#----------------------------------------------------------------------------------------
# Script para obtener reportes historicos PIC. LL_EST_REASON
# Ejecuta reporte para el dia de ayer
# Ejecucion: ./LL_EST_REASON.sh ConexionBD     (Formato ConexionBD: usr/pass@DB)
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
varArchivoOut="LL_EST_REASON_DIA_$varFechaArchivo.txt" #--LL_EST_REASON_YYYYMMDD.txt
	#---------------------------------------
	# Hardcode para test
	#varFechaReporte="03-05-2018"
	#varFechaArchivo="20180503"
	#varArchivoOut="LL_EST_REASON_20180503.txt"
	#----------------------------------------
cd /opt/genesys/InterfacesReportesPIC
sqlplus -s $varConexionSQL <<EOF > /dev/null
set feedback on verify on heading off colsep '|' termout off ECHO on TRIMOUT on TRIMSPOOL on LINESIZE 32767 WRAP off PAGESIZE 0
SET SPOOL ON
SPOOL $varArchivoOut
select  mtyest.media_name,
        --cal_date FECHA,
		to_char(cal_date,'DD/MM/YYYY')  FECHA,
        group_name VAG,
        resource_name agente, 
        ACTIVE_TIME,
        BUSY,
        BUSY_TIME,
        NOT_READY,
        NOT_READY_TIME,
        READY,
        READY_TIME,
        WRAP,
        WRAP_TIME,
        nvl(state_type, 'NO State Type') state_type,
        nvl(state_name, 'NO State') state_name,
        nvl(REASON_TYPE, 'NO Reason Type') REASON_TYPE,
        nvl(HARDWARE_REASON,'NO Hardware Reason') HardwareReason,
        nvl(SOFTWARE_REASON_VALUE,'NO Software Reason') SoftwareReason,
        nvl(STATE_RSN,0) State_RSN,
        nvl(STATE_RSN_TIME,0) STATE_RSN_TIME
from  a001441.AGt_I_SESS_STATE_day ASSS
inner join
    a001441.date_time dt
on
    DT.DATE_TIME_KEY = asss.date_time_key
left join
    a001441.resource_ res_ag
on
    res_ag.resource_key = ASss.RESOURCE_KEY        
left join
    a001441.resource_group_fact rgf
on
    RGF.RESOURCE_KEY = res_ag.resource_key
left join
    a001441.group_ gro
on
   GRO.GROUP_KEY = rgf.group_key  and asss.date_time_key between rgf.start_ts and rgf.end_ts
left join
    a001441.media_type mtyest
on
    MTYEST.MEDIA_TYPE_KEY = ASSS.MEDIA_TYPE_KEY           
left join
    a001441.agt_i_state_rsn_day b
on            
    asss.date_time_key = b.date_time_key and asss.resource_key = b.resource_key
left join 
  a001441.resource_state rs
on
    RS.RESOURCE_STATE_KEY = b.RESOURCE_STATE_KEY
left join
    a001441.resource_state_reason srs
on
    SRS.RESOURCE_STATE_REASON_KEY = b.RESOURCE_STATE_REASON_KEY
left join
    a001441.media_type mtyraz
on
    MTYraz.MEDIA_TYPE_KEY = b.MEDIA_TYPE_KEY
where to_date(to_char(cal_date, 'dd/mm/yyyy'), 'dd/mm/yyyy') between to_date('$varFechaReporte', 'dd/mm/yyyy') and to_date('$varFechaReporte', 'dd/mm/yyyy')   
and group_name like 'VAG_R%_Q%'
order by resource_name,cal_date   
;
EOF
sed -i "s/ \+|/|/g;s/| \+/|/g;s/^\s*//;s/[ \t]*$//" $varArchivoOut