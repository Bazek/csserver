FROM debian
MAINTAINER Petr Bartunek <petr.bartunek@firma.seznam.cz>

# Dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update -y && apt-get upgrade -y && \
    apt-get install -y \
        curl wget less procps file tar bzip2 gzip unzip bsdmainutils python3 util-linux \
        ca-certificates binutils bc jq tmux netcat cpio lib32gcc1 lib32stdc++6 libsdl2-2.0-0:i386 && \
    apt-get clean && apt-get auto-clean && rm -rf /var/lib/apt/lists/*

# User
RUN groupadd -r linuxGSM && adduser --ingroup linuxGSM csserver
WORKDIR /home/csserver
USER csserver

# Installation
COPY --chown=csserver install.sh /home/csserver/install.sh
RUN ./install.sh

# Configuration
COPY --chown=csserver cstrike /home/csserver/serverfiles/cstrike
COPY --chown=csserver configure.sh /home/csserver/configure.sh
RUN ./configure.sh

# Entrypoint
COPY --chown=csserver entrypoint.sh /home/csserver/entrypoint.sh
ENTRYPOINT ./entrypoint.sh
