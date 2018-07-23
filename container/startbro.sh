#!/bin/bash
#
# Starts a Docker instance of the Bro IDS and tunes some settings for high throughput

###############################
#Edit these varibles as needed#
###############################
#CONTAINERINT is the interface within the Container
CONTAINERINT="net0"

sed -i "/const fanout_id/c\ \tconst fanout_id = $RANDOM &redef;" /usr/local/bro/lib/bro/plugins/Bro_AF_Packet/scripts/init.bro
#########Removing this to allow Kubernetes to configure this##############
#Pins cpus 0 - 5 by default, should be changed depending on your NUMA node setup 
#sh -c "printf '[logger] \ntype=logger \nhost=localhost \n# \n[manager] \ntype=manager \nhost=localhost \n# \n[proxy-1] \ntype=proxy \nhost=localhost \n# \n[worker-1] \ntype=worker \nhost=localhost \ninterface=af_packet::$CONTAINERINT \nlb_method=custom \nlb_procs=6 \npin_cpus=0,1,2,3,4,5' > /usr/local/bro/etc/node.cfg"
/usr/local/bro/bin/bro -i $CONTAINERINT -e 'redef LogAscii::use_json=T;'
