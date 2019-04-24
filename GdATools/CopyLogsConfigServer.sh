#!/bin/bash
alias fttget='/usr/bin/sudo /usr/local/seguridad/bin/fttget'
mkdir $HOME/logs
cd $HOME/logs
rm -rf $HOME/logs/*

/usr/bin/sudo /usr/local/seguridad/bin/fttget plpicpacapp66 /var/log/genesys/confserv/*$(date +'%Y%m%d')* ./ && tar -zcf ../logs_plpicpacapp66_confserv.tar.gz ./* && rm -rf $HOME/logs/*

for i in 0{1..9} {10..18}
do
cd $HOME/logs
/usr/bin/sudo /usr/local/seguridad/bin/fttget plpicpacapp$((10#$i + 12)) /var/log/genesys/pac_cfgprx_$i/*$(date +'%Y%m%d')* ./ && tar -zcf ../logs_plpicpacapp$((10#$i + 12))_pac_cfgprx_$i.tar.gz ./* && rm -rf $HOME/logs/*
done
