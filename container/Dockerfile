#https://www.bro.org/sphinx/components/bro-plugins/redis/README.html
# https://www.bro.org/sphinx/components/bro-plugins/README.html
FROM centos:latest
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
        
ENV PATH="${PATH}:/usr/local/bro/bin/"        
RUN yum upgrade
RUN     yum -y install --enablerepo=C7.3.1611-base "kernel-devel-uname-r == $(uname -r)" && \
        git clone https://github.com/J-Gras/bro-af_packet-plugin.git && \
        cd bro-af_packet-plugin && \
        ./configure --bro-dist=/bro-2.5 && \
        make && \
        make install && \
        yum -y clean all
ADD startbro.sh /startbro.sh
ADD reset-network.sh /reset-network.sh
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod +x /startbro.sh
RUN chmod +x /reset-network.sh
#Used for allowing Bro to run as a regular user
setcap cap_net_raw,cap_net_admin=eip /usr/local/bro/bin/bro
RUN /usr/local/bro/bin/broctl deploy
WORKDIR /usr/local/bro/logs/
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]
