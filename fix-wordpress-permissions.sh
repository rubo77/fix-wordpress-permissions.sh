#!/bin/bash
#
# This script configures WordPress file permissions based on recommendations
# from http://codex.wordpress.org/Hardening_WordPress#File_permissions
#
# Authors:
# Michael Conigliaro <mike [at] conigliaro [dot] org>
# Kyle Skrinak kyleskrinak
# 

WP_ROOT=$1  # <-- wordpress root directory
WP_OWNER=$2 # <-- wordpress owner
WP_GROUP=$3 # <-- wordpress group
WWW_GROUP=$3 # <-- webserver group


if [[ ${#1} -eq 0 ]]
then
  echo "No path arguments supplied. Bye."
  exit 1
fi

if [[ ! -d $1/wp-admin ]]
then
  echo "$1 is not a valid path. Bye."
  exit 1
fi

# Check the arguments before proceeding

# If user, returns number. Not a user, no value
ISUSER=$(id -u $2 2> /dev/null)
# Is group in the group file? If so, returns line
ISGRP=$(egrep -i $3 /etc/group)

if [[ $ISUSER -eq 0 ]]
  then
    echo "$2 is not a user"
    exit 1
fi

if [[ ${#ISGRP} -eq 0 ]]
  then
    echo "$3 is not a group"
    exit 1
fi

echo "Proceeding with the following assumptions:"
echo " 1. WP_ROOT: $WP_ROOT"
echo " 2. WP_OWNER: $WP_OWNER"
echo " 2. WP_GROUP: $WP_GROUP\n"
echo "Look Good [y/n]?"
read yn
case $yn in
  [Yy]* ) echo "And we are off!";;
  [Nn]* ) return;;
  * ) echo "That's not yes or no." && return;;
esac

# reset to safe defaults
echo "Reseting permissions to safe defaults"

find ${WP_ROOT} -exec chown ${WP_OWNER}:${WP_GROUP} {} \;
find ${WP_ROOT} -type d -exec chmod 755 {} \;
find ${WP_ROOT} -type f -exec chmod 644 {} \;

# allow wordpress to manage wp-config.php (but prevent world access)
echo "Allowing wordpress to manage wp-config.php (but prevent world access)"

chgrp ${WWW_GROUP} ${WP_ROOT}/wp-config.php
chmod 660 ${WP_ROOT}/wp-config.php

# allow wordpress to manage wp-content
echo "Allowing wordpress to manage wp-content"

find ${WP_ROOT}/wp-content -exec chgrp ${WWW_GROUP} {} \;
find ${WP_ROOT}/wp-content -type d -exec chmod 775 {} \;
find ${WP_ROOT}/wp-content -type f -exec chmod 664 {} \;
