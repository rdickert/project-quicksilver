#!/bin/bash

DRUPAL_PATH=${1%/}
DRUPAL_USER=${2}
APACHE_GROUP="www-data"
HELP="\nHELP: This script is used to fix permissions of a drupal installation\nyou need to provide the following arguments:\n\t 1) path to your drupal installation\n\t 2) Username of the user that you want to give files/directories ownership\nNote: \"www-data\" (apache default) is assumed as the group the server is belonging to, if this is different you need to modify it manually by editing this script\n\nUsage: (sudo) bash ${0##*/} drupal_path user_name\n"

if [ -z "${DRUPAL_PATH}" ] || [ ! -d "${DRUPAL_PATH}/sites" ] || [ ! -f "${DRUPAL_PATH}/modules/system/system.module" ]; then
echo "Please provide a valid drupal path"
echo -e $HELP
exit
fi

if [ -z "${DRUPAL_USER}" ] || [ "`id -un ${DRUPAL_USER} 2> /dev/null`" != "${DRUPAL_USER}" ]; then
echo "Please provide a valid user"
echo -e $HELP
exit
fi


cd $DRUPAL_PATH
echo -e "Changing ownership of all contents of \"${DRUPAL_PATH}\" :\n user => \"${DRUPAL_USER}\" \t group => \"${APACHE_GROUP}\"\n"
chown -R $DRUPAL_USER:$APACHE_GROUP .

#Change to make /sites/* owned by web server. If you don't do this, the gui module installer does not work.
echo -e "Changing ownership of \"${DRUPAL_PATH}\"/sites/* for GUI module installer compatibility :\n user => \"${APACHE_GROUP}\" \t group => \"${APACHE_GROUP}\"\n"
# chown $APACHE_GROUP:$APACHE_GROUP sites/
chown -R $APACHE_GROUP:$APACHE_GROUP $DRUPAL_PATH/sites/*
chown $DRUPAL_USER:$APACHE_GROUP $DRUPAL_PATH/sites/default/settings.php

echo "Changing permissions of all directories inside \"${DRUPAL_PATH}\" to \"rwxr-x---\"..."
find . -type d -exec chmod u=rwx,g=rx,o= '{}' \;

echo -e "Changing permissions of all files inside \"${DRUPAL_PATH}\" to \"rw-r-----\"...\n"
find . -type f -exec chmod u=rw,g=r,o= '{}' \;

echo "Changing permissions of \"files\" directories in \"${DRUPAL_PATH}/sites\" to \"rwxrwx---\"..."
cd $DRUPAL_PATH/sites
find . -type d -name files -exec chmod ug=rwx,o= '{}' \;
echo "Changing permissions of all files inside all \"files\" directories in \"${DRUPAL_PATH}/sites\" to \"rw-rw----\"..."
echo "Changing permissions of all directories inside all \"files\" directories in \"${DRUPAL_PATH}/sites\" to \"rwxrwx---\"..."
for d in ./*/files
do
   find $d -type d -exec chmod ug=rwx,o= '{}' \;
   find $d -type f -exec chmod ug=rw,o= '{}' \;
done
true