#!/bin/bash
#
# This script configures WordPress file permissions based on recommendations
# from http://codex.wordpress.org/Hardening_WordPress#File_permissions
#
# Forked from https://gist.github.com/Adirael/3383404
# 
# Authors:
# Michael Conigliaro <mike [at] conigliaro [dot] org>
# Kyle Skrinak kyleskrinak
# Ruben Barkow-Kuder
set -e

WP_ROOT=$1  # <-- wordpress root directory
WP_OWNER=$2 # <-- wordpress owner (default: www-data)
WP_GROUP=$3 # <-- wordpress group (default: www-data)
WWW_GROUP=$4 # <-- webserver group (default: www-data)

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  echo -e "usage:\n  $0 [wordpress root directory] [wordpress owner] [wordpress group] [webserver group]"
  exit
fi

if [[ ${#1} -eq 0 ]]
then
  WP_ROOT="/var/www/html/wordpress"
  echo "No path arguments supplied. Using default path $WP_ROOT"
fi

if [[ ! -d "$WP_ROOT/wp-admin" ]]
then
  echo "$WP_ROOT is not a valid path. Bye."
  exit 1
fi

if [[ ${#2} -eq 0 ]]
then
  WP_OWNER="www-data"
  echo "No wordpress owner supplied. Using default wordpress owner $WP_OWNER"
fi

if [[ ${#WP_GROUP} -eq 0 ]]
then
  WP_GROUP="www-data"
  echo "No wordpress group supplied. Using default wordpress group $WP_GROUP"
fi

if [[ ${#4} -eq 0 ]]
then
  WWW_GROUP="$WP_GROUP"
  echo "No webserver group supplied. Using wordpress group as webserver group (this is usually the expected scenario)"
fi

# Check the arguments before proceeding

# If user, returns number. Not a user, no value
ISUSER=$(id -u $WP_OWNER 2> /dev/null)
# Is group in the group file? If so, returns line
ISGRP=$(egrep -i $WP_GROUP /etc/group)
WWW_ISGRP=$(egrep -i $WWW_GROUP /etc/group)

if [[ $ISUSER -eq 0 ]]
  then
    echo "$WP_OWNER is not a user"
    exit 1
fi

if [[ ${#ISGRP} -eq 0 ]]
  then
    echo "$WP_GROUP is not a group"
    exit 1
fi

if [[ ${#WWW_ISGRP} -eq 0 ]]
  then
    echo "$WWW_GROUP is not a group"
    exit 1
fi

echo "Proceeding with the following assumptions:"
echo " 1. WP_ROOT: $WP_ROOT"
echo " 2. WP_OWNER: $WP_OWNER"
echo " 2. WP_GROUP: $WP_GROUP"
echo -e " 3. WWW_GROUP: $WWW_GROUP\n"

while true; do
    read -p "Looks good [Y/n]? " -n 1 -r -e yn
    case "${yn:-Y}" in
        [YyZzOoJj]* ) echo; break ;;
        [Nn]* ) [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 ;; # handle exits from shell or function but don't exit interactive shell
        * ) echo "Please answer yes or no.";;
    esac
done
echo "And we are off!"

# reset to safe defaults
echo "Reseting permissions to safe defaults"

set -x
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
