#!/bin/bash


# JShielder v2.4
# Linux Hardening Script
#
# Jason Soto
# www.jasonsoto.com
# Twitter = @JsiTech

# Tool URL = github.com/jsitech/jshielder

# Based from JackTheStripper Project
# Credits to Eugenia Bahit

# A lot of Suggestion Taken from The Lynis Project
# www.cisofy.com/lynis
# Credits to Michael Boelen @mboelen

#Credits to Center for Internet Security CIS

##############################################################################################################

f_banner(){
echo
echo "

     ██╗███████╗██╗  ██╗██╗███████╗██╗     ██████╗ ███████╗██████╗
     ██║██╔════╝██║  ██║██║██╔════╝██║     ██╔══██╗██╔════╝██╔══██╗
     ██║███████╗███████║██║█████╗  ██║     ██║  ██║█████╗  ██████╔╝
██   ██║╚════██║██╔══██║██║██╔══╝  ██║     ██║  ██║██╔══╝  ██╔══██╗
╚█████╔╝███████║██║  ██║██║███████╗███████╗██████╔╝███████╗██║  ██║
╚════╝ ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═╝
                                                              
Automated Hardening Script for Linux Servers
Developed By Jason Soto @JsiTech "
echo
echo

}

##############################################################################################################

#Check if Running with root user

if [ "$USER" != "root" ]; then
      echo "Permission Denied"
      echo "Can only be run by root"
      exit
else
      clear
      f_banner
fi


menu=""
until [ "$menu" = "10" ]; do

clear
f_banner

echo
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m SELECT YOUR LINUX DISTRIBUTION"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo "1. Ubuntu Server 16.04 LTS"
echo "2. Ubuntu Server 18.04 LTS"
echo "3. Linux CentOS 7 (Coming Soon)"
echo "4. Debian GNU/Linux 8 (Coming Soon)"
echo "5. Debian GNU/Linux 9 (Coming Soon)"
echo "6. Red Hat Linux 7 (Coming Soon)"
echo "7. Exit"
echo

read menu
case $menu in

1)
cd UbuntuServer_16.04LTS/
chmod +x jshielder.sh
./jshielder.sh
;;

2)
cd UbuntuServer_18.04LTS/
chmod +x jshielder.sh
./jshielder.sh
;;

8)
break
;;

*) ;;

esac
done
