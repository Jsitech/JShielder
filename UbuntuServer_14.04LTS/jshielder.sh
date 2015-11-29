#!/bin/bash

# JShielder v1.0
# Deployer for Ubuntu Server 14.04 LTS
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


For Ubuntu Server 14.04 LTS
By Jason Soto "
echo
echo

}

##############################################################################################################

#Check if running with root User

clear
f_banner

if [ "$USER" != "root" ]; then
      echo "Permission Denied"
      echo "Can only be run by root"
      exit
else
      clear
      f_banner
      cat templates/texts/welcome
fi

# 1. Configure Hostname
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



# 2. Configure TimeZone
   clear
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m We will now Configure the TimeZone"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo ""
   sleep 10
   dpkg-reconfigure tzdata
   say_done

#  3. Update System
   clear
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m Updating the System"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo ""
   apt-get update
   apt-get upgrade -y
   say_done

#  4. Create Privileged User
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


#  5. Instruction to Generate RSA Keys
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


#  6. Move the Generated Public Key
    echo " Run the Following Command to copy the Key"
    echo " Press ENTER when done "
    echo " ssh-copy-id -i $HOME/.ssh/id_rsa.pub $username@$serverip "
    say_done



#  7.Secure SSH
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


#  8. Set IPTABLES Rules
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


# 9. Install fail2ban
    # To Remove a Fail2Ban rule use:
    # iptables -D fail2ban-ssh -s IP -j DROP
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing Fail2Ban"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt-get install sendmail
    apt-get install fail2ban
    say_done



# 10. Install, Configure and Optimize MySQL
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


# 11. Install, Configure and Optimize PHP
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing, Configuring and Optimizing PHP"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt-get install apache2
    apt-get install php5 php5-cli php-pear
    apt-get install php5-mysql python-mysqldb
    echo -n " Replacing php.ini..."
    cp templates/php /etc/php5/apache2/php.ini; echo " OK"
    cp templates/php /etc/php5/cli/php.ini; echo " OK"
    service apache2 restart
    say_done



# 12. Install ModSecurity
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



# 13. Configure OWASP for ModSecuity
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



# 14. Configure and optimize Apache
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



# 15. Install ModEvasive
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


# 16. Install Mod_qos/spamhaus
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


# 17. Configure fail2ban
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Configuring Fail2Ban"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Configuring Fail2Ban......"
    spinner
    sed s/MAILTO/$inbox/g templates/fail2ban > /etc/fail2ban/jail.local
    cp /etc/fail2ban/jail.local /etc/fail2ban/jail.conf
    /etc/init.d/fail2ban restart
    say_done


# 18. Install Additional Packages
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


# 19. Tune and Secure Kernel
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Tunning and Securing the Linux Kernel"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Securing Linux Kernel"
    spinner
    cp templates/sysctl.conf /etc/sysctl.conf; echo " OK"
    cp templates/ufw /etc/default/ufw
    sysctl -e -p
    say_done


# 20. Install RootKit Hunter
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


    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Tunning bashrc, nano and Vim"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""

# 21. Tune .bashrc
    echo "Tunning .bashrc......"
    spinner
    cp templates/bashrc-root /root/.bashrc
    cp templates/bashrc-user /home/$username/.bashrc
    chown $username:$username /home/$username/.bashrc
    echo "OK"
    say_done



# 22. Tune Vim
    echo "Tunning Vim......"
    spinner
    tunning vimrc
    echo "OK"


# 23. Tune Nano
    echo "Tunning Vim......"
    spinner
    tunning nanorc
    echo "OK"


# 24. Add Daily Update Cron Job
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


# 25. Install PortSentry
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


# 26. Additional Hardening Steps
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
    #Proteger contra IP Spoofing
    echo nospoof on >> /etc/host.conf
    #Desinstalar AT y Restringiendo Cron a Root
    apt-get purge at
    echo " Securing Cron "
    touch /etc/cron.allow
    chmod 600 /etc/cron.allow
    awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/cron.deny
    echo "OK"
    say_done


# 27. Install Unhide
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


# 28. Install Tiger
#Tiger is and Auditing and Intrusion Detection System
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



#29. Disable Compilers
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
    echo " If you wish to use them, just change the Permissions"
    echo " Example: chmod 755 /usr/bin/gcc "
    echo "OK"
    say_done


#30. Restrict Access to Apache Config Files
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

#31. Additional Security Configurations
  #Enable Unattended Security Updates
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

  # Enable Process Accounting
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Enable Process Accounting"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  apt-get install acct
  touch /var/log/wtmp



# 32. Reboot Server
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
