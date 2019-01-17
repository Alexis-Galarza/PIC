#!/bin/sh
#----------------------------------------------------------------------------------------
# Script para obtener reportes historicos PIC. LL_EST_REASON_DET
# Ejecuta reporte para el dia de ayer
# Ejecucion: ./LL_EST_REASON_DET.sh ConexionBD     (Formato ConexionBD: usr/pass@DB)
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
varArchivoOut="LL_EST_REASON_DET_$varFechaArchivo.txt" #--LL_EST_REASON_DET_YYYYMMDD.txt
	#---------------------------------------
	# Hardcode para test
	#varFechaReporte="08-05-2018"
	#varFechaArchivo="20180508"
	#varArchivoOut="LL_EST_REASON_DET_20180508.txt"
	#----------------------------------------
cd /opt/genesys/InterfacesReportesPIC
sqlplus -s $varConexionSQL <<EOF > /dev/null
set feedback on verify on heading off colsep '|' termout off ECHO on TRIMOUT on TRIMSPOOL on LINESIZE 32767 WRAP off PAGESIZE 0
SET SPOOL ON
SPOOL $varArchivoOut
select  res.RESOURCE_NAME Agente,
        group_name "VAG",
        SRSELF.SM_RES_SESSION_FACT_KEY,
        -- Fechas del reporte
        to_char(cal_date,'dd/mm/yyyy') Fecha,
         case when to_char( to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') = 
                  to_char( to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy')
             then 0
             else 1
        end "OtroDia",
        case when to_char( to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') = 
                  to_char( to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy')
             then to_char( to_date('1970-01-01','YYYY-MM-DD') + (date_time_day_key/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS')
             else to_char( to_date('1970-01-01','YYYY-MM-DD') + (date_time_next_day_key/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS')
        end "DIA",
        /********************
        --
        -- Información de Login del Agente
        --
        *********************/
        -- Fechas y duración real del login
        to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS') Inicio_Login,
        to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS') Fin_Login,
        srself.total_duration T_Login_Segundos,
        SRSELF.active_flag Login_Activo,
        -- identifica si el agente realizó el login en un día y el logout al día siguiente
        case when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') <
                   to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')
             then to_char(to_date('1970-01-01','YYYY-MM-DD') + (date_time_next_day_key/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS') 
             else to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS')
        end Inicio_Login_MismoDia,     
        case when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')
             then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS')
             else to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-1/24/60/60, 'dd/mm/yyyy HH24:MI:SS')
        end Fin_Login_MismoDia,
        case when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')
             then (srself.total_duration) 
             else (date_time_next_day_key- SRSELF.START_TS)
        end T_Login_Segundos_MismoDia,
        case when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') >
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')
             then to_char(to_date('1970-01-01','YYYY-MM-DD') + (date_time_next_day_key/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS')  
             else to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')
        end Inicio_Login_SigDia,
        case when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')
             then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS') 
             else to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS')
        end Fin_Login_SigDia,     
        case when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')
             then 0 
             else (SRSELF.end_TS - date_time_next_day_key)
        end T_Login_Segundos_SigDia, 
        --------
        -- Estados del Agente
        --------
        nvl(SRSF.SM_RES_STATE_FACT_KEY,0) SM_RES_STATE_FACT_KEY,
        case when to_char( to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy') = 
                 to_char( to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy') and
                 to_char( to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') = 
                 to_char( to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy')
            then 0
            else 1
        end Estado_OtroDia,
        nvl(rs.STATE_NAME,'') STATE_NAME,
        nvl(rs.STATE_TYPE, '') STATE_TYPE,
        to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS') Inicio_Estado,
        to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS') Fin_Estado,        
        nvl(srsf.total_duration,'') T_Estado_Segundos,
        nvl(srsf.ACTIVE_FLAG,'') Estado_Activo,
        case when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy') = 
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') 
             then 1
             else 0
        end Estado_Inicia_Mismo_Dia, 
         case when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy') = 
                   to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') 
              then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS')
              else to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')
         end Inicio_Estado_MismoDia,    
        case 
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')  
             then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS') 
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')
             then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS') 
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') and
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy')       
             then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-1/24/60/60, 'dd/mm/yyyy HH24:MI:SS')
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy') 
             then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')
        end Fin_Estado_MismoDia,
        case when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy') and
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy')
             then srsf.total_duration
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                   to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy')
             then 0     
             else date_time_next_day_key - SRSF.START_TS     
        end T_Estado_Segundos_MismoDia,        
        case 
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')  
             then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')
             then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')  
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') and
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy')       
             then to_char(to_date('1970-01-01','YYYY-MM-DD') + (date_time_next_day_key/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS')
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy')
             then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24 , 'dd/mm/yyyy HH24:MI:SS')
        end Inicio_Estado_SigDia,
        case 
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')  
             then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')  
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')
             then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')  
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') and
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy')       
             then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24 , 'dd/mm/yyyy HH24:MI:SS')
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy')
             then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS') 
        end Fin_Estado_SigDia,     
        case 
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')  
             then 0
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')
             then 0  
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') and
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy')       
             then (SRSF.end_TS - date_time_next_day_key)
             when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                  to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy')
             then (SRSF.total_duration)
        end T_Estado_Segundos_SigDia, 
        --------
        -- Razón de Estados del Agente
        --------
        nvl(srsrf.RESOURCE_STATE_REASON_KEY,-2) RESOURCE_STATE_REASON_KEY,
        nvl(srsrf.active_flag, -2) Reason_Activo,
        nvl(rsr.REASON_TYPE,'No Reason') REASON_TYPE,
        nvl(rsr.SOFTWARE_REASON_VALUE,'No Reason')  Software_Reason,
        nvl(rsr.HARDWARE_REASON,'No Reason') HARDWARE_REASON,
        nvl(rsr.WORKMODE, 'No WorkMode') WORKMODE,
        case when nvl(srsrf.RESOURCE_STATE_REASON_KEY,-2) = -2
            then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')
            else nvl(to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS'),'') 
        end Ini_Razon,
        case when nvl(srsrf.RESOURCE_STATE_REASON_KEY,-2) = -2
             then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')
             else nvl(to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS'),'')
        end   Final_Razon,
        nvl(srsrf.total_duration,0) T_Razon_Segundos,
        case when nvl(srsrf.RESOURCE_STATE_REASON_KEY,-2) = -2
             then -2
             else
                  case when to_char( to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy') = 
                         to_char( to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy') and
                         to_char( to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') = 
                         to_char( to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy') 
                    then 0
                    else 1
                  end  
        end Razon_OtroDia,
        case when nvl(srsrf.RESOURCE_STATE_REASON_KEY,-2) = -2
             then -2
             else
                case when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsf.start_TS/86400)-3/24, 'dd/mm/yyyy') = 
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') 
                     then 1
                     else 0
                end 
        end Razon_Inicia_Mismo_Dia, 
         case when nvl(srsrf.RESOURCE_STATE_REASON_KEY,-2) = -2
             then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')
             else
                 case when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy') = 
                           to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') 
                      then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS')
                      else to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')
                 end    
        end Inicio_Razon_MismoDia,     
        case when nvl(srsrf.RESOURCE_STATE_REASON_KEY,-2) = -2
             then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')
             else
                 case
                     when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')  
                     then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS') 
                     when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')
                     then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS') 
                     when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') and
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy')       
                     then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-1/24/60/60, 'dd/mm/yyyy HH24:MI:SS')
                     when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy') 
                     then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS') 
                 end  
        end Fin_Razon_MismoDia,
        case when nvl(srsrf.RESOURCE_STATE_REASON_KEY,-2) = -2
             then 0
             else
                 case when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy') and
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy')
                     then srsrf.total_duration 
                     when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy')
                     then 0      
                     else date_time_next_day_key- srsrf.START_TS
                end             
        end T_Razon_Segundos_MismoDia,
       case when nvl(srsrf.RESOURCE_STATE_REASON_KEY,-2) = -2
            then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')
            else
                case 
                     when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')  
                     then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')  
                     when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')
                     then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')
                     when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') and
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy')       
                     then to_char(to_date('1970-01-01','YYYY-MM-DD') + (date_time_next_day_key/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS')
                     when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy')
                     then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS') 
                end     
        end Inicio_Razon_SigDia,
        case when nvl(srsrf.RESOURCE_STATE_REASON_KEY,-2) = -2
             then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')
             else
                case 
                     when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')  
                     then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')  
                     when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy')
                     then to_char(to_date('31/12/2050 11:59:59','dd/mm/yyyy hh:mi:ss'), 'dd/mm/yyyy HH24:MI:SS')  
                     when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') and
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy')       
                     then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS') 
                     when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy') and 
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.end_TS/86400)-3/24, 'dd/mm/yyyy')
                     then to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy HH24:MI:SS') 
                end     
        end Fin_Razon_SigDia,     
        case when nvl(srsrf.RESOURCE_STATE_REASON_KEY,-2) = -2
             then 0
             else
               case when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy') and
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy')
                     then 0
                     when to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.end_TS/86400)-3/24, 'dd/mm/yyyy') =
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy') and
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srself.start_TS/86400)-3/24, 'dd/mm/yyyy') <
                          to_char(to_date('1970-01-01','YYYY-MM-DD') + (srsrf.start_TS/86400)-3/24, 'dd/mm/yyyy') 
                     then srsrf.total_duration     
                     else SRSrF.end_TS - date_time_next_day_key
                end    
        end T_Razon_Segundos_SigDia 
from a001441.SM_RES_STATE_FACT srsf
left join
    a001441.RESOURCE_STATE rs
on
    rs.RESOURCE_STATE_KEY = srsf.RESOURCE_STATE_KEY
inner join
    a001441.sm_res_session_fact srself
on
   SRSElF.SM_RES_SESSION_FACT_KEY = SRSF.SM_RES_SESSION_FACT_KEY                         
inner join
    a001441.DATE_TIME dt 
on
    dt.DATE_TIME_KEY = srself.START_DATE_TIME_KEY
inner join
    a001441.RESOURCE_ res
on
    res.RESOURCE_KEY = srsf.RESOURCE_KEY
inner join
    a001441.MEDIA_TYPE mt
on
    mt.MEDIA_TYPE_KEY = srsf.MEDIA_TYPE_KEY
left join
    a001441.SM_RES_STATE_REASON_FACT srsrf
on
    srsf.RESOURCE_KEY = srsrf.RESOURCE_KEY and srsrf.SM_RES_STATE_FACT_KEY = srsf.SM_RES_STATE_FACT_KEY and SRSRF.MEDIA_TYPE_KEY = SRSF.MEDIA_TYPE_KEY 
left join
    a001441.RESOURCE_STATE_REASON rsr
on
    rsr.RESOURCE_STATE_REASON_KEY = srsrf.RESOURCE_STATE_REASON_KEY
inner join
    a001441.resource_group_fact rgf
on
    RGF.RESOURCE_KEY = res.resource_key
inner join
    a001441.group_ gro
on
   GRO.GROUP_KEY = rgf.group_key  and srself.start_ts between rgf.start_ts and rgf.end_ts 
where to_date(to_char(cal_date, 'dd/mm/yyyy'), 'dd/mm/yyyy') between to_date('$varFechaReporte', 'dd/mm/yyyy') and to_date('$varFechaReporte', 'dd/mm/yyyy')   
and group_name like 'VAG_RIMM%_QC2S%'
order by  resource_name,srself.start_ts, srsf.start_ts, sm_res_state_fact_key, srsrf.start_ts
;
EOF
sed -i "s/ \+|/|/g;s/| \+/|/g;s/^\s*//;s/[ \t]*$//" $varArchivoOut