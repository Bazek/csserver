#!/bin/bash -e

# Maps
ls serverfiles/cstrike/maps/ -1 | grep .bsp | sed s/.bsp//g > serverfiles/cstrike/addons/amxmodx/configs/maps.ini

# Plugins
cd serverfiles/cstrike/addons/amxmodx/scripting
for plugin in afk_manager_1-8-3 AntiSpawnKill killer_view psd rememberthescore round_startmoney spec_hud_info ; do
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
