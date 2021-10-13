#!/bin/bash -e

# Maps
ls serverfiles/cstrike/maps/ -1 | grep .bsp | sed s/.bsp//g > serverfiles/cstrike/addons/amxmodx/configs/maps.ini

# Plugins
cd serverfiles/cstrike/addons/amxmodx/scripting
./compile.sh
cp compiled/*.amxx ../plugins
