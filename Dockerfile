FROM debian:bullseye
MAINTAINER Petr Bartunek <petr.bartunek@firma.seznam.cz>

# Dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update -y && apt-get upgrade -y && \
    apt-get install -y net-tools \
        curl wget less procps file tar bzip2 gzip unzip bsdmainutils iproute2 dnsutils python3 util-linux default-mysql-client \
        ca-certificates binutils bc jq tmux netcat cpio xz-utils lib32gcc-s1 lib32stdc++6 libsdl2-2.0-0:i386 && \
    apt-get clean && apt-get auto-clean && rm -rf /var/lib/apt/lists/*

# User
RUN groupadd -r linuxGSM && adduser --ingroup linuxGSM csserver
WORKDIR /home/csserver
USER csserver

# Installation
COPY --chown=csserver:linuxGSM install.sh /home/csserver/install.sh
RUN ./install.sh

# Configuration
COPY --chown=csserver:linuxGSM cstrike /home/csserver/serverfiles/cstrike
COPY --chown=csserver:linuxGSM configure.sh /home/csserver/configure.sh
RUN ./configure.sh

# Entrypoint
COPY --chown=csserver:linuxGSM entrypoint.sh /home/csserver/entrypoint.sh
ENTRYPOINT ./entrypoint.sh
EXPOSE 27015/udp

# Default settings
ENV SV_PASSWORD TralalaTrololo
ENV GG_ENABLED 0
