#!/bin/bash
#
# This script configures WordPress file permissions based on recommendations
# from https://wordpress.org/support/article/hardening-wordpress/#file-permissions
#
# Forked from https://gist.github.com/Adirael/3383404
# 
# Authors:
# Michael Conigliaro <mike [at] conigliaro [dot] org>
# Kyle Skrinak
# Ruben Barkow-Kuder

#### SETTINGS
# default values, if no arguments are given to the script call:
DEFAULT_WP_ROOT="/var/www/html/wordpress" # <-- wordpress root directory
DEFAULT_WP_OWNER="www-data"  # <-- wordpress owner
DEFAULT_WP_GROUP="www-data"  # <-- wordpress group
DEFAULT_WWW_GROUP="$DEFAULT_WP_GROUP" # <-- webserver group (usually the same as WP_GROUP)
# optional if you don't want a confirmation:
#NO_CONFIRM=1
# optional be verbose on changing of user/groups:
VERBOSE="-v"

if [[ "$1" == "-y" ]]; then
  NO_CONFIRM=1
  shift
fi

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  echo -e "usage:\n  $0 [-y] [wordpress root directory] [wordpress owner] [wordpress group] [webserver group]"
  echo "  -y dont ask for confirmation"
  exit
fi

WP_ROOT=$(echo "$1"| sed 's/\/*$//g')
WP_OWNER=$2
WP_GROUP=$3
WWW_GROUP=$4

if [[ ${#1} -eq 0 ]]; then
  WP_ROOT="$DEFAULT_WP_ROOT"
  echo "No path arguments supplied. Using default path $DEFAULT_WP_ROOT"
fi

if [[ ! -d "$WP_ROOT/wp-admin" ]]; then
  echo "$WP_ROOT is not a valid path. Bye."
  exit 1
fi

if [[ ! -f "$WP_ROOT/wp-config.php" ]]; then
  echo "$WP_ROOT/wp-config.php is missing. Bye."
  exit 1
fi

if [[ ${#WP_OWNER} -eq 0 ]]; then
  WP_OWNER="$DEFAULT_WP_OWNER"
  echo "No wordpress owner supplied. Using default wordpress owner $DEFAULT_WP_OWNER"
fi

if [[ ${#WP_GROUP} -eq 0 ]]; then
  WP_GROUP="$DEFAULT_WP_GROUP"
  echo "No wordpress group supplied. Using default wordpress group $DEFAULT_WP_GROUP"
fi

if [[ ${#WWW_GROUP} -eq 0 ]]; then
  WWW_GROUP="$DEFAULT_WWW_GROUP"
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
echo "WP_ROOT=$WP_ROOT"
echo "WP_OWNER=$WP_OWNER"
echo "WP_GROUP=$WP_GROUP"
echo -e "WWW_GROUP=$WWW_GROUP\n"

if [[ "$NO_CONFIRM" != "1" ]]; then
  while true; do
      read -p "Looks good [Y/n]? " -n 1 -r -e yn
      case "${yn:-Y}" in
          [YyZzOoJj]* ) echo; break ;;
          [Nn]* ) [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 ;; # handle exits from shell or function but don't exit interactive shell
          * ) echo "Please answer yes or no.";;
      esac
  done
fi

PS4="# "; set -x
: ::: Change owner and group. Put this line in a cronjob if you plan to both upload by Wordpress, which is usually the user www-data, and autodeploy by WP_OWNER regularly:
find ${WP_ROOT} -not '(' -user  ${WP_OWNER} -a -group ${WP_GROUP} ')' -exec chown $VERBOSE ${WP_OWNER}:${WP_GROUP} {} \;

: ::: Resetting permissions to safe defaults
find ${WP_ROOT} -type d -not -perm 755 -exec chmod 755 {} \;
find ${WP_ROOT} -type f -not -perm 644 -exec chmod 644 {} \;

: ::: Allowing wordpress to manage wp-config.php, but prevent world access

chgrp ${WWW_GROUP} ${WP_ROOT}/wp-config.php
chmod 660 ${WP_ROOT}/wp-config.php

: ::: Allowing wordpress to manage wp-content

find ${WP_ROOT}/wp-content -not -group ${WWW_GROUP} -exec chgrp $VERBOSE ${WWW_GROUP} {} \;
find ${WP_ROOT}/wp-content -type d -not -perm 775 -exec chmod 775 {} \;
find ${WP_ROOT}/wp-content -type f -not -perm 664 -exec chmod 664 {} \;
