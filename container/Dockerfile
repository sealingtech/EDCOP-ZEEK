FROM centos:latest AS build
RUN yum -y install epel-release
RUN yum -y update && \
        yum -y install sudo supervisor git cmake make gcc gcc-c++ flex bison libpcap-devel openssl-devel python-devel swig zlib-devel GeoIP-devel libpcap gperftools vim-minimal wget kernel-headers kernel-devel kernel hiredis-devel git python-pip
RUN pip install bro-pkg
RUN     wget https://www.bro.org/downloads/bro-2.5.tar.gz && \
        tar xzf bro-2.5.tar.gz && \
        cd bro-2.5 && \
        #split the configure and make \
        ./configure && \
        make install 

RUN cd /bro-2.5/aux/plugins && \
    make build-redis && \
    cd /bro-2.5/aux/plugins/redis && \
    ./configure && \
    make && \
    make install && \
    cd /
        
        
RUN yum upgrade
RUN     yum -y install --enablerepo=C7.3.1611-base "kernel-devel-uname-r == $(uname -r)" && \
        git clone https://github.com/J-Gras/bro-af_packet-plugin.git && \
        cd bro-af_packet-plugin && \
        ./configure --bro-dist=/bro-2.5 && \
        make && \
        make install && \
        yum -y clean all

FROM centos:latest
RUN yum -y install epel-release
RUN yum -y install supervisor git wget libpcap GeoIP gperftools hiredis python-pip tcpdump && \
    yum -y clean all && \
    mkdir -p /conf/{plugins,site} && \
    pip install bro-pkg && \
    yum -y remove python-pip
COPY --from=build /usr/local/bro/ /usr/local/bro
ADD startbro.sh /startbro.sh
ADD reset-network.sh /reset-network.sh
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ENV PATH="/usr/local/bro/bin/:${PATH}"
RUN chmod +x /startbro.sh
RUN chmod +x /reset-network.sh
#Used for allowing Bro to run as a regular user
RUN /usr/local/bro/bin/broctl deploy
RUN groupadd -g 2001 bro && \
    useradd -u 2001 -g bro bro -d /usr/local/bro/logs/ && \
    chown -R bro:bro /usr/local/bro/logs/ /usr/local/bro/lib/bro/plugins /usr/local/bro/share/bro/site
#Needed to run as a non-privileged user
RUN setcap cap_net_raw,cap_net_admin=eip /usr/local/bro/bin/bro
WORKDIR /usr/local/bro/logs/
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]
