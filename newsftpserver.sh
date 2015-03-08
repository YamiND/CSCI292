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
      read -p "Would you like to chroot/jail your users? [y/n] " restrict
      case $restrict in 
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
      
      echo "The file name and location you gave me was $dir/$file"
      echo "The password you gave me was $passwd"
      read -p "Is this correct? [y/n] " loop
      if [ "$loop" = 'y' ]
        then
                  for NAME in $NAMES; do
                        useradd -d /var/www/$NAME $NAME
                        echo "$NAME:$passwd" | chpasswd
                        mkdir -p /var/www/$NAME
                        usermod -G $groupname $NAME
            if [ "$restrict" = 'y' ];
                  then
                        chown root:root /var/www/$NAME
            fi
                        chmod 755 /var/www/$NAME
                        cd /var/www/$NAME
                        mkdir public_html
                        chown $NAME:$groupname *
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
            echo ""
            read -p "The password you entered was $passwd. Is this correct? [y/n] " loop
      if [ "$loop" = 'y' ]
        then
            mkdir -p /var/www/$NAME
            useradd -d /var/www/$NAME $NAME
            echo "$NAME:$passwd" | chpasswd
            usermod -G $groupname $NAME
            if [ "$restrict" = 'y' ];
                  then
                  chown root:root /var/www/$NAME
            fi
            chmod 755 /var/www/$NAME
            cd /var/www/$NAME
            mkdir public_html
            chown $NAME:$groupname *
            clear
      fi
      ;;
esac
            ;;
            n)
            ;;
      esac
      echo "Your sftp server should be set up!"