#!/bin/bash -e

# Maps
ls serverfiles/cstrike/maps/ -1 | grep .bsp | sed s/.bsp//g > serverfiles/cstrike/addons/amxmodx/configs/maps.ini

# Plugins
cd serverfiles/cstrike/addons/amxmodx/scripting
for plugin in afk_manager_1-8-2 AntiSpawnKill round_startmoney spec_hud_info ; do
    ./amxxpc $plugin.sma -o../plugins/$plugin.amxx
    echo $plugin.amxx >> ../configs/plugins.ini
done
cd -
