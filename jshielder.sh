#!/bin/bash


# JShielder v2.1
# Linux Hardening Script
#
# Jason Soto
# www.jsitech.com
# Twitter = @JsiTech

# Tool URL = www.jsitech.com/jshielder
# us.jsitech.com/jshielder

# Based from JackTheStripper Project
# Credits to Eugenia Bahit

# A lot of Suggestion Taken from The Lynis Project
# www.cisofy.com/lynis
# Credits to Michael Boelen @mboelen

##############################################################################################################

f_banner(){
echo
echo "
     _ ____  _     _      _     _
    | / ___|| |__ (_) ___| | __| | ___ _ __
 _  | \___ \| '_ \| |/ _ \ |/ _  |/ _ \ '__|
| |_| |___) | | | | |  __/ | (_| |  __/ |
 \___/|____/|_| |_|_|\___|_|\__,_|\___|_|


Linux Automated Hardening Script for Linux Servers
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
echo "1. Ubuntu Server 14.04 LTS"
echo "2. Ubuntu Server 16.04 LTS (Testing)"
echo "3. Linux CentOS 6 (Coming Soon)"
echo "4. Linux CentOS 7 (Coming Soon)"
echo "5. Debian GNU/Linux 7 (Coming Soon)"
echo "6. Debian GNU/Linux 8 (Coming Soon)"
echo "7. Red Hat Linux 6 (Coming Soon)"
echo "8. Red Hat Linux 7 (Coming Soon)"
echo "9. Fedora Server 23 (Coming Soon)"
echo "10. Exit"
echo

read menu
case $menu in

1)
cd UbuntuServer_14.04LTS/
chmod +x jshielder.sh
./jshielder.sh
;;

2)
cd UbuntuServer_16.04LTS/
chmod +x jshielder.sh
./jshielder.sh
;;

10)
break
;;

*) ;;

esac
done
