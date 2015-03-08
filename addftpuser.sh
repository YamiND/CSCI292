#!/bin/bash
#
#     Copyright (C) 2015  Tyler Postma (Yami)
#
#     This program is free software; you can redistribute it and/or
#     modify it under the terms of the GNU General Public License
#     as published by the Free Software Foundation; either version 2
#     of the License, or (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software
#     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
fi
echo "This script is meant to easily add FTP user accounts"
echo "First we need to figure out how we're adding an user(s)"
echo ""
echo ""
echo "1) Add a set of users from a file"
echo "2) Add a single user via the terminal"
echo ""
echo ""
echo "Note: If you add users from a file, each user will be assigned the same password"
read -p "What method would you like? [1-2] " choice
echo ""
echo ""
echo "Second, we need to assign these users to a group"
read -p "What is the group called? " groupname
echo ""
echo ""
echo "Third, we need to decide if we're going to 'jail' our users"
echo "Jailing/Chrooting is the process of limiting our users to their own directories"
echo ""
read -p "Would you like to Jail/Chroot your users? [y/n] " jail
case $choice in
	1)
	echo "I need to know where the list of usernames are"
	echo "the format you enter the username in the file will be the same way"
	echo "their directories are named"
	echo "Unless it is in the same directory as this script,"
	echo "Please enter the absolute path of the directory"
	echo "The format of a directory looks like: "
	echo "/home/username/Downloads"
	echo ""
	read -p "What is the directory the text file is located in? " dir
	echo ""
	echo "What is the file called?"
	read -p "Please enter the full text file name: "  file
	NAMES="$(< $dir/$file)"
  echo ""
  echo ""
  echo "Now we need to set the users passwords."
  echo "For simplicity, all passwords will be the same"
  echo ""
  echo ""
  read -p "What would you like the user(s) passwords to be? " passwd
  read -p "What is the root MySQL password? " rootpasswd
  echo "The file name and location you gave me was $dir/$file"
  echo "The password you gave me was $passwd"
	read -p "Is this correct? [y/n] " loop
    apt-get install wget;
    wget http://wordpress.org/latest.tar.gz
    tar xzvf latest.tar.gz
    apt-get update
    apt-get install php5-gd libssh2-php


	if [ "$loop" = 'y' ]
        then
      		for NAME in $NAMES; do
      			useradd -d /var/www/$NAME $NAME
            echo "$NAME:$passwd" | chpasswd
      			mkdir -p /var/www/$NAME
      			usermod -G $groupname $NAME
          if [ "$jail" = 'y' ];
            then
      			chown root:root /var/www/$NAME
          fi
      			chmod 755 /var/www/$NAME
      			cd /var/www/$NAME
      			mkdir public_html
            mkdir wordpress
      			chown $NAME:$groupname *
            rsync -avP wordpress /var/www/$NAME/public_html/wordpress/
            cd /var/www/$NAME/public_html/wordpress/

          echo "<?php" >> wp-config.php
          echo "define('DB_NAME', '$NAME');" >> wp-config.php
          echo "define('DB_USER', '$NAME');" >> wp-config.php
          echo "define('DB_PASSWORD', '$passwd');" >> wp-config.php
          echo "define('DB_HOST', 'localhost');" >> wp-config.php
          echo "define('DB_CHARSET', 'utf8');" >> wp-config.php
          echo "define('DB_COLLATE', '');" >> wp-config.php
          echo "$table_prefix  = 'wp_';" >> wp-config.php
          echo "define('WP_DEBUG', false);" >> wp-config.php
          echo "if ( !defined('ABSPATH') )" >> wp-config.php
          echo "define('ABSPATH', dirname(__FILE__) . '/');" >> wp-config.php
          echo "require_once(ABSPATH . 'wp-settings.php');" >> wp-config.php

          echo "CREATE DATABASE $NAME;" >> name.sql
          echo "CREATE USER $NAME@localhost IDENTIFIED BY '$passwd';" >> name.sql
          echo "GRANT ALL PRIVILEGES ON $NAME.* TO $NAME@localhost;" >> name.sql
          echo "FLUSH PRIVILEGES;" >> name.sql
          echo "exit" >> name.sql
          mysql -u root -p $rootpasswd < name.sql
          chown -R $NAME:www-data *
          mkdir /var/www/$NAME/public_html/wordpress/wp-content/uploads
          chown -R :www-data /var/www/html/wp-content/uploads
          rm name.sql
			done
   
   
     

	fi
	;;
	2)
		clear
		read -p "What is the name of the user you wish to add? " NAME
    echo ""
    echo ""
    read -p "What would you like the user(s) passwords to be? " passwd
    echo "The password you gave me was $passwd"
		echo ""
        mkdir -p /var/www/$NAME
        useradd -d /var/www/$NAME $NAME
        echo "$NAME:$passwd" | chpasswd
        usermod -G $groupname $NAME
        if [ "$jail" = 'y' ];
          then
          chown root:root /var/www/$NAME
        fi
        chmod 755 /var/www/$NAME
        cd /var/www/$NAME
        mkdir public_html
        mkdir wordpress
        chown $NAME:$groupname *
        rsync -avP wordpress /var/www/$NAME/public_html/wordpress/
        cd /var/www/$NAME/public_html/wordpress/

          echo "<?php" >> wp-config.php
          echo "define('DB_NAME', '$NAME');" >> wp-config.php
          echo "define('DB_USER', '$NAME');" >> wp-config.php
          echo "define('DB_PASSWORD', '$passwd');" >> wp-config.php
          echo "define('DB_HOST', 'localhost');" >> wp-config.php
          echo "define('DB_CHARSET', 'utf8');" >> wp-config.php
          echo "define('DB_COLLATE', '');" >> wp-config.php
          echo "$table_prefix  = 'wp_';" >> wp-config.php
          echo "define('WP_DEBUG', false);" >> wp-config.php
          echo "if ( !defined('ABSPATH') )" >> wp-config.php
          echo "define('ABSPATH', dirname(__FILE__) . '/');" >> wp-config.php
          echo "require_once(ABSPATH . 'wp-settings.php');" >> wp-config.php

          echo "CREATE DATABASE $NAME;" >> name.sql
          echo "CREATE USER $NAME@localhost IDENTIFIED BY '$passwd';" >> name.sql
          echo "GRANT ALL PRIVILEGES ON $NAME.* TO $NAME@localhost;" >> name.sql
          echo "FLUSH PRIVILEGES;" >> name.sql
          echo "exit" >> name.sql
          mysql -u $NAME -p $passwd < name.sql
          chown -R $NAME:www-data *
          mkdir /var/www/$NAME/public_html/wordpress/wp-content/uploads
          chown -R :www-data /var/www/html/wp-content/uploads
	;;
esac
echo "Your FTP user(s) should be all set up!"