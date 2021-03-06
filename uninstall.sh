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
echo "This script is designed to remove a previously added SFTP service via my other scripts"
echo "Please note there may be unexpected consequences, and I am not responsible for you backing up your configs"
echo "If you want to play it safe, back up your /etc/ssh/sshd_config file"
echo ""
echo ""
read -p "What is the group name of the FTP service you wish to remove? " groupname
			sed -i '/Subsystem sftp internal-sftp/d' /etc/ssh/sshd_config #ditto
			sed -i '/Match Group $groupname/d' /etc/ssh/sshd_config
      service ssh restart

      a2dissite students.conf
      a2ensite 000-default.conf
      rm /etc/apache2/sites-available/students.conf
      service apache2 restart

read -p "Would you like to delete all users in $groupname? [y/n] " dieusers
case $dieusers in 
		y)
        umount -a
      	grep "$groupname" /etc/group | cut -d ':' -f4 | cut -d ',' -f1- --output-delimiter=$'\n' > deletedusers.txt
      	file="deletedusers.txt"
      	NAMES="$(< $file)"
        read -p "What is the mySQL root password? " rootpasswd
      	for NAME in $NAMES; do
      			deluser --remove-home $NAME
            rm -rf /var/www/$NAME
            echo "drop database $NAME;" >> name.sql
            echo "drop user '$NAME'@'localhost';" >> name.sql
            echo "FLUSH PRIVILEGES;" >> name.sql
            echo "exit" >> name.sql
            mysql -u "root" -p$rootpasswd < name.sql
            rm name.sql
			done

		echo "A list of deleted users is located at $file"
		read -p "Would you like to remove $file? [y/n] " choice
		if [ "$choice" = 'y' ]
			then
			rm $file
		fi
        ;;
        n)
        ;;
esac        
groupdel $groupname