#!/bin/sh
#----------------------------------------------------------------------------------------
# Script para obtener reportes historicos PIC. CC_TOT_15M
# Ejecuta reporte para el dia de ayer
# Ejecucion: ./CC_TOT_15M.sh ConexionBD     (Formato ConexionBD: usr/pass@DB)
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
#varFechaArchivo=`date --date="1 days ago" +%Y%m%d` #--Fecha de ayer formateada para nombre de archivo.
if [ -z "$1" ]; then 
	varFechaReporte=$(date --date="1 days ago" +%d-%m-%Y) 	#--Fecha de ayer formateada para condicion SQL.
	varFechaArchivo=$(date --date="1 days ago" +%Y%m%d)   	#--Fecha de ayer formateada para nombre de archivo.
else
	varFechaReporte=$(date --date=$1 +%d-%m-%Y)			  	#--Fecha de ayer formateada para condicion SQL.
	varFechaArchivo=$(date --date=$1 +%Y%m%d)   			#--Fecha de ayer formateada para nombre de archivo.
fi
varHoraArchivo=`date -d now +%H%M` #--Hora formateada para nombre de archivo TXT.
varArchivoOut="CC_TOT_15M_$varFechaArchivo.txt" #--CC_TOT_15M_YYYYMMDD.txt
	#---------------------------------------
	# Hardcode para test
	#varFechaReporte="28-05-2018"
	#varFechaArchivo="20180528"
	#varArchivoOut="CC_TOT_15M_20180528_$varHoraArchivo.txt"
	#----------------------------------------
cd /opt/genesys/InterfacesReportesPIC
sqlplus -s $varConexionSQL <<EOF > /dev/null
set feedback on verify on heading off colsep '|' termout off ECHO on TRIMOUT on TRIMSPOOL on LINESIZE 32767 WRAP off PAGESIZE 0
SET SPOOL ON
SPOOL $varArchivoOut
SELECT 
  --cal_date fecha,
  to_char(cal_date, 'dd/mm/yyyy HH24:MI') fecha,
  interaction_type,
  res_vq.RESOURCE_NAME VQ,
  grogvq.group_name GVQ,
  udc1.DIM_ATTRIBUTE_1 Tabulacion1,
  udc1.DIM_ATTRIBUTE_2 Tabulacion2,
  udc1.DIM_ATTRIBUTE_3 Tabulacion3,
  udc1.DIM_ATTRIBUTE_4 Tabulacion4,
  udc2.DIM_ATTRIBUTE_4 Agrupador1,
  udc2.DIM_ATTRIBUTE_5 Agrupador2,
 sum(case when udc1.DIM_ATTRIBUTE_1 is not null
            then 1
            else 0
      end ) "N_TABULACION1",
 sum(case when udc1.DIM_ATTRIBUTE_2 is not null
            then 1
            else 0
      end) "N_TABULACION2",
  sum(case when udc1.DIM_ATTRIBUTE_3 is not null
            then 1
            else 0
      end ) "N_TABULACION3",
 sum(case when udc1.DIM_ATTRIBUTE_4 is not null
            then 1
            else 0
      end) "N_TABULACION4",
 sum(case when udc2.DIM_ATTRIBUTE_4 is not null
            then 1
            else 0
      end ) "N_AGRUPACION1",
 sum(case when udc2.DIM_ATTRIBUTE_5 is not null
            then 1
            else 0
      end) "N_AGRUPACION2"                     
FROM a001441.INTERACTION_RESOURCE_FACT irf 
INNER JOIN 
    a001441.MEDIA_TYPE mt 
ON 
    Mt.MEDIA_TYPE_KEY=irf.MEDIA_TYPE_KEY
INNER JOIN 
    a001441.INTERACTION_TYPE ity
ON 
    ity.INTERACTION_TYPE_KEY=irf.INTERACTION_TYPE_KEY
INNER JOIN 
    a001441.INTERACTION_FACT ifa 
ON 
     irf.INTERACTION_ID=ifa.INTERACTION_ID
INNER JOIN 
    a001441.routing_target rta
ON 
        rta.routing_target_KEY=irf.routing_target_KEY
INNER JOIN 
    a001441.RESOURCE_ res_vq 
ON 
    res_vq.RESOURCE_KEY=irf.LAST_VQUEUE_RESOURCE_KEY
INNER JOIN 
    a001441.RESOURCE_GI2 
ON 
    (irf.RESOURCE_KEY=RESOURCE_GI2.RESOURCE_KEY)
INNER JOIN 
    a001441.RESOURCE_  resirf 
ON 
   (resirf.RESOURCE_KEY=irf.RESOURCE_KEY)
INNER JOIN 
    a001441.TECHNICAL_DESCRIPTOR tde_ag
ON 
   (tde_ag.TECHNICAL_DESCRIPTOR_KEY=irf.TECHNICAL_DESCRIPTOR_KEY)
INNER JOIN 
    a001441.RESOURCE_STATE rst
ON 
    (rst.RESOURCE_STATE_KEY=irf.RES_PREVIOUS_SM_STATE_KEY)
INNER JOIN 
    a001441.IRF_USER_DATA_GEN_1 
    ON 
        (irf.INTERACTION_RESOURCE_ID=IRF_USER_DATA_GEN_1.INTERACTION_RESOURCE_ID and irf.START_DATE_TIME_KEY=IRF_USER_DATA_GEN_1.START_DATE_TIME_KEY)
INNER JOIN 
    a001441.IRF_USER_DATA_KEYS 
    ON 
        (IRF_USER_DATA_KEYS.INTERACTION_RESOURCE_ID=irf.INTERACTION_RESOURCE_ID and IRF_USER_DATA_KEYS.START_DATE_TIME_KEY=irf.START_DATE_TIME_KEY)
INNER JOIN 
    a001441.INTERACTION_DESCRIPTOR_GI2 
    ON 
        (INTERACTION_DESCRIPTOR_GI2.INTERACTION_DESCRIPTOR_KEY=IRF_USER_DATA_KEYS.INTERACTION_DESCRIPTOR_KEY)
inner join 
    a001441.date_time dt 
    on 
        DT.DATE_TIME_KEY = irf.START_DATE_TIME_KEY
left join
    a001441.mediation_segment_fact msf
on
     MSF.MEDIATION_SEGMENT_ID = IRF.MEDIATION_SEGMENT_ID 
left JOIN 
    a001441.TECHNICAL_DESCRIPTOR tde_vq
ON 
   (tde_vq.TECHNICAL_DESCRIPTOR_KEY=msf.TECHNICAL_DESCRIPTOR_KEY)
 --Custom Attached Data  Low Cardinality 1
left join
    a001441.IRF_USER_DATA_KEYS iuk
on
    irf.interaction_resource_id = iuk.INTERACTION_RESOURCE_ID
left join
    a001441.USER_DATA_CUST_DIM_1 udc1
on 
    iuk.CUSTOM_KEY_1 = udc1.ID
-- Custom Attached Data Low Cardinality 2
left join
    a001441.USER_DATA_CUST_DIM_2 udc2
on 
    iuk.CUSTOM_KEY_2 = udc2.ID
-- Custom Attached Data Hgh Cardinality 1
left join 
 a001441.IRF_USER_DATA_CUST_1 iud1
on
 irf.interaction_resource_id = iud1.INTERACTION_RESOURCE_ID   
inner join
    a001441.resource_group_combination   rgc_vq  
on
    RGC_vq.GROUP_COMBINATION_KEY = msf.RESOURCE_GROUP_COMBINATION_KEY
inner join
    a001441.group_ grogvq     
on 
    grogvq.group_key = rgc_vq.group_key    
where to_date(to_char(cal_date, 'dd-mm-yyyy'), 'dd-mm-yyyy') between to_date('$varFechaReporte', 'dd-mm-yyyy') and to_date('$varFechaReporte', 'dd-mm-yyyy')
and   TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) and TDE_VQ.TECHNICAL_RESULT = 'Diverted'
and   TDE_VQ.RESULT_REASON = 'AnsweredByAgent'
and   RES_VQ.RESOURCE_NAME!= 'NONE'
and media_name = 'Voice'   
group by cal_date,
         interaction_type, 
         res_vq.RESOURCE_NAME,
         grogvq.group_name,
         udc1.DIM_ATTRIBUTE_1,
         udc1.DIM_ATTRIBUTE_2,
         udc1.DIM_ATTRIBUTE_3,
         udc1.DIM_ATTRIBUTE_4,
         udc2.DIM_ATTRIBUTE_4,
         udc2.DIM_ATTRIBUTE_5
order by cal_date,interaction_type, n_tabulacion1 desc, n_tabulacion2 desc, n_tabulacion3 desc ,n_tabulacion4 desc  
;
EOF
sed -i "s/ \+|/|/g;s/| \+/|/g;s/^\s*//;s/[ \t]*$//" $varArchivoOut