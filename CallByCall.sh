#!/bin/sh
#----------------------------------------------------------------------------------------
# Script para obtener reportes historicos PIC. CallByCall
# Ejecuta reporte para el dia de ayer
# Ejecucion: ./CallByCall.sh ConexionBD     (Formato ConexionBD: usr/pass@DB)
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
varArchivoOut="CallByCall_$varFechaArchivo.txt" #--CallByCall_YYYYMMDD.txt
	#---------------------------------------
	# Hardcode para test
	#varFechaReporte="28-05-2018"
	#varFechaArchivo="20180528"
	#varArchivoOut="CallByCall_20180528.txt"
	#----------------------------------------
cd /opt/genesys/InterfacesReportesPIC
sqlplus -s $varConexionSQL <<EOF > /dev/null
set feedback on verify on heading off colsep '|' termout off ECHO on TRIMOUT on TRIMSPOOL on LINESIZE 32767 WRAP off PAGESIZE 0
SET SPOOL ON
SPOOL $varArchivoOut
SELECT 
  irf.interaction_id,
  irf.INTERACTION_RESOURCE_ID,
  nvl(telf.target_address,-2)  telefono,
  IRF.MEDIATION_SEGMENT_ID,
  MT.MEDIA_NAME,
  ity.INTERACTION_TYPE,
  to_char(cal_date,'DD/MM/YYYY')  fecha,
  to_char(to_date('1970-01-01','YYYY-MM-DD') + (ifa.start_TS/86400)-3/24, 'DD/MM/YYYY HH24:MI:SS')  Fecha_Ini_Llamada,
  to_char(to_date('1970-01-01','YYYY-MM-DD') + (ifa.end_TS/86400)-3/24, 'DD/MM/YYYY HH24:MI:SS')  Fecha_Fin_Llamada,
  ifa.END_TS - ifa.START_TS as duration_Call,
  case when (ifa.END_TS - ifa.START_TS ) < 10
        then 1
        else 0
  end Llamada_Corta,      
  ifa.SOURCE_ADDRESS ANI,
  ifa.TARGET_ADDRESS DNIS,
  IRF.INTERACTION_RESOURCE_ORDINAL Res_ordinal,
  to_char(to_date('1970-01-01','YYYY-MM-DD') + (msf.start_TS/86400)-3/24, 'DD/MM/YYYY HH24:MI:SS') Fecha_Ingreso_VQ,
  to_char(to_date('1970-01-01','YYYY-MM-DD') + (msf.end_TS/86400)-3/24, 'DD/MM/YYYY HH24:MI:SS')  Fecha_Salida_VQ,
  msf.end_ts - msf.start_ts T_Duration_VQ,
  nvl(res_vq.RESOURCE_NAME,'none') VQ,
  IRF.MEDIATION_COUNT,
  TDE_VQ.RESOURCE_ROLE RESOURCEROLE_VQ,
  TDE_VQ.TECHNICAL_RESULT TECHNICALRESULT_VQ,
  TDE_VQ.RESULT_REASON RESULTREASON_VQ,
  nvl(grogvq.group_name, 'none') GVQ,
  to_char(to_date('1970-01-01','YYYY-MM-DD') + (irf.start_TS/86400)-3/24, 'DD/MM/YYYY HH24:MI:SS')  Fecha_Ingreso_AG,
  to_char(to_date('1970-01-01','YYYY-MM-DD') + (irf.end_TS/86400)-3/24, 'DD/MM/YYYY HH24:MI:SS')  Fecha_Salida_AG,
  irf.end_ts - irf.start_ts T_Duration_AG,
  nvl(GROVAG.GROUP_NAME,'none') VAG,
  resirf.RESOURCE_TYPE,
  nvl(resirf.agent_first_name,'none') Nombre,
  nvl(resirf.agent_last_name,'none') Apellido,
  pl.place_name,
  resirf.resource_name Agente_RP,
  rst.STATE_NAME,
  TDE_AG.RESOURCE_ROLE RESOURCEROLE_AG,
  TDE_AG.TECHNICAL_RESULT TECHNICALRESULT_AG,
  TDE_AG.RESULT_REASON RESULTREASON_AG,
  irf.ROUTING_POINT_DURATION,
    --  Contestadas en umbrales
  case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) and TDE_VQ.TECHNICAL_RESULT = 'Diverted' 
            and TDE_VQ.RESULT_REASON = 'AnsweredByAgent' and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  >= 0 and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  <= 10)) 
       then 1
       else 0
  end Contestada_1_9,
   case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) and TDE_VQ.TECHNICAL_RESULT = 'Diverted' 
            and TDE_VQ.RESULT_REASON = 'AnsweredByAgent' and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  >= 11 and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  <= 20)) 
       then 1
       else 0
  end Contestada_10_19,       
  case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) and TDE_VQ.TECHNICAL_RESULT = 'Diverted' 
            and TDE_VQ.RESULT_REASON = 'AnsweredByAgent' and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  >= 21 and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  <= 30)) 
       then 1
       else 0
  end Contestada_20_29,
  case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) and TDE_VQ.TECHNICAL_RESULT = 'Diverted' 
            and TDE_VQ.RESULT_REASON = 'AnsweredByAgent' and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  >= 31 and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  <= 40)) 
       then 1
       else 0
  end Contestada_30_39,
  case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) and TDE_VQ.TECHNICAL_RESULT = 'Diverted' 
            and TDE_VQ.RESULT_REASON = 'AnsweredByAgent' and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  >= 41 and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  <= 50)) 
       then 1
       else 0
  end Contestada_40_49,
  case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) and TDE_VQ.TECHNICAL_RESULT = 'Diverted' 
            and TDE_VQ.RESULT_REASON = 'AnsweredByAgent' and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  >= 51 and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  <= 60)) 
       then 1
       else 0
  end Contestada_50_59,
  case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) and TDE_VQ.TECHNICAL_RESULT = 'Diverted' 
            and TDE_VQ.RESULT_REASON = 'AnsweredByAgent' and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  >= 61 and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  <= 90)) 
       then 1
       else 0
  end Contestada_60_89,
  case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) and TDE_VQ.TECHNICAL_RESULT = 'Diverted' 
            and TDE_VQ.RESULT_REASON = 'AnsweredByAgent' and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  >= 91 and ((IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts))  <= 120)) 
       then 1
       else 0
  end Contestada_90_119,
  case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) and TDE_VQ.TECHNICAL_RESULT = 'Diverted' 
            and TDE_VQ.RESULT_REASON = 'AnsweredByAgent' and (IRF.CUSTOMER_RING_DURATION + (msf.end_ts - msf.start_ts) >= 121) 
       then 1
       else 0
  end Contestada_120_mas,
    --  Abandonadas en cola umbrales
  case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) 
            and ( TDE_VQ.RESULT_REASON = 'AbandonedWhileQueued')
            and msf.end_ts - msf.start_ts >=  0 and msf.end_ts - msf.start_ts <= 10 
       then 1
       else 0
  end Abandono_Q_1_9,
   case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) 
            and ( TDE_VQ.RESULT_REASON = 'AbandonedWhileQueued')
            and msf.end_ts - msf.start_ts >= 11 and msf.end_ts - msf.start_ts <= 20 
       then 1
       else 0
  end Abandono_Q_10_19,
   case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) 
            and ( TDE_VQ.RESULT_REASON = 'AbandonedWhileQueued')
            and msf.end_ts - msf.start_ts >= 21 and msf.end_ts - msf.start_ts <= 30 
       then 1
       else 0
  end Abandono_Q_20_29,
   case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) 
            and ( TDE_VQ.RESULT_REASON = 'AbandonedWhileQueued')
            and msf.end_ts - msf.start_ts >= 31 and msf.end_ts - msf.start_ts <= 40 
       then 1
       else 0
  end Abandono_Q_30_39,
   case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) 
            and ( TDE_VQ.RESULT_REASON = 'AbandonedWhileQueued')
            and msf.end_ts - msf.start_ts >= 41 and msf.end_ts - msf.start_ts <= 50 
       then 1
       else 0
  end Abandono_Q_40_49,
   case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) 
            and ( TDE_VQ.RESULT_REASON = 'AbandonedWhileQueued')
            and msf.end_ts - msf.start_ts >= 51 and msf.end_ts - msf.start_ts <= 60 
       then 1
       else 0
  end Abandono_Q_50_59,
   case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) 
            and ( TDE_VQ.RESULT_REASON = 'AbandonedWhileQueued')
            and msf.end_ts - msf.start_ts >= 61 and msf.end_ts - msf.start_ts <= 90 
       then 1
       else 0
  end Abandono_Q_60_89,
   case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) 
            and ( TDE_VQ.RESULT_REASON = 'AbandonedWhileQueued')
            and msf.end_ts - msf.start_ts >= 91 and msf.end_ts - msf.start_ts <= 120 
       then 1
       else 0
  end Abandono_Q_90_119,
   case when TDE_VQ.RESOURCE_ROLE in ('Received','ReceivedConsult' ) 
            and ( TDE_VQ.RESULT_REASON = 'AbandonedWhileQueued')
            and msf.end_ts - msf.start_ts >= 121 
       then 1
       else 0
  end Abandono_Q_120_Mas,
  -- Contadores de IRF
  irf.DIAL_COUNT,
  irf.DIAL_DURATION,
  irf.RING_COUNT,
  irf.RING_DURATION,
  irf.TALK_COUNT,
  irf.TALK_DURATION,
  irf.HOLD_COUNT,
  irf.HOLD_DURATION,
  irf.AFTER_CALL_WORK_COUNT,
  irf.AFTER_CALL_WORK_DURATION,
  irf.CUSTOMER_DIAL_COUNT,
  irf.CUSTOMER_DIAL_DURATION,
  irf.CUSTOMER_RING_COUNT,
  irf.CUSTOMER_RING_DURATION,
  irf.CUSTOMER_TALK_COUNT,
  irf.CUSTOMER_TALK_DURATION,
  irf.CUSTOMER_HOLD_COUNT,
  irf.CUSTOMER_HOLD_DURATION,
  irf.CUSTOMER_ACW_COUNT,
  irf.CUSTOMER_ACW_DURATION,
  irf.POST_CONS_XFER_TALK_COUNT,
  irf.POST_CONS_XFER_TALK_DURATION,
  irf.POST_CONS_XFER_HOLD_COUNT,
  irf.POST_CONS_XFER_HOLD_DURATION,
  irf.POST_CONS_XFER_RING_COUNT,
  irf.POST_CONS_XFER_RING_DURATION,
  irf.CONF_INIT_TALK_COUNT,
  irf.CONF_INIT_TALK_DURATION,
  irf.CONF_INIT_HOLD_COUNT,
  irf.CONF_INIT_HOLD_DURATION,
  irf.CONF_JOIN_RING_COUNT,
  irf.CONF_JOIN_RING_DURATION,
  irf.CONF_JOIN_TALK_COUNT,
  irf.CONF_JOIN_TALK_DURATION,
  irf.CONF_JOIN_HOLD_COUNT,
  irf.CONF_JOIN_HOLD_DURATION,
  irf.CONFERENCE_INITIATED_COUNT,
  irf.CONS_INIT_DIAL_COUNT,
  irf.CONS_INIT_DIAL_DURATION,
  irf.CONS_INIT_TALK_COUNT,
  irf.CONS_INIT_TALK_DURATION,
  irf.CONS_INIT_HOLD_COUNT,
  irf.CONS_INIT_HOLD_DURATION,
  irf.CONS_RCV_RING_COUNT,
  irf.CONS_RCV_RING_DURATION,
  irf.CONS_RCV_TALK_COUNT,
  irf.CONS_RCV_TALK_DURATION,
  irf.CONS_RCV_HOLD_COUNT,
  irf.CONS_RCV_HOLD_DURATION,
  irf.CONS_RCV_ACW_COUNT,
  irf.CONS_RCV_ACW_DURATION,
  irf.AGENT_TO_AGENT_CONS_COUNT,
  irf.AGENT_TO_AGENT_CONS_DURATION,
  nvl(CASE WHEN RTA.ROUTING_TARGET_TYPE_CODE='AGENT GROUP' THEN  rta.AGENT_GROUP_NAME
          WHEN RTA.ROUTING_TARGET_TYPE_CODE='PLACE GROUP' THEN  rta.PLACE_GROUP_NAME
          WHEN RTA.ROUTING_TARGET_TYPE_CODE='SKILL EXPRESSION' THEN  rta.SKILL_EXPRESSION
  ELSE NULL
  END,'Unspecified') Tipo_Target,
  rta.routing_target_TYPE,
  rta.TARGET_OBJECT_SELECTED,
  IRF_USER_DATA_GEN_1.CUSTOMER_ID,
  ifa.ACTIVE_FLAG,
  irf.STOP_ACTION,
  udc1.DIM_ATTRIBUTE_1 "TABULACION1",
  udc1.DIM_ATTRIBUTE_2 "TABULACION2",
  udc1.DIM_ATTRIBUTE_3 "TABULACION3",
  udc1.DIM_ATTRIBUTE_4 "TABULACION4",
  udc2.DIM_ATTRIBUTE_4 Agrupador1,
  udc2.DIM_ATTRIBUTE_5 Agrupador2,
  udc2.DIM_ATTRIBUTE_2 "Contexto IVR/0800",
  udc2.DIM_ATTRIBUTE_3 "Contexto IVR/0800 Opción",
  udc1.DIM_ATTRIBUTE_5 "Contexto IVR/0800 Segmento",
  ifa.SOURCE_ADDRESS "REGION/LOCALIDAD",
  iud1.CUSTOM_DATA_1 "DNI o Documento",
  iud1.CUSTOM_DATA_2 "NOMBRE CLIENTE",
  iud1.CUSTOM_DATA_5 "EMAIL CLIENTE",
  iud1.custom_data_3 ID_IVR,
  iud1.custom_data_4 PostDiscado,
  ifa.MEDIA_SERVER_IXN_GUID "ID NICE",
  IFA.START_TS Ini_IFA_SEG,
  IFA.END_TS FIN_IFA_SEG,
  MSF.START_TS Ini_MSF_SEG,
  MSF.END_TS FIN_MSF_SEG,
  IRF.START_TS Ini_IRF_SEG,
  IRF.END_TS FIN_IRF_SEG,
  irf.CUSTOMER_HANDLE_COUNT,
 case when (irf.CUSTOMER_HANDLE_COUNT > 0 and irf.CUSTOMER_TALK_DURATION between 0 and 10) 
      then 1
      else 0
 end LLamada_Corta_1_9,
  case when (irf.CUSTOMER_HANDLE_COUNT > 0 and irf.CUSTOMER_TALK_DURATION between 11 and 20) 
      then 1
      else 0
 end LLamada_Corta_10_19,
  case when (irf.CUSTOMER_HANDLE_COUNT > 0 and irf.CUSTOMER_TALK_DURATION between 21 and 30) 
      then 1
      else 0
 end LLamadaCorta_20_29,
    --  Abandonadas en Ringin umbrales
  case when irf.CUSTOMER_RING_COUNT > 0
            and ((TDE_VQ.TECHNICAL_RESULT = 'Diverted' and TDE_VQ.RESULT_REASON = 'AbandonedWhileRinging') )
            and ((IRF.CUSTOMER_RING_DURATION between 0 and 10)) 
       then 1
       else 0
  end Abandono_R_1_9,
  case when irf.CUSTOMER_RING_COUNT > 0
            and ((TDE_VQ.TECHNICAL_RESULT = 'Diverted' and TDE_VQ.RESULT_REASON = 'AbandonedWhileRinging') )
            and ((IRF.CUSTOMER_RING_DURATION between 11 and 20)) 
       then 1
       else 0
  end Abandono_R_10_19,
  case when irf.CUSTOMER_RING_COUNT > 0
            and ((TDE_VQ.TECHNICAL_RESULT = 'Diverted' and TDE_VQ.RESULT_REASON = 'AbandonedWhileRinging') )
            and ((IRF.CUSTOMER_RING_DURATION between 21 and 30)) 
       then 1
       else 0
  end Abandono_R_20_29,
  case when irf.CUSTOMER_RING_COUNT > 0
            and ((TDE_VQ.TECHNICAL_RESULT = 'Diverted' and TDE_VQ.RESULT_REASON = 'AbandonedWhileRinging') )
            and ((IRF.CUSTOMER_RING_DURATION between 31 and 40)) 
       then 1
       else 0
  end Abandono_R_30_39,
  case when irf.CUSTOMER_RING_COUNT > 0
            and ((TDE_VQ.TECHNICAL_RESULT = 'Diverted' and TDE_VQ.RESULT_REASON = 'AbandonedWhileRinging') )
            and ((IRF.CUSTOMER_RING_DURATION between 41 and 50)) 
       then 1
       else 0
  end Abandono_R_40_49,
  case when irf.CUSTOMER_RING_COUNT > 0
            and ((TDE_VQ.TECHNICAL_RESULT = 'Diverted' and TDE_VQ.RESULT_REASON = 'AbandonedWhileRinging') )
            and ((IRF.CUSTOMER_RING_DURATION between 51 and 60)) 
       then 1
       else 0
  end Abandono_R_50_59,
  case when irf.CUSTOMER_RING_COUNT > 0
            and ((TDE_VQ.TECHNICAL_RESULT = 'Diverted' and TDE_VQ.RESULT_REASON = 'AbandonedWhileRinging') )
            and ((IRF.CUSTOMER_RING_DURATION between 61 and 90)) 
       then 1
       else 0
  end Abandono_R_60_89,
  case when irf.CUSTOMER_RING_COUNT > 0
            and ((TDE_VQ.TECHNICAL_RESULT = 'Diverted' and TDE_VQ.RESULT_REASON = 'AbandonedWhileRinging') )
            and ((IRF.CUSTOMER_RING_DURATION between 91 and 120)) 
       then 1
       else 0
  end Abandono_R_90_119,
 case when irf.CUSTOMER_RING_COUNT > 0
            and ((TDE_VQ.TECHNICAL_RESULT = 'Diverted' and TDE_VQ.RESULT_REASON = 'AbandonedWhileRinging') )
            and ((IRF.CUSTOMER_RING_DURATION >= 121)) 
       then 1
       else 0
  end Abandono_R_120_Mas,
  res_vq.switch_name
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
     irf.INTERACTION_ID=ifa.INTERACTION_ID --and IRF.START_DATE_TIME_KEY = IFA.START_DATE_TIME_KEY
INNER JOIN 
    a001441.routing_target rta
ON 
        rta.routing_target_KEY=irf.routing_target_KEY
INNER JOIN 
    a001441.RESOURCE_ res_vq 
ON 
    res_vq.RESOURCE_KEY=irf.LAST_VQUEUE_RESOURCE_KEY
INNER JOIN 
    a001441.Resource_ RESOURCE_GI2 
ON 
    (irf.RESOURCE_KEY=RESOURCE_GI2.RESOURCE_KEY)
left JOIN 
    a001441.RESOURCE_  resirf 
ON 
   (resirf.RESOURCE_KEY=irf.RESOURCE_KEY)
left JOIN 
    a001441.TECHNICAL_DESCRIPTOR tde_ag
ON 
   (tde_ag.TECHNICAL_DESCRIPTOR_KEY=irf.TECHNICAL_DESCRIPTOR_KEY)
left JOIN 
    a001441.RESOURCE_STATE rst
ON 
    (rst.RESOURCE_STATE_KEY=irf.RES_PREVIOUS_SM_STATE_KEY)
left JOIN 
    a001441.IRF_USER_DATA_GEN_1 
    ON 
        (irf.INTERACTION_RESOURCE_ID=IRF_USER_DATA_GEN_1.INTERACTION_RESOURCE_ID and irf.START_DATE_TIME_KEY=IRF_USER_DATA_GEN_1.START_DATE_TIME_KEY)
left JOIN 
    a001441.IRF_USER_DATA_KEYS 
ON 
        (IRF_USER_DATA_KEYS.INTERACTION_RESOURCE_ID=irf.INTERACTION_RESOURCE_ID and IRF_USER_DATA_KEYS.START_DATE_TIME_KEY=irf.START_DATE_TIME_KEY)
left JOIN 
    a001441.interaction_descriptor INTERACTION_DESCRIPTOR_GI2 
ON 
        (INTERACTION_DESCRIPTOR_GI2.INTERACTION_DESCRIPTOR_KEY=IRF_USER_DATA_KEYS.INTERACTION_DESCRIPTOR_KEY)
inner join 
    a001441.date_time dt 
    on 
        DT.DATE_TIME_KEY = irf.START_DATE_TIME_KEY
left join
    a001441.mediation_segment_fact msf
on
     MSF.MEDIATION_SEGMENT_ID = IRF.MEDIATION_SEGMENT_ID --and MSF.START_DATE_TIME_KEY = IRF.START_DATE_TIME_KEY 
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
left join
    a001441.place pl
on
    PL.PLACE_KEY = irf.place_key    
-- Custom Attached Data Hgh Cardinality 1
left join 
 a001441.IRF_USER_DATA_CUST_1 iud1
on
 irf.interaction_resource_id = iud1.INTERACTION_RESOURCE_ID
left join
    a001441.resource_group_combination   rgc_vag  
on
    RGC_vag.GROUP_COMBINATION_KEY = IRF.RESOURCE_GROUP_COMBINATION_KEY
left join
    a001441.group_ grovag     
on 
    grovag.group_key = rgc_vag.group_key    
left join
    a001441.resource_group_combination   rgc_vq  
on
    RGC_vq.GROUP_COMBINATION_KEY = msf.RESOURCE_GROUP_COMBINATION_KEY
left join
    a001441.group_ grogvq     
on 
    grogvq.group_key = rgc_vq.group_key
-- Join para hacer la búsqueda de las interacciones en donde los agentes realizaron una llamada (consulta, trasnferencia
-- interna u outbound   
left join
    (select interaction_id,
            ixrsf.target_address,
            IRFint.INTERACTION_RESOURCE_ID
    from a001441.interaction_resource_fact irfint
    inner join       
        a001441.date_time dt
    on
        DT.DATE_TIME_KEY = irfint.START_DATE_TIME_KEY
    inner join
        a001441.ixn_resource_state_fact ixrsf
    on
       ixrsf.INTERACTION_RESOURCE_ID = irfint.INTERACTION_RESOURCE_ID
       and irfint.START_DATE_TIME_KEY = ixrsf.START_DATE_TIME_KEY
    inner join
       a001441.interaction_resource_state irs
    on
       IRS.INTERACTION_RESOURCE_STATE_KEY = ixrsf.interaction_RESOURCE_STATE_KEY
       and IRS.STATE_NAME = 'Initiate'
       and state_role = 'Initiator'
       and ixrsf.INTERACTION_RESOURCE_ID = irfint.INTERACTION_RESOURCE_ID
       and irfint.START_DATE_TIME_KEY = ixrsf.START_DATE_TIME_KEY
       and irfint.interaction_type_key = ixrsf.interaction_type_key) telf
on
    telf.interaction_id = IRF.INTERACTION_ID  and IRF.INTERACTION_RESOURCE_ID = telf.INTERACTION_RESOURCE_ID
--
where to_date(to_char(cal_date, 'dd-mm-yyyy'), 'dd-mm-yyyy') between to_date('$varFechaReporte', 'dd-mm-yyyy') and to_date('$varFechaReporte', 'dd-mm-yyyy')
and media_name = 'Voice'
and (grovag.group_name like 'VAG_R%_%Q%' or grovag.group_name = 'No Group')
order by irf.START_TS, IRF.INTERACTION_RESOURCE_ORDINAL--, grovag.group_name,  grogvq.group_name
;
EOF
sed -i "s/ \+|/|/g;s/| \+/|/g;s/^\s*//;s/[ \t]*$//" $varArchivoOut