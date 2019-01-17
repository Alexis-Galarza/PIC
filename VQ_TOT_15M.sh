#!/bin/sh
#----------------------------------------------------------------------------------------
# Script para obtener reportes historicos PIC. VQ_TOT_15M
# Ejecuta reporte para el dia de ayer
# Ejecucion: ./VQ_TOT_15M.sh ConexionBD     (Formato ConexionBD: usr/pass@DB)
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
varArchivoOut="VQ_TOT_15M_$varFechaArchivo.txt" #--VQ_TOT_15M_YYYYMMDD.txt
	#---------------------------------------
	# Hardcode para test
	#varFechaReporte="08-05-2018"
	#varFechaArchivo="20180508"
	#varArchivoOut="VQ_TOT_15M_20180508.txt"
	#----------------------------------------
cd /opt/genesys/InterfacesReportesPIC
sqlplus -s $varConexionSQL <<EOF > /dev/null
set feedback on verify on heading off colsep '|' termout off ECHO on TRIMOUT on TRIMSPOOL on LINESIZE 32767 WRAP off PAGESIZE 0
SET SPOOL ON
SPOOL $varArchivoOut
select 
       resource_name VQ,
       group_name GVQ, 
       --cal_date Fecha,
	   to_char(cal_date, 'dd/mm/yyyy HH24:MI') Fecha,
       media_name,
       interaction_type,
       sum(queu.ENTERED) Q_Ingresadas,
       sum(queu.ACCEPTED) Q_Atendidas,
       sum(queu.ABANDONED) Q_Abandon_Cola,
       sum(queu.ACCEPTED_TIME) Q_T_Contestar,
       sum(queu.ABANDONED_TIME) Q_T_Abandon_Cola,
       sum(QUEU.ABANDONED_INVITE) Q_Abandon_Ring,
       sum(nvl(qacc.ACCEPTED_AGENT_STI_1,0)) Q_ATN_1_9,
       sum(nvl(qacc.ACCEPTED_AGENT_STI_2,0)) Q_ATN_10_19,
       sum(nvl(qacc.ACCEPTED_AGENT_STI_3,0)) Q_ATN_20_29,
       sum(nvl(qacc.ACCEPTED_AGENT_STI_4,0)) Q_ATN_30_39,
       sum(nvl(qacc.ACCEPTED_AGENT_STI_5,0)) Q_ATN_40_49,
       sum(nvl(qacc.ACCEPTED_AGENT_STI_6,0)) Q_ATN_50_59,
       sum(nvl(qacc.ACCEPTED_AGENT_STI_7,0)) Q_ATN_60_89,
       sum(nvl(qacc.ACCEPTED_AGENT_STI_8,0)) Q_ATN_90_119,
       sum(nvl(qacc.ACCEPTED_AGENT_STI_9,0)) Q_ATN_120_mas,
       sum(nvl(qabn.ABANDONED_STI_1,0)) Q_ABN_1_9,
       sum(nvl(qabn.ABANDONED_STI_2,0)) Q_ABN_10_19,  
       sum(nvl(qabn.ABANDONED_STI_3,0)) Q_ABN_20_29,
       sum(nvl(qabn.ABANDONED_STI_4,0)) Q_ABN_30_39,
       sum(nvl(qabn.ABANDONED_STI_5,0)) Q_ABN_40_49,
       sum(nvl(qabn.ABANDONED_STI_6,0)) Q_ABN_50_59,
       sum(nvl(qabn.ABANDONED_STI_7,0)) Q_ABN_60_89,
       sum(nvl(qabn.ABANDONED_STI_8,0)) Q_ABN_90_119,
       sum(nvl(qabn.ABANDONED_STI_9,0)) Q_ABN_120_mas,
       sum(QUEU.ENGAGE_TIME) T_Talk,
       sum(QUEU.HOLD_TIME) T_Hold,
       sum(QUEU.INVITE_TIME) T_Ring,
       sum(QUEU.WRAP_TIME) WRAP_TIME
from a001441.AGT_QUEUE_subhr queu
inner join
    a001441.date_time dt
on 
    queu.DATE_TIME_KEY = DT.DATE_TIME_KEY
inner join
    a001441.interaction_type ity
on
    ity.interaction_type_key = queu.interaction_type_key
inner join
    a001441.media_type mty
on
    mty.media_type_key = queu.media_type_key
inner join
    a001441.resource_ resvq
on
    RESvq.RESOURCE_KEY = queu.RESOURCE_KEY
inner join
    a001441.resource_group_fact rgf    
on
    RGF.RESOURCE_KEY = RESVQ.RESOURCE_KEY    
inner join
    a001441.group_ gro
on
    GRO.GROUP_KEY = Rgf.GROUP_KEY and DT.DATE_TIME_KEY between RGF.START_DATE_TIME_KEY and RGF.end_DATE_TIME_KEY   
left join
    a001441.AGT_QUEUE_acc_agent_day qacc
on
   qacc.RESOURCE_KEY = resvq.RESOURCE_KEY and qacc.DATE_TIME_KEY = dt.DATE_TIME_KEY and QUEU.INTERACTION_TYPE_KEY = QACC.INTERACTION_TYPE_KEY and QUEU.INTERACTION_DESCRIPTOR_KEY = QACC.INTERACTION_DESCRIPTOR_KEY
left join
    a001441.AGT_QUEUE_abn_day qabn
on
   qabn.RESOURCE_KEY = resvq.RESOURCE_KEY and qabn.DATE_TIME_KEY = dt.DATE_TIME_KEY and QUEU.INTERACTION_TYPE_KEY = QAbn.INTERACTION_TYPE_KEY and QUEU.INTERACTION_DESCRIPTOR_KEY = QABN.INTERACTION_DESCRIPTOR_KEY      
where to_date(to_char(cal_date, 'dd-mm-yyyy'), 'dd-mm-yyyy') = to_date('$varFechaReporte', 'dd-mm-yyyy')
group by resource_name,
         group_name,
         cal_date,
         media_name,
         interaction_type 
order by cal_date,resource_name,interaction_type  
;
EOF
sed -i "s/ \+|/|/g;s/| \+/|/g;s/^\s*//;s/[ \t]*$//" $varArchivoOut