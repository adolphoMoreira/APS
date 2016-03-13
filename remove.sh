#!/bin/bash

#Debug enable next 3 lines
exec 5> remove.txt
BASH_XTRACEFD="5"
set -x


cd $(dirname $(readlink -f $0))

# Terminal colors
color_red="tput setaf 1"
color_green="tput setaf 2"
color_reset="tput sgr0"

source ./config.txt

fn_stop ()
{ # This is function stop
        sudo killall raspimjpeg
        sudo killall php
        sudo killall motion
        sudo service apache2 stop >dev/null 2>&1
        sudo service nginx stop >dev/null 2>&1
        dialog --title 'Stop message' --infobox 'Stopped.' 4 16 ; sleep 2
}

fn_autostart_disable ()
{
  tmpfile=$(mktemp)
  sudo sed '/#START/,/#END/d' /etc/rc.local > "$tmpfile" && sudo mv "$tmpfile" /etc/rc.local
  # Remove to growing plank lines.
  sudo awk '!NF {if (++n <= 1) print; next}; {n=0;print}' /etc/rc.local > "$tmpfile" && sudo mv "$tmpfile" /etc/rc.local
			  
  # Finally we set owners and permissions all files what we changed.
  sudo chown root:root /etc/rc.local
  sudo chmod 755 /etc/rc.local
  sudo chmod 664 ./config.txt
}


fn_apache_default ()
{
if [ -e /etc/apache2/sites-available/000-default.conf ]; then
   adefault="/etc/apache2/sites-available/000-default.conf"
   subdir="\/html"
else
   adefault="/etc/apache2/sites-available/default"
   subdir=""
fi
tmpfile=$(mktemp)
webport="80"
user=""
passwd=""
sudo awk '/NameVirtualHost \*:/{c+=1}{if(c==1){sub("NameVirtualHost \*:.*","NameVirtualHost *:'$webport'",$0)};print}' /etc/apache2/ports.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/ports.conf
sudo awk '/Listen/{c+=1}{if(c==1){sub("Listen.*","Listen '$webport'",$0)};print}' /etc/apache2/ports.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/ports.conf
sudo awk '/<VirtualHost \*:/{c+=1}{if(c==1){sub("<VirtualHost \*:.*","<VirtualHost *:'$webport'>",$0)};print}' $adefault > "$tmpfile" && sudo mv "$tmpfile" $adefault
sudo sed -i "s/DocumentRoot\ \/var\/www\/.*/DocumentRoot\ \/var\/www$subdir/g" $adefault
sudo awk '/AllowOverride/{c+=1}{if(c==2){sub("AllowOverride.*","AllowOverride None",$0)};print}' /etc/apache2/sites-available/default > "$tmpfile" && sudo mv "$tmpfile" $adefault
sudo service apache2 restart
}


fn_stop
     
dialog --title "Uninstall packages!" --backtitle "$backtitle" --yesno "Do You want uninstall webserver and php packages also?" 6 35
response=$?
case $response in
   0) package=('apache2' 'php5' 'libapache2-mod-php5' 'php5-cli' 'zip' 'nginx' 'apache2-utils' 'php5-fpm' 'php5-common' 'php-apc' 'gpac motion' 'libav-tools');; 
   1) package=('zip' 'gpac motion' 'libav-tools');; 
   255) dialog --title 'Uninstall message' --infobox 'Webserver and php packages not uninstalled.' 4 33 ; sleep 2;;
esac
for i in "${package[@]}"
   do
      if [ $(dpkg-query -W -f='${Status}' "$i" 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
      sudo apt-get remove -y "$i"
      fi
   done
sudo apt-get autoremove -y	  

if [ ! -d ~/media ]; then
  mkdir ~/media
fi
if [ ! "$rpicamdir" == "" ]; then
   sudo mv  /var/www/$rpicamdir/media ~/media
   sudo rm -r /var/www/$rpicamdir
else
   sudo mv /var/www/media ~/media
   sudo rm /var/www/*
fi
sudo rm /etc/sudoers.d/RPI_Cam_Web_Interface
sudo rm /usr/bin/raspimjpeg
sudo rm /etc/raspimjpeg
fn_autostart_disable

sudo mv etc/nginx/sites-available/*default* /etc/nginx/sites-available >/dev/null 2>&1
sudo mv etc/apache2/sites-available/*default* /etc/apache2/sites-available >/dev/null 2>&1
     
if [ $(dpkg-query -W -f='${Status}' "apache2" 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
   fn_apache_default
fi

