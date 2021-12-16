#!/bin/bash -e

export USER="root"
export PASSWORD="TralalaTrololo"
export SOURCE_DATABASE="csserver"
export DESTINATION_DATABASE="${SOURCE_DATABASE}_`date +%Y_%m`"

while etopts "u:p:s:d:" opt; do
     case $opt in
         u) USER=$OPTARG;;
         p) PASSWORD=$OPTARG;;
         s) SOURCE_DATABASE=$OPTARG;;
         d) DESTINATION_DATABASE=$OPTARG;;
     esac
done

docker exec mysql mysql -u $USER -p$PASSWORD -s -N -e "CREATE DATABASE $DESTINATION_DATABASE;";
for table in `docker exec mysql mysql -u $USER -p$PASSWORD -s -N -e "USE $SOURCE_DATABASE; SHOW TABLES FROM $SOURCE_DATABASE;"`; do
  docker exec mysql mysql -u $USER -p$PASSWORD -s -N -e "USE $SOURCE_DATABASE; RENAME TABLE $SOURCE_DATABASE.$table TO $DESTINATION_DATABASE.$table;";
done;
