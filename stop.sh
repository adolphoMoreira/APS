#!/bin/bash

# Description
# This script stops a running RPi_Cam interface
# Based on RPI_Cam_Web_Interface installer by Bob Tidey


#Debug enable next 3 lines
exec 5> stop.txt
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

#stop operation
fn_stop
