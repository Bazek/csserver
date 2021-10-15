#!/bin/bash -e

# LinuxGSM
wget -O linuxgsm.sh https://linuxgsm.sh && chmod +x linuxgsm.sh
./linuxgsm.sh csserver && yes | ./csserver install

# Metamod
mkdir -p serverfiles/cstrike/addons/metamod/dlls
wget https://prdownloads.sourceforge.net/metamod/metamod-1.20-linux.tar.gz
tar -zxvf metamod-1.20-linux.tar.gz -C serverfiles/cstrike/addons/metamod/dlls
rm metamod-1.20-linux.tar.gz
sed -iE 's~gamedll_linux .*~gamedll_linux "addons/metamod/dlls/metamod.so"~' serverfiles/cstrike/liblist.gam

# AMXModX 1.8.2
#wget https://www.amxmodx.org/release/amxmodx-1.8.2-base-linux.tar.gz
#tar -zxvf amxmodx-1.8.2-base-linux.tar.gz -C serverfiles/cstrike
#rm amxmodx-1.8.2-base-linux.tar.gz
#wget https://www.amxmodx.org/release/amxmodx-1.8.2-cstrike-linux.tar.gz
#tar -zxvf amxmodx-1.8.2-cstrike-linux.tar.gz -C serverfiles/cstrike
#rm amxmodx-1.8.2-cstrike-linux.tar.gz
#echo "linux addons/amxmodx/dlls/amxmodx_mm_i386.so" > serverfiles/cstrike/addons/metamod/plugins.ini

# AMXModX 1.9
wget https://www.amxmodx.org/amxxdrop/1.9/amxmodx-1.9.0-git5293-base-linux.tar.gz
tar -zxvf amxmodx-1.9.0-git5293-base-linux.tar.gz -C serverfiles/cstrike
rm amxmodx-1.9.0-git5293-base-linux.tar.gz
wget https://www.amxmodx.org/amxxdrop/1.9/amxmodx-1.9.0-git5293-cstrike-linux.tar.gz
tar -zxvf amxmodx-1.9.0-git5293-cstrike-linux.tar.gz -C serverfiles/cstrike
rm amxmodx-1.9.0-git5293-cstrike-linux.tar.gz
echo "linux addons/amxmodx/dlls/amxmodx_mm_i386.so" >> serverfiles/cstrike/addons/metamod/plugins.ini

# PODBots
wget -O podbot_full_V3B22.zip https://www.gvme.org/dl/5310
unzip podbot_full_V3B22.zip -d serverfiles/cstrike/addons
rm podbot_full_V3B22.zip
echo "linux addons/podbot/podbot_mm_i386.so" >> serverfiles/cstrike/addons/metamod/plugins.ini
