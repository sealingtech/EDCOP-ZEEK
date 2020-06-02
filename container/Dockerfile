
FROM centos:latest AS build

#Version Number of Zeek
ENV VERSION="3.1.3"
RUN yum -y install epel-release dnf-plugins-core
RUN yum -y update && \
        yum config-manager --set-enabled PowerTools && \
        yum -y install sudo supervisor git cmake make gcc gcc-c++ flex bison libpcap-devel openssl-devel python2-devel swig zlib-devel GeoIP-devel libpcap gperftools vim-minimal wget kernel-headers kernel-devel kernel hiredis-devel git python2-pip cmake librdkafka librdkafka-devel sendmail
RUN python2 -m pip install zkg
RUN     wget https://download.zeek.org/zeek-$VERSION.tar.gz && \
        tar xzf zeek-$VERSION.tar.gz && \
        cd zeek-$VERSION && \
        #split the configure and make \
        ./configure && \
        make install 

#here is where you can add all your packages.  Note that some packages require different build tools and therefore may require additional packages not otherwise found.  Some packages require configuration as well.  If this is the case it is best to modify the configurations maps accordingly.
RUN PATH=/usr/local/zeek/bin:"${PATH}"; zkg autoconfig # && \
    #zkg install --force zeek-af_packet-plugin && \
    #zkg install --force zeek/sethhall/unknown-mime-type-discovery && \
    #zkg install --force zeek/apache/metron-zeek-plugin-kafka || true

RUN echo "********Log files for Bro Packages*********" && \
    if [ -d /root/.zkg/logs/ ];then for i in $(find /root/.zkg/logs/); do echo "***Zeek Log file: $i"; cat $i; done;fi

FROM centos:latest
RUN yum -y install epel-release
RUN yum -y install supervisor git wget libpcap GeoIP gperftools tcpdump cmake librdkafka iproute sendmail && \
    yum -y clean all && \
    mkdir -p /conf/{plugins,site}
	
COPY --from=build /usr/local/zeek/ /usr/local/zeek

ADD startbro.sh /startbro.sh
ADD reset-network.sh /reset-network.sh
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENV PATH="/usr/local/bro/bin/:${PATH}"
ENV INTERFACE=eth0

RUN chmod +x /startbro.sh
RUN chmod +x /reset-network.sh

##Used for allowing Zeek to run as a regular user
RUN /usr/local/zeek/bin/zeekctl deploy
RUN groupadd -g 2001 zeek && \
    useradd -u 2001 -g zeek zeek -d /usr/local/zeek/logs/ && \
    chown -R zeek:zeek /usr/local/zeek/logs/ /usr/local/zeek/lib/zeek/plugins /usr/local/zeek/share/zeek/site /usr/local/zeek/etc/ 

#Needed to run as a non-privileged user
RUN setcap cap_net_raw,cap_net_admin=eip /usr/local/zeek/bin/zeek
RUN setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

WORKDIR /usr/local/zeek/logs/
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]
