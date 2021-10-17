#!/bin/bash -e

# Public IP
MY_PUBLIC_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
sed s/__MY_PUBLIC_IP__/$MY_PUBLIC_IP/g -i serverfiles/cstrike/motd.txt serverfiles/cstrike/csserver.cfg

# Maps
ls serverfiles/cstrike/maps/ -1 | grep .bsp | sed s/.bsp//g > serverfiles/cstrike/addons/amxmodx/configs/maps.ini

# Plugins
cd serverfiles/cstrike/addons/amxmodx/scripting
for plugin in AntiSpawnKill afk_manager_1-8-3 automatic_knife_duel gungame killer_view psd rememberthescore round_startmoney spec_hud_info ; do
    ./amxxpc $plugin.sma -o../plugins/$plugin.amxx
    echo $plugin.amxx >> ../configs/plugins.ini
done
cd -

# CSDM 2.0
wget -O csdm-2.0.zip https://forums.alliedmods.net/attachment.php?attachmentid=4292
unzip csdm-2.0.zip
cp -r csdm-2.0/* serverfiles/cstrike/addons/amxmodx/
rm -rf csdm-2.0*

# CSDM 2.1
#wget http://www.bailopan.net/csdm/files/csdm-2.1.2.zip
#unzip csdm-2.1.2.zip -d serverfiles/cstrike/
