FROM debian
MAINTAINER Petr Bartunek <petr.bartunek@firma.seznam.cz>

RUN dpkg --add-architecture i386 && \
    apt-get update -y && apt-get upgrade -y && \
    apt-get install -y \
        curl wget procps file tar bzip2 gzip unzip bsdmainutils python3 util-linux \
        ca-certificates binutils bc jq tmux netcat cpio lib32gcc1 lib32stdc++6 libsdl2-2.0-0:i386


RUN groupadd -r linuxGSM && adduser --ingroup linuxGSM csserver
WORKDIR /home/csserver
USER csserver


RUN wget -O linuxgsm.sh https://linuxgsm.sh && chmod +x linuxgsm.sh
RUN ./linuxgsm.sh csserver && yes | ./csserver install

COPY entrypoint.sh /home/csserver
ENTRYPOINT ./entrypoint.sh
