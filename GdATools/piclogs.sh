#!/bin/bash
alias fttget='/usr/bin/sudo /usr/local/seguridad/bin/fttget'
mkdir $HOME/logs 1>/dev/null 2>/dev/null
cd $HOME/logs
rm -rf $HOME/logs/* 1>/dev/null 2>/dev/null

echo " ########################################################"
echo " Script de Copia Automatica de Logs de GdA Contact Center"
echo " G    E    N    E    S    Y    S              P    I    C"
echo " ########################################################"
echo " Version 0.2 - 26-4-2019 "
echo ""
echo " Este Script copia del dia corriente del ConfigServer Primario"
echo " De Genesys PIC y de los Proxy Servers Primarios de Pacheco"
echo " "
echo ""
file="PIClogs_$(date +'%Y-%m-%d_%S')--plpicpacapp66_confserv.zip"
echo " Copiando logs de Configserver Primario.." && \
/usr/bin/sudo /usr/local/seguridad/bin/fttget plpicpacapp66 /var/log/genesys/confserv/*$(date +'%Y%m%d')* ./ 1>/dev/null 2>/dev/null && \
echo " Descargados $(du -sh ./ | awk '{print $1}') del servidor" && \
echo " Comprimiendo logs..." && \
#tar -zcf ../logs_plpicpacapp66_confserv.tar.gz ./* 1>/dev/null && \
zip $HOME/$file ./* 1>/dev/null 2>/dev/null && \
echo " Comprimido en $(ls -lsh ../$file | awk '{print $6}')" && \
echo " Enviando log a http://wga/logs ..."
curl -F "file=@$HOME/$file" http://wga/logs/upload/index.php 1>/dev/null 2>/dev/null
echo " Borrando archivos temporales.." && \
rm -rf $HOME/logs/* 1>/dev/null
rm -rf ../$file 1>/dev/null 2>/dev/null
echo " >> Descarga el log desde http://wga/logs/upload/data/$file"


for i in 0{1..9} {10..18}
do
cd $HOME/logs
file="PIClogs_$(date +'%Y-%m-%d_%S')--plpicpacapp$((10#$i + 12))_servicio_pac_cfgprx_$i.zip"
echo "" && \
echo " Copiando logs del servicio pac_cfgprx_$i" && \
/usr/bin/sudo /usr/local/seguridad/bin/fttget plpicpacapp$((10#$i + 12)) /var/log/genesys/pac_cfgprx_$i/*$(date +'%Y%m%d')* ./ 1>/dev/null 2>/dev/null && \
echo " Descargados $(du -sh ./ | awk '{print $1}') del servidor" && \
echo " Comprimiendo logs en archivo logs_plpicpacapp$((10#$i + 12))_pac_cfgprx_$i.tar.gz" && \
#tar -zcf ../logs_plpicpacapp$((10#$i + 12))_pac_cfgprx_$i.tar.gz ./* 1>/dev/null && \
zip ../$file ./* 1>/dev/null && \
echo " Comprimido en $(ls -lsh ../$file | awk '{print $6}')" && \
echo " Enviando log a http://wga/logs ..."
curl -F "file=@../$file" http://wga/logs/upload/index.php 1>/dev/null 2>/dev/null && \
echo " Borrando archivos temporales.." && \
rm -rf $HOME/logs/* 1>/dev/null
rm -rf $HOME/$file
echo " >> Descarga el log desde http://wga/logs/upload/data/$file"
done
