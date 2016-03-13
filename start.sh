#!/bin/bash

# Description
# This script stops a running RPi_Cam interface
# Based on RPI_Cam_Web_Interface installer by Bob Tidey

#Debug enable next 3 lines
exec 5> start.txt
BASH_XTRACEFD="5"
set -x

cd $(dirname $(readlink -f $0))

source ./config.txt

fn_stop ()
{ # This is function stop
   sudo killall raspimjpeg
   sudo killall php
   sudo killall motion
}

#start operation
fn_stop
sudo mkdir -p /dev/shm/mjpeg
sudo chown www-data:www-data /dev/shm/mjpeg
sudo chmod 777 /dev/shm/mjpeg
sleep 1;sudo su -c 'raspimjpeg > /dev/null &' www-data
if [ -e /etc/debian_version ]; then
   sleep 1;sudo su -c "php /var/www/$rpicamdir/schedule.php > /dev/null &" www-data
else
   sleep 1;sudo su -c '/bin/bash' -c "php /var/www/$rpicamdir/schedule.php > /dev/null &" www-data
fi
