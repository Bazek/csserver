#!/bin/bash -e

# Wait for nginx
until wget http://nginx:8016/motd.txt -o /dev/null &> /dev/null ; do
    echo Waiting for nginx...
    sleep 1
done

# Wait for mysql
until mysql --host=mysql --port=3306 --user=root --password=TralalaTrololo csserver -e exit &> /dev/null ; do
    echo Waiting for mysql...
    sleep 1
done

# Start csserver
echo
echo STARTING CSSERVER...
echo
sed "s/__SV_PASSWORD__/$SV_PASSWORD/g" -i /home/csserver/serverfiles/cstrike/csserver.cfg
sed "s/__GG_ENABLED__/$GG_ENABLED/g" -i /home/csserver/serverfiles/cstrike/addons/amxmodx/configs/gungame.cfg
./csserver start
tail -n +1 -f /home/csserver/log/console/csserver-console.log
