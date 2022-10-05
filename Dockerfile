FROM ubuntu:22.04

ENV VERSION=0.7.1 \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Vienna \
    OS=ubuntu \
    SERVICE=opencanary

LABEL maintainer="somebody@universe.com" \ 
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-type=Git \
      org.label-schema.vcs-url=https://github.com/dlounge/${SERVICE} \
      org.label-schema.maintainer=dlounge

RUN rm /bin/sh && ln -s /bin/bash /bin/sh 
RUN apt-get update && apt-get -y dist-upgrade \
    apt-get install -y --no-install-recommends sudo git build-essential tcpdump nano iproute2 libpcap-dev libffi-dev \
    libssl-dev python3-dev python3-setuptools python3-pip python3-virtualenv iptables inetutils-ping netcat \
	samba samba-common-bin cups && \
	mv /etc/samba/smb.conf /etc/samba/smb.conf_backup
	mkdir -p /opt/opencanary && \
    virtualenv -p python3 /opt/opencanary/virtualenv && \
    source /opt/opencanary/virtualenv/bin/activate && \
    pip3 install --upgrade pip setuptools && \
    pip3 install opencanary && \
    pip3 install scapy pcapy && \
    mkdir -p /opt/opencanary/scripts /data && touch /data/opencanary.log && chmod 666 /data/opencanary.log && \
    apt-get -y purge build-essential libpcap-dev libffi-dev libssl-dev python3-dev && \
    apt-get -y autoremove --purge && \
    rm -rf /var/lib/apt/lists*

#    pip install rdpy && \
# ERROR: Package 'rsa' requires a different Python: 2.7.17 not in '>=3.5, <4'

COPY bin/tini-static-amd64 bin/dockerize /
COPY conf/opencanary.conf /root/.opencanary.conf
COPY scripts/startcanary.sh /opt/opencanary/scripts/startcanary.sh
# COPY scripts/logger.py /opt/opencanary/virtualenv/lib/python3/site-packages/opencanary/logger.py
# COPY scripts/tcpbanner.py /opt/opencanary/virtualenv/lib/python3/site-packages/opencanary/modules/tcpbanner.py
COPY conf/smb.conf /etc/samba/smb.conf
RUN chmod +x /opt/opencanary/scripts/startcanary.sh && chmod 777 /data
RUN chmod +x /tini-static-amd64 /dockerize && \
	ln -s /tini-static-amd64 /tini 

CMD ["/tini","--","/opt/opencanary/scripts/startcanary.sh"]