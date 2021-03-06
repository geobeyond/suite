#!/bin/bash
# Script to toggle training mode
# http://boundlessgeo.com/
# Maintainer- Nick Stires

if [ "$(id -u)" != "0" ]; then
 echo "This script must be run as root" 1>&2
 exit 1
fi

if [ "$1" != "on" ] && [ "$1" != "off" ]; then
 echo "Incorrect arguements provided."
 echo "Proper use is: training.sh on/off"
 exit 1
fi

TRAINING_MODE=$1

function pause(){
 read -p "$*"
}

pkill -9 -U tomcat9

if [ "$TRAINING_MODE" == "on" ]; then
  echo "Enabling training mode..."
  cat /etc/tomcat9/web.xml.cors > /etc/tomcat9/web.xml
  
  if psql -lqt -U postgres | cut -d \| -f 1 | grep -qw training; then
    echo "Training DB found, skipping..."
  else
    echo "Creating training DB..."
    createdb -U postgres training
  fi
  
  psql -U postgres -c 'CREATE EXTENSION postgis;' training
  
  unlink /var/opt/boundless/server/geoserver/data
  ln -s /var/opt/boundless/server/geoserver/training-data /var/opt/boundless/server/geoserver/data
elif [ "$TRAINING_MODE" == "off" ]; then
  echo "Disabling training mode..."
  cat /etc/tomcat9/web.xml.default > /etc/tomcat9/web.xml
  
  if psql -lqt -U postgres | cut -d \| -f 1 | grep -qw training; then
    echo "Training DB found, deleting..."
    dropdb -U postgres training
  else
    echo "No training DB found, skipping..."
  fi
  
  unlink /var/opt/boundless/server/geoserver/data
  ln -s /var/opt/boundless/server/geoserver/default-data /var/opt/boundless/server/geoserver/data
fi

service tomcat9 start
