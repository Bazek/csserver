#!/bin/bash -e

USER="root"
PASSWORD="TralalaTrololo"
SOURCE_DATABASE="csserver"
DESTINATION_DATABASE="${SOURCE_DATABASE}_`date +%Y_%m`"

while getopts "u:p:s:d:" opt; do
     # shellcheck disable=SC2220
     case $opt in
         u) USER=$OPTARG;;
         p) PASSWORD=$OPTARG;;
         s) SOURCE_DATABASE=$OPTARG;;
         d) DESTINATION_DATABASE=$OPTARG;;
     esac
done

docker-compose down csserver
docker exec mysql mysql -u $USER -p$PASSWORD -s -N -e "CREATE DATABASE $DESTINATION_DATABASE;";
for table in `docker exec mysql mysql -u $USER -p$PASSWORD -s -N -e "USE $SOURCE_DATABASE; SHOW TABLES FROM $SOURCE_DATABASE;"`; do
  docker exec mysql mysql -u $USER -p$PASSWORD -s -N -e "USE $SOURCE_DATABASE; RENAME TABLE $SOURCE_DATABASE.$table TO $DESTINATION_DATABASE.$table;";
done;
docker-compose up --detach
