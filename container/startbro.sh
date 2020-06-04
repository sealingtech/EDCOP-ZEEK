#!/bin/bash
#
# Starts a Docker instance of the Bro IDS and tunes some settings for high throughput

###############################
#Edit these varibles as needed#
###############################
#CONTAINERINT is the interface within the Container
CONTAINERINT=$INTERFACE

sed -i 's/${INTERFACE}/'$INTERFACE' /g' /usr/local/zeek/etc/node.cfg

sudo chgrp $USER $(zeek-config --site_dir) $(zeek-config --plugin_dir)
sudo chmod g+rwX $(zeek-config --site_dir) $(zeek-config --plugin_dir)

sudo chgrp $USER $(zeek-config --site_dir) $(zeek-config --plugin_dir)
sudo chmod g+rwX $(zeek-config --site_dir) $(zeek-config --plugin_dir)

sed -i "/const fanout_id/c\ \tconst fanout_id = $RANDOM &redef;" /usr/local/zeek/lib/zeek/plugins/Zeek_AF_Packet/scripts/init.zeek

/usr/local/zeek/bin/zeek -i $CONTAINERINT -e 'redef LogAscii::use_json=T;'
