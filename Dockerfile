FROM debian
MAINTAINER Petr Bartunek <petr.bartunek@firma.seznam.cz>

# Dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update -y && apt-get upgrade -y && \
    apt-get install -y \
        curl wget procps file tar bzip2 gzip unzip bsdmainutils python3 util-linux \
        ca-certificates binutils bc jq tmux netcat cpio lib32gcc1 lib32stdc++6 libsdl2-2.0-0:i386 && \
    apt-get clean && apt-get auto-clean && rm -rf /var/lib/apt/lists/*

# User
RUN groupadd -r linuxGSM && adduser --ingroup linuxGSM csserver
WORKDIR /home/csserver
USER csserver

# LinuxGSM
RUN wget -O linuxgsm.sh https://linuxgsm.sh && chmod +x linuxgsm.sh && \
    ./linuxgsm.sh csserver && yes | ./csserver install

# Metamod
RUN mkdir -p serverfiles/cstrike/addons/metamod/dlls && \
    wget https://prdownloads.sourceforge.net/metamod/metamod-1.20-linux.tar.gz && \
    tar -zxvf metamod-1.20-linux.tar.gz -C serverfiles/cstrike/addons/metamod/dlls && \
    rm metamod-1.20-linux.tar.gz && \
    sed -iE 's~gamedll_linux .*~gamedll_linux "addons/metamod/dlls/metamod.so"~' serverfiles/cstrike/liblist.gam

# AMXModX
RUN wget https://www.amxmodx.org/release/amxmodx-1.8.2-base-linux.tar.gz && \
    tar -zxvf amxmodx-1.8.2-base-linux.tar.gz -C serverfiles/cstrike && \
    rm amxmodx-1.8.2-base-linux.tar.gz && \
    wget https://www.amxmodx.org/release/amxmodx-1.8.2-cstrike-linux.tar.gz && \
    tar -zxvf amxmodx-1.8.2-cstrike-linux.tar.gz -C serverfiles/cstrike && \
    rm amxmodx-1.8.2-cstrike-linux.tar.gz && \
    echo "linux addons/amxmodx/dlls/amxmodx_mm_i386.so" > serverfiles/cstrike/addons/metamod/plugins.ini

# Entrypoint
COPY entrypoint.sh /home/csserver
ENTRYPOINT ./entrypoint.sh
