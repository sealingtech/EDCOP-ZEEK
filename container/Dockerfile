FROM centos:latest AS build
RUN yum -y install epel-release
RUN yum -y update && \
        yum -y install sudo supervisor git cmake make gcc gcc-c++ flex bison libpcap-devel openssl-devel python-devel swig zlib-devel GeoIP-devel libpcap gperftools vim-minimal wget kernel-headers kernel-devel kernel hiredis-devel git python-pip cmake librdkafka librdkafka-devel sendmail
RUN pip install bro-pkg
RUN     wget https://www.bro.org/downloads/bro-2.5.5.tar.gz && \
        tar xzf bro-2.5.5.tar.gz && \
        cd bro-2.5.5 && \
        #split the configure and make \
        ./configure && \
        make install 

#here is where you can add all your packages.  Note that some packages require different build tools and therefore may require additional packages not otherwise found.  Some packages require configuration as well.  If this is the case it is best to modify the configurations maps accordingly.
RUN PATH="${PATH}:/usr/local/bro/bin/"; bro-pkg autoconfig && \
    bro-pkg install --force bro/j-gras/bro-af_packet-plugin
    #bro-pkg install --force bro/sethhall/unknown-mime-type-discovery && \
    #bro-pkg install --force bro/apache/metron-bro-plugin-kafka

RUN echo "********Log files for Bro Packages*********" && \
    if [ -d /root/.bro-pkg/logs/ ];then for i in $(find /root/.bro-pkg/logs/); do echo "***Bro Log file: $i"; cat $i; done;fi

FROM centos:latest
RUN yum -y install epel-release
RUN yum -y install supervisor git wget libpcap GeoIP gperftools tcpdump cmake librdkafka iproute sendmail && \
    yum -y clean all && \
    mkdir -p /conf/{plugins,site}
	
COPY --from=build /usr/local/bro/ /usr/local/bro

ADD startbro.sh /startbro.sh
ADD reset-network.sh /reset-network.sh
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENV PATH="/usr/local/bro/bin/:${PATH}"
ENV INTERFACE=eth0

RUN chmod +x /startbro.sh
RUN chmod +x /reset-network.sh

#Used for allowing Bro to run as a regular user
RUN /usr/local/bro/bin/broctl deploy
RUN groupadd -g 2001 bro && \
    useradd -u 2001 -g bro bro -d /usr/local/bro/logs/ && \
    chown -R bro:bro /usr/local/bro/logs/ /usr/local/bro/lib/bro/plugins /usr/local/bro/share/bro/site /usr/local/bro/etc/ 

#Needed to run as a non-privileged user
RUN setcap cap_net_raw,cap_net_admin=eip /usr/local/bro/bin/bro
RUN setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

WORKDIR /usr/local/bro/logs/
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]
