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
      clear

      echo "This script is meant to be run once on a new system install"
      echo "Or a system where sftp has not already been configured"
      echo "Running this script multiple times may have undesired consequences"
      echo ""
      echo ""
      echo "We can restrict users to their own directory, or give them access to the whole system"
      read -p "Would you like to chroot/jail your users? [y/n] " jail
      case $jail in 
            y)
            echo ""
            echo ""
		read -p "What is the group name that you want for ftp users? " groupname

			addgroup --system $groupname
			number=`grep -n "Subsystem" /etc/ssh/sshd_config | cut -d ":" -f1`
      		sed -i "${number}d" /etc/ssh/sshd_config
      		echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config
      		echo "Match Group $groupname" >> /etc/ssh/sshd_config
      		echo "ChrootDirectory %h" >> /etc/ssh/sshd_config
      		echo "X11Forwarding no" >> /etc/ssh/sshd_config
      		echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
      		echo "ForceCommand internal-sftp" >> /etc/ssh/sshd_config
      		
      		service ssh restart
                  ;;
            n)
            echo ""
            echo ""
            read -p "What is the group name that you want for ftp users? " groupname
                  addgroup --system $groupname
                  number=`grep -n "Subsystem" /etc/ssh/sshd_config | cut -d ":" -f1`
                  sed -i "${number}d" /etc/ssh/sshd_config
                  echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config
                  echo "Match Group $groupname" >> /etc/ssh/sshd_config
                  echo "X11Forwarding no" >> /etc/ssh/sshd_config
                  echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
                  echo "ForceCommand internal-sftp" >> /etc/ssh/sshd_config
                  
                  service ssh restart
            ;;
      esac
      read -p "Do you wish to add a user? [y/n] " user
      case $user in 
            y)
 apt-get install wget;
    
    apt-get update
    apt-get install php5-gd libssh2-php
echo "First we need to figure out how we're adding an user(s)"
echo ""
echo ""

echo "1) Add a set of users from a file"
echo "2) Add a single user via the terminal"
echo ""
echo ""
echo "The user directories will be placed in /var/www/"
echo "Note: If you add users from a file, each user will be assigned the same password you choose"
echo ""
read -p "What method would you like? [1-2] " choice
echo ""
echo ""
case $choice in
      1)
      echo "I need to know where the list of usernames are"
      echo "the format you enter the username in the file will be the same way"
      echo "their directories are named"
      echo "Unless it is in the same directory as this script,"
      echo "Please enter the absolute path of the directory"
      echo "The format of a directory looks like: "
      echo "/home/username/Downloads"
      echo "Do not put a '/' at the end of your path"
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
      if [ "$loop" = 'y' ];
        then
            for NAME in $NAMES; do
              wget http://wordpress.org/latest.tar.gz
              tar xzvf latest.tar.gz
              mkdir /home/$NAME
              mkdir -p /var/www/$NAME
              mkdir /home/$NAME/public_html 
              mkdir /var/www/$NAME/public_html  

              useradd -d /home/$NAME $NAME
              usermod -G $groupname $NAME
              usermod -s /bin/false $NAME
              echo "$NAME:$passwd" | chpasswd         
          if [ "$jail" = 'y' ];
            then
              chown root:root /home/$NAME
          fi
              chmod 0755 /home/$NAME
              cp -avr wordpress/ /var/www/$NAME/public_html/
              cd /var/www/$NAME/
              chmod -R 755 * 
              chown $NAME:$groupname *
              echo "/var/www/$NAME/public_html /home/$NAME/public_html none bind 0 0" >> /etc/fstab

              echo "<?php" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('DB_NAME', '$NAME');" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('DB_USER', '$NAME');" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('DB_PASSWORD', '$passwd');" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('DB_HOST', 'localhost');" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('DB_CHARSET', 'utf8');" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('DB_COLLATE', '');" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo '$table_prefix  = 'wp_';' >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('WP_DEBUG', false);" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "if ( !defined('ABSPATH') )" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('ABSPATH', dirname(__FILE__) . '/');" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "require_once(ABSPATH . 'wp-settings.php');" >> /var/www/$NAME/public_html/wordpress/wp-config.php

              echo "CREATE DATABASE $NAME;" >> name.sql
              echo "CREATE USER $NAME@localhost IDENTIFIED BY '$passwd';" >> name.sql
              echo "GRANT ALL PRIVILEGES ON $NAME.* TO $NAME@localhost;" >> name.sql
              echo "FLUSH PRIVILEGES;" >> name.sql
              echo "exit" >> name.sql
              mysql -u "root" -p$rootpasswd < name.sql
              
              chown -R $NAME:www-data *
              mkdir /var/www/$NAME/public_html/wordpress/wp-content/uploads
              chown -R :www-data /var/www/$NAME/public_html/wordpress/wp-content/uploads
              rm name.sql
              rm latest.tar.gz
    done
      fi
      ;;
      2)
            clear
            read -p "What is the name of the user you wish to add? " NAME
            echo "Now we need to set the users password."
            echo ""
            echo ""
            read -p "What would you like the user(s) passwords to be? " passwd
              read -p "What is the root MySQL password? " rootpasswd
            echo ""
            read -p "The password you entered was $passwd. Is this correct? [y/n] " loop
      if [ "$loop" = 'y' ]
        then
              mkdir /home/$NAME
              mkdir -p /var/www/$NAME
              mkdir /home/$NAME/public_html 
              mkdir /var/www/$NAME/public_html  

              useradd -d /home/$NAME $NAME
              usermod -G $groupname $NAME
              usermod -s /bin/false $NAME
              echo "$NAME:$passwd" | chpasswd         
          if [ "$jail" = 'y' ];
            then
              chown root:root /home/$NAME
          fi
              chmod 0755 /home/$NAME
              cp -avr wordpress/ /var/www/$NAME/public_html/
              cd /var/www/$NAME/
              chmod -R 755 * 
              chown $NAME:$groupname *
              echo "/var/www/$NAME/public_html /home/$NAME/public_html none bind 0 0" >> /etc/fstab

              echo "<?php" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('DB_NAME', '$NAME');" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('DB_USER', '$NAME');" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('DB_PASSWORD', '$passwd');" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('DB_HOST', 'localhost');" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('DB_CHARSET', 'utf8');" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('DB_COLLATE', '');" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo '$table_prefix  = 'wp_';' >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('WP_DEBUG', false);" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "if ( !defined('ABSPATH') )" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "define('ABSPATH', dirname(__FILE__) . '/');" >> /var/www/$NAME/public_html/wordpress/wp-config.php
              echo "require_once(ABSPATH . 'wp-settings.php');" >> /var/www/$NAME/public_html/wordpress/wp-config.php

              echo "CREATE DATABASE $NAME;" >> name.sql
              echo "CREATE USER $NAME@localhost IDENTIFIED BY '$passwd';" >> name.sql
              echo "GRANT ALL PRIVILEGES ON $NAME.* TO $NAME@localhost;" >> name.sql
              echo "FLUSH PRIVILEGES;" >> name.sql
              echo "exit" >> name.sql
              mysql -u "root" -p$rootpasswd < name.sql
              
              chown -R $NAME:www-data *
              mkdir /var/www/$NAME/public_html/wordpress/wp-content/uploads
              chown -R :www-data /var/www/$NAME/public_html/wordpress/wp-content/uploads
              rm name.sql
      fi
      ;;
esac
            ;;
            n)
            ;;
      esac
      mount -a
      echo "Your sftp server should be set up!"