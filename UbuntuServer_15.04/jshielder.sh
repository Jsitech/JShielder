#!/bin/bash


# JShielder v2.0
# Deployer for Ubuntu Server 15.04 LTS
#
# Jason Soto
# www.jsitech.com
# Twitter = @JsiTech

# Based from JackTheStripper Project
# Credits to Eugenia Bahit


source helpers.sh
##############################################################################################################

f_banner(){
echo
echo "
     _ ____  _     _      _     _
    | / ___|| |__ (_) ___| | __| | ___ _ __
 _  | \___ \| '_ \| |/ _ \ |/ _  |/ _ \ '__|
| |_| |___) | | | | |  __/ | (_| |  __/ |
 \___/|____/|_| |_|_|\___|_|\__,_|\___|_|


For Ubuntu Server 15.04
By Jason Soto "
echo
echo

}

##############################################################################################################

# Check if running with root User

clear
f_banner


check_root() {
if [ "$USER" != "root" ]; then
      echo "Permission Denied"
      echo "Can only be run by root"
      exit
else
      clear
      f_banner
      cat templates/texts/welcome
fi
}

##############################################################################################################

# Configure Hostname
config_host() {
echo -e "\e[93m[?]\e[00m ¿Do you Wish to Set a HostName? (y/n): "; read config_host
if [ "$config_host" == "y" ]; then
    serverip=$(__get_ip)
    echo " Type a Name to Identify this server"
    echo -n " (For Example: myserver) "; read host_name
    echo -n " ¿Type Domain Name? "; read domain_name
    echo $host_name > /etc/hostname
    hostname -F /etc/hostname
    echo "127.0.0.1    localhost.localdomain      localhost" >> /etc/hosts
    echo "$serverip    $host_name.$domain_name    $host_name" >> /etc/hosts
fi
    say_done
}

##############################################################################################################


# Configure TimeZone
config_timezone(){
   clear
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m We will now Configure the TimeZone"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo ""
   sleep 10
   dpkg-reconfigure tzdata
   say_done
}

##############################################################################################################

# Update System
update_system(){
   clear
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m Updating the System"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo ""
   apt-get update
   apt-get upgrade -y
   say_done
}

##############################################################################################################

# Create Privileged User
admin_user(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m We will now Create a New Privileged User"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -e "\e[93m[?]\e[00m Type the new username: "; read username
    adduser $username
    usermod -a -G sudo $username
    say_done
}

##############################################################################################################
# Instruction to Generate RSA Keys
rsa_keygen(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Instructions to Generate an RSA KEY PAIR"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    serverip=$(__get_ip)
    echo " *** IF YOU DONT HAVE A PUBLIC RSA KEY, GENERATE ONE ***"
    echo "     Follow the Instruction and Hit Enter When Done"
    echo "     To receive a new Instruction"
    echo " "
    echo "    RUN THE FOLLOWING COMMANDS"
    echo -n "     a) ssh-keygen -t rsa -b 4096 "; read foo1
    echo -n "     b) cat /home/$username/.ssh/id_rsa.pub >> /home/$username/.ssh/authorized_keys: "; read foo2
    say_done
}
##############################################################################################################

# Move the Generated Public Key
rsa_keycopy(){
    echo " Run the Following Command to copy the Key"
    echo " Press ENTER when done "
    echo " ssh-copy-id -i $HOME/.ssh/id_rsa.pub $username@$serverip "
    say_done
}
##############################################################################################################

# Secure SSH
secure_ssh(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Securing SSH"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " Securing SSH..."
    spinner
    sed s/USERNAME/$username/g templates/sshd_config > /etc/ssh/sshd_config; echo "OK"
    chattr -i /home/$username/.ssh/authorized_keys
    service ssh restart
    say_done
}

##############################################################################################################

# Set IPTABLES Rules
set_iptables(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Setting IPTABLE RULES"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " Setting Iptables Rules..."
    spinner
    sh templates/iptables.sh
    cp templates/iptables.sh /etc/init.d/
    ln -s /etc/init.d/iptables.sh /etc/rc2.d/S99iptables.sh
    say_done
}

##############################################################################################################


# Install fail2ban
# To Remove a Fail2Ban rule use:
# iptables -D fail2ban-ssh -s IP -j DROP
install_sendmail(){
      clear
      f_banner
      echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
      echo -e "\e[93m[+]\e[00m Installing SendMail"
      echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
      echo ""
      apt-get install sendmail
      say_done
}

##############################################################################################################

# Install, Configure and Optimize MySQL
install_secure_mysql(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing, Configuring and Optimizing MySQL"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt-get install mysql-server
    echo -n " configuring MySQL............ "
    cp templates/mysql /etc/mysql/my.cnf; echo " OK"
    mysql_secure_installation
    service mysql restart
    say_done
}

##############################################################################################################

# Install Apache
install_apache(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Installing Apache Web Server"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  apt-get install apache2
  say_done
}

##############################################################################################################

# Install, Configure and Optimize PHP
install_secure_php(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing, Configuring and Optimizing PHP"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt-get install php5 php5-cli php-pear
    apt-get install php5-mysql python-mysqldb
    echo -n " Replacing php.ini..."
    cp templates/php /etc/php5/apache2/php.ini; echo " OK"
    cp templates/php /etc/php5/cli/php.ini; echo " OK"
    service apache2 restart
    say_done
}

##############################################################################################################


# Install ModSecurity
install_modsecurity(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing ModSecurity"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt-get install libxml2 libxml2-dev libxml2-utils
    apt-get install libaprutil1 libaprutil1-dev
    apt-get install libapache2-mod-security2
    service apache2 restart
    say_done
}

##############################################################################################################
# Configure OWASP for ModSecurity
set_owasp_rules(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Setting UP OWASP Rules for ModSecurity"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""

    for archivo in /usr/share/modsecurity-crs/base_rules/*
        do ln -s $archivo /usr/share/modsecurity-crs/activated_rules/
    done

    for archivo in /usr/share/modsecurity-crs/optional_rules/*
        do ln -s $archivo /usr/share/modsecurity-crs/activated_rules/
    done
    spinner
    echo "OK"

    sed s/SecRuleEngine\ DetectionOnly/SecRuleEngine\ On/g /etc/modsecurity/modsecurity.conf-recommended > salida
    mv salida /etc/modsecurity/modsecurity.conf

    echo 'SecServerSignature "AntiChino Server 1.0.4 LS"' >> /usr/share/modsecurity-crs/modsecurity_crs_10_setup.conf
    echo 'Header set X-Powered-By "Plankalkül 1.0"' >> /usr/share/modsecurity-crs/modsecurity_crs_10_setup.conf
    echo 'Header set X-Mamma "Mama mia let me go"' >> /usr/share/modsecurity-crs/modsecurity_crs_10_setup.conf

    a2enmod headers
    service apache2 restart
    say_done
}

##############################################################################################################
# Configure and optimize Apache
secure_optimize_apache(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Optimizing Apache"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    cp templates/apache /etc/apache2/apache2.conf
    echo " -- Enabling ModRewrite"
    spinner
    a2enmod rewrite
    service apache2 restart
    say_done
}

##############################################################################################################

# Install ModEvasive
install_modevasive(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing ModEvasive"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " Type Email to Receive Alerts "; read inbox
    apt-get install libapache2-mod-evasive
    mkdir /var/log/mod_evasive
    chown www-data:www-data /var/log/mod_evasive/
    sed s/MAILTO/$inbox/g templates/mod-evasive > /etc/apache2/mods-available/mod-evasive.conf
    service apache2 restart
    say_done
}

##############################################################################################################
# Install Mod_qos/spamhaus
install_qos_spamhaus(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing Mod_Qos/Spamhaus"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt-get -y install libapache2-mod-qos
    cp templates/qos /etc/apache2/mods-available/qos.conf
    apt-get -y install libapache2-mod-spamhaus
    cp templates/spamhaus /etc/apache2/mods-available/spamhaus.conf
    service apache2 restart
    say_done
}

##############################################################################################################

# Install Additional Packages
additional_packages(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing Additional Packages"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Install tree............."; apt-get install tree
    echo "Install Python-MySQLdb..."; apt-get install python-mysqldb
    echo "Install WSGI............."; apt-get install libapache2-mod-wsgi
    echo "Install PIP.............."; apt-get install python-pip
    echo "Install Vim.............."; apt-get install vim
    echo "Install Nano............."; apt-get install nano
    echo "Install pear............."; apt-get install php-pear
    echo "Install PHPUnit..........";
    pear config-set auto_discover 1
    mv phpunit-patched /usr/share/phpunit
    echo include_path = ".:/usr/share/phpunit:/usr/share/phpunit/PHPUnit" >> /etc/php5/apache2/php.ini
    echo include_path = ".:/usr/share/phpunit:/usr/share/phpunit/PHPUnit" >> /etc/php5/cli/php.ini
    service apache2 restart
    say_done
}

##############################################################################################################
# Tune and Secure Kernel
tune_secure_kernel(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Tuning and Securing the Linux Kernel"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Securing Linux Kernel"
    spinner
    cp templates/sysctl.conf /etc/sysctl.conf; echo " OK"
    cp templates/ufw /etc/default/ufw
    sysctl -e -p
    say_done
}

##############################################################################################################

# Install RootKit Hunter
install_rootkit_hunter(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing RootKit Hunter"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    cd rkhunter-1.4.2/
    sh installer.sh --layout /usr --install
    cd ..
    rkhunter --update
    rkhunter --propupd
    echo " ***To Run RootKit Hunter ***"
    echo "     rkhunter -c --enable all --disable none"
    echo "     Puede ver el reporte detallado en /var/log/rkhunter.log"
    say_done
}

##############################################################################################################

# Tuning
tune_nano_vim_bashrc(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Tunning bashrc, nano and Vim"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""

# Tune .bashrc
    echo "Tunning .bashrc......"
    spinner
    cp templates/bashrc-root /root/.bashrc
    cp templates/bashrc-user /home/$username/.bashrc
    chown $username:$username /home/$username/.bashrc
    echo "OK"
    say_done


# Tune Vim
    echo "Tunning Vim......"
    spinner
    tunning vimrc
    echo "OK"


# Tune Nano
    echo "Tunning Nano......"
    spinner
    tunning nanorc
    echo "OK"
}

##############################################################################################################

# Add Daily Update Cron Job
daily_update_cronjob(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Adding Daily System Udpdate Cron Job"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Creating Daily Cron Job"
    spinner
    job="@daily apt-get update; apt-get dist-upgrade -y"
    touch job
    echo $job >> job
    crontab job
    rm job
    say_done
}

##############################################################################################################

# Install PortSentry
install_portsentry(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing PortSentry"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt-get install portsentry
    mv /etc/portsentry/portsentry.conf /etc/portsentry/portsentry.conf-original
    cp templates/portsentry /etc/portsentry/portsentry.conf
    sed s/tcp/atcp/g /etc/default/portsentry > salida.tmp
    mv salida.tmp /etc/default/portsentry
    /etc/init.d/portsentry restart
    say_done
}

##############################################################################################################

# Additional Hardening Steps
additional_hardening(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Running additional Hardening Steps"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Running Additional Hardening Steps...."
    spinner
    echo tty1 > /etc/securetty
    chmod 700 /root
    chmod 600 /boot/grub/grub.cfg
    #Protect Against IP Spoofing
    echo nospoof on >> /etc/host.conf
    #Remove AT and Restrict Cron
    apt-get purge at
    echo " Securing Cron "
    touch /etc/cron.allow
    chmod 600 /etc/cron.allow
    awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/cron.deny
    echo "OK"
    say_done
}

##############################################################################################################

# Install Unhide
install_unhide(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing UnHide"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt-get -y install unhide
    echo " Unhide is a tool for Detecting Hidden Processes "
    echo " For more info about the Tool use the manpages "
    echo " man unhide "
    say_done
}

##############################################################################################################

# Install Tiger
#Tiger is and Auditing and Intrusion Detection System
install_tiger(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing Tiger"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt-get -y install tiger
    echo " For More info about the Tool use the ManPages "
    echo " man tiger "
    say_done
}

##############################################################################################################

# Disable Compilers
disable_compilers(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Disabling Compilers"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Disabling Compilers....."
    spinner
    chmod 000 /usr/bin/byacc >/dev/null 2>&1
    chmod 000 /usr/bin/yacc >/dev/null 2>&1
    chmod 000 /usr/bin/bcc >/dev/null 2>&1
    chmod 000 /usr/bin/kgcc >/dev/null 2>&1
    chmod 000 /usr/bin/cc >/dev/null 2>&1
    chmod 000 /usr/bin/gcc >/dev/null 2>&1
    chmod 000 /usr/bin/*c++ >/dev/null 2>&1
    chmod 000 /usr/bin/*g++ >/dev/null 2>&1
    spinner
    echo ""
    echo " If you wish to use them, just change the Permissions"
    echo " Example: chmod 755 /usr/bin/gcc "
    echo "OK"
    say_done
}

##############################################################################################################

# Restrict Access to Apache Config Files
apache_conf_restrictions(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Restricting Access to Apache Config Files"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Restricting Access to Apache Config Files......"
    spinner
     chmod 750 /etc/apache2/conf*
     chmod 511 /usr/sbin/apache2
     chmod 750 /var/log/apache2/
     chmod 640 /etc/apache2/conf-available/*
     chmod 640 /etc/apache2/conf-enabled/*
     chmod 640 /etc/apache2/apache2.conf
     echo "OK"
     say_done
}

##############################################################################################################

# Additional Security Configurations
  #Enable Unattended Security Updates
  unattended_upgrades(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Enable Unattended Security Updates"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  echo -e "\e[93m[?]\e[00m ¿Do you Wish to Enable Unattended Security Updates? (y/n): "; read unattended
  if [ "$unattended" == "y" ]; then
      dpkg-reconfigure -plow unattended-upgrades
  else
      clear
  fi
}

##############################################################################################################

# Enable Process Accounting
enable_proc_acct(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Enable Process Accounting"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  apt-get install acct
  touch /var/log/wtmp
  echo "OK"
}

##############################################################################################################

#Install PHP Suhosin Extension
install_phpsuhosin(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Installing PHP Suhosin Extension"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  echo 'deb http://repo.suhosin.org/ vivid main' >> /etc/apt/sources.list
  #Suhosin Key
  wget https://sektioneins.de/files/repository.asc
  apt-key add repository.asc
  apt-get update
  apt-get install php5-suhosin-extension
  php5enmod suhosin
  service apache2 restart
  echo "OK"
  say_done
}

##############################################################################################################

# Reboot Server
reboot_server(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Final Step"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    replace USERNAME $username SERVERIP $serverip < templates/texts/bye
    echo -n " ¿Were you able to connect via SSH to the Server using $username? (y/n) "
    read answer
    if [ "$answer" == "y" ]; then
        reboot
    else
        echo "Server will not Reboot"
        echo "Bye."
    fi
}

##################################################################################################################

clear
f_banner
echo
echo "1. LAMP Deployment"
echo "2. Reverse Proxy Deployment With Apache"
echo "3. Running With SecureWPDeployer Script"
echo "4. Exit"
echo

read choice

case $choice in

1)
check_root
config_host
config_timezone
update_system
admin_user
rsa_keygen
rsa_keycopy
secure_ssh
set_iptables
install_sendmail
install_secure_mysql
install_apache
install_secure_php
install_modsecurity
set_owasp_rules
secure_optimize_apache
install_modevasive
install_qos_spamhaus
additional_packages
tune_secure_kernel
install_rootkit_hunter
tune_nano_vim_bashrc
daily_update_cronjob
install_portsentry
additional_hardening
install_unhide
install_tiger
disable_compilers
apache_conf_restrictions
unattended_upgrades
enable_proc_acct
install_phpsuhosin
reboot_server
;;

2)
check_root
config_host
config_timezone
update_system
admin_user
rsa_keygen
rsa_keycopy
secure_ssh
set_iptables
install_sendmail
install_apache
install_modsecurity
set_owasp_rules
secure_optimize_apache
install_modevasive
install_qos_spamhaus
additional_packages
tune_secure_kernel
install_rootkit_hunter
tune_nano_vim_bashrc
daily_update_cronjob
install_portsentry
additional_hardening
install_unhide
install_tiger
disable_compilers
apache_conf_restrictions
unattended_upgrades
enable_proc_acct
reboot_server
;;

3)
check_root
config_host
config_timezone
update_system
admin_user
rsa_keygen
rsa_keycopy
secure_ssh
set_iptables
install_sendmail
install_secure_mysql
install_apache
install_secure_php
install_modsecurity
set_owasp_rules
secure_optimize_apache
install_modevasive
install_qos_spamhaus
additional_packages
tune_secure_kernel
install_rootkit_hunter
tune_nano_vim_bashrc
daily_update_cronjob
install_portsentry
additional_hardening
install_unhide
install_tiger
disable_compilers
apache_conf_restrictions
unattended_upgrades
enable_proc_acct
install_phpsuhosin
;;

4)
exit 0
;;

esac
##############################################################################################################
