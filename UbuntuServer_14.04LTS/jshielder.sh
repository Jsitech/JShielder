#!/bin/bash

# JShielder v2.0
# Deployer for Ubuntu Server 14.04 LTS
#
# Jason Soto
# www.jsitech.com
# Twitter = @JsiTech

# Based from JackTheStripper Project
# Credits to Eugenia Bahit

# A lot of Suggestion Taken from The Lynis Project
# www.cisofy.com/lynis
# Credits to Michael Boelen @mboelen


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
echo -n " ¿Do you Wish to Set a HostName? (y/n): "; read config_host
if [ "$config_host" == "y" ]; then
    serverip=$(__get_ip)
    echo " Type a Name to Identify this server :"
    echo -n " (For Example: myserver): "; read host_name
    echo -n " ¿Type Domain Name?: "; read domain_name
    echo $host_name > /etc/hostname
    hostname -F /etc/hostname
    echo "127.0.0.1    localhost.localdomain      localhost" >> /etc/hosts
    echo "$serverip    $host_name.$domain_name    $host_name" >> /etc/hosts
    #Creating Legal Banner for unauthorized Access
    echo ""
    echo "Creating legal Banners for unauthorized access"
    spinner
    cat templates/motd > /etc/motd
    cat templates/motd > /etc/issue
    cat templates/motd > /etc/issue.net
    sed -i s/server.com/$host_name.$domain_name/g /etc/motd /etc/issue /etc/issue.net
    echo "OK "
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

# Update System, Install sysv-rc-conf tool
update_system(){
   clear
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m Updating the System"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo ""
   apt-get update
   apt-get upgrade -y
   apt-get install -y sysv-rc-conf
   say_done
}

##############################################################################################################

# Setting a more restrictive UMASK
restrictive_umask(){
   clear
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m Setting UMASK to a more Restrictive Value (027)"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo ""
   spinner
   cp templates/login.defs /etc/login.defs
   sed -i s/umask\ 022/umask\ 027/g /etc/init.d/rc
   echo ""
   echo "OK"
   say_done
}

##############################################################################################################

# Create Privileged User
admin_user(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m We will now Create a New User"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " Type the new username: "; read username
    adduser $username
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

#Securing /tmp Folder
secure_tmp(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Securing /tmp Folder"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  echo -n " ¿Did you Create a Separate /tmp partition during the Initial Installation? (y/n): "; read tmp_answer
  if [ "$tmp_answer" == "n" ]; then
      echo "We will create a FileSystem for the /tmp Directory and set Proper Permissions "
      dd if=/dev/zero of=/usr/tmpDISK bs=1024 count=2048000
      mkdir /tmpbackup
      cp -Rpf /tmp /tmpbackup
      mount -t tmpfs -o loop,noexec,nosuid,rw /usr/tmpDISK /tmp
      chmod 1777 /tmp
      cp -Rpf /tmpbackup/* /tmp/
      rm -rf /tmpbackup
      echo "/usr/tmpDISK  /tmp    tmpfs   loop,nosuid,noexec,rw  0 0" >> /etc/fstab
      sudo mount -o remount /tmp
      rm -rf /var/tmp
      ln -s /tmp /var/tmp
      say_done
  else
      echo "Nice Going, Remember to set proper permissions in /etc/fstab"
      echo ""
      echo "Example:"
      echo ""
      echo "/dev/sda4   /tmp   tmpfs  loop,nosuid,noexec,rw  0 0 "
      say_done
  fi
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
    chmod +x /etc/init.d/iptables.sh
    ln -s /etc/init.d/iptables.sh /etc/rc2.d/S99iptables.sh
    say_done
}

##############################################################################################################

# Install fail2ban
    # To Remove a Fail2Ban rule use:
    # iptables -D fail2ban-ssh -s IP -j DROP
install_fail2ban(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing Fail2Ban"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt-get install sendmail
    apt-get install fail2ban
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

# Install Nginx With ModSecurity
install_nginx_modsecurity(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Downloading and Compiling Nginx with ModSecurity"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  apt-get -y install git build-essential libpcre3 libpcre3-dev libssl-dev libtool autoconf apache2-prefork-dev libxml2-dev libcurl4-openssl-dev
  mkdir src
  cd src/
  git clone https://github.com/SpiderLabs/ModSecurity
  cd ModSecurity
  ./autogen.sh
  ./configure --enable-standalone-module
  make
  cd ..
  wget http://nginx.org/download/nginx-1.9.7.tar.gz
  tar xzvf nginx-1.9.7.tar.gz
  cp ../templates/ngx_http_header_filter_module.c nginx-1.9.7/src/http/ngx_http_header_filter_module.c
  cd nginx-1.9.7/
  ./configure --user=www-data --group=www-data --with-pcre-jit --with-debug --with-http_ssl_module --add-module=/root/JShielder/UbuntuServer_14.04LTS/src/ModSecurity/nginx/modsecurity
  make
  make install
  #Replacing Nginx conf with secure Configurations
  cp ../../templates/nginx /usr/local/nginx/conf/nginx.conf
  #Jason Giedymin Nginx Init Script
  wget https://raw.github.com/JasonGiedymin/nginx-init-ubuntu/master/nginx -O /etc/init.d/nginx
  chmod +x /etc/init.d/nginx
  update-rc.d nginx defaults
  mkdir /usr/local/nginx/conf/sites-available
  mkdir /usr/local/nginx/conf/sites-enabled
  say_done
}
  ##############################################################################################################

  #Setting UP Virtual Host
  set_nginx_vhost(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Setup Virtual Host for Nginx"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo " Configure a Virtual Host"
  echo " Type a Name to Identify the Virtual Host"
  echo -n " (For Example: myserver.com) "; read vhost
  touch /usr/local/nginx/conf/sites-available/$vhost
  cd ../..
  cat templates/nginxvhost >> /usr/local/nginx/conf/sites-available/$vhost
  sed -i s/server.com/$vhost/g /usr/local/nginx/conf/sites-available/$vhost
  ln -s /usr/local/nginx/conf/sites-available/$vhost /usr/local/nginx/conf/sites-enabled/$vhost
  say_done
}


##############################################################################################################

#Setting UP Virtual Host
set_nginx_vhost_nophp(){
clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Setup Virtual Host for Nginx"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo " Configure a Virtual Host"
echo " Type a Name to Identify the Virtual Host"
echo -n " (For Example: myserver.com) "; read vhost
touch /usr/local/nginx/conf/sites-available/$vhost
cd ../..
cat templates/nginxvhost_nophp >> /usr/local/nginx/conf/sites-available/$vhost
sed -i s/server.com/$vhost/g /usr/local/nginx/conf/sites-available/$vhost
ln -s /usr/local/nginx/conf/sites-available/$vhost /usr/local/nginx/conf/sites-enabled/$vhost
say_done
}


##############################################################################################################

#Set Nginx Modsecurity OWASP Rules
set_nginx_modsec_OwaspRules(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Setting OWASP Rules for ModSecurity on Nginx"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  cd src/
  wget https://github.com/SpiderLabs/owasp-modsecurity-crs/tarball/master -O owasp.tar.gz
  tar -zxvf owasp.tar.gz
  owaspdir=$(ls -la | grep SpiderLabs | cut -d ' ' -f18)
  cp ModSecurity/modsecurity.conf-recommended /usr/local/nginx/conf/modsecurity.conf
  cp ModSecurity/unicode.mapping /usr/local/nginx/conf/
  cd $owaspdir/
  cat modsecurity_crs_10_setup.conf.example >> /usr/local/nginx/conf/modsecurity.conf
  cd base_rules/
  cat *.conf >> /usr/local/nginx/conf/modsecurity.conf
  cp *.data /usr/local/nginx/conf/
  cd ../../..
  service nginx restart
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
# Install, Configure and Optimize PHP for Nginx
install_php_nginx(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Installing, Configuring and Optimizing PHP/PHP-FPM"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  apt-get install php5-fpm php5 php5-cli php-pear
  apt-get install php5-mysql python-mysqldb
  echo -n " Replacing php.ini..."
  cp templates/php /etc/php5/cli/php.ini; echo " OK"
  cp templates/phpnginx /etc/php5/fpm/php.ini; echo "OK"
  service php5-fpm restart
  service nginx restart
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

# Configure fail2ban
config_fail2ban(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Configuring Fail2Ban"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo " Configuring Fail2Ban......"
    spinner
    sed s/MAILTO/$inbox/g templates/fail2ban > /etc/fail2ban/jail.local
    cp /etc/fail2ban/jail.local /etc/fail2ban/jail.conf
    /etc/init.d/fail2ban restart
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
    echo "Install DebSums.........."; apt-get install debsums
    echo "Install apt-show-versions"; apt-get install apt-show-versions
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
    echo " Securing Linux Kernel"
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
    echo "Rootkit Hunter is a scanning tool to ensure you are you're clean of nasty tools. This tool scans for rootkits, backdoors and local exploits by running tests like:

          - MD5 hash compare
          - Look for default files used by rootkits
          - Wrong file permissions for binaries
          - Look for suspected strings in LKM and KLD modules
          - Look for hidden files
          - Optional scan within plaintext and binary files "
    sleep 1
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
    chmod 0600 /etc/securetty
    chmod 700 /root
    chmod 600 /boot/grub/grub.cfg
    #Protect Against IP Spoofing
    echo nospoof on >> /etc/host.conf
    #Remove AT and Restrict Cron
    apt-get purge at
    apt-get install -y libpam-cracklib
    echo " Securing Cron "
    touch /etc/cron.allow
    chmod 600 /etc/cron.allow
    awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/cron.deny
    echo -n " Do you want to Disable USB Support for this Server? (y/n): " ; read usb_answer
    if [ "$usb_answer" == "y" ]; then
       echo "blacklist usb-storage" | sudo tee -a /etc/modprobe.d/blacklist.conf
       update-initramfs -u
       echo "OK"
       say_done
    else
       echo "OK"
       say_done
    fi
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
    echo "Unhide is a forensic tool to find hidden processes and TCP/UDP ports by rootkits / LKMs or by another hidden technique."
    sleep 1
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
    echo "Tiger is a security tool that can be use both as a security audit and intrusion detection system"
    sleep 1
    apt-get -y install tiger
    echo " For More info about the Tool use the ManPages "
    echo " man tiger "
    say_done
}

##############################################################################################################

#Install PSAD
#PSAD actively monitors firewall logs to determine if a scan or attack is taking place
install_psad(){
clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Install PSAD"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo " PSAD is a piece of Software that actively monitors you Firewall Logs to Determine if a scan
       or attack event is in Progress. It can alert and Take action to deter the Threat

       NOTE:
       IF YOU ARE ONLY RUNNING THIS FUNCTION, YOU MUST ENABLE LOGGING FOR iptables

       iptables -A INPUT -j LOG
       iptables -A FORWARD -j LOG

       "
echo ""
echo -n " Do you want to install PSAD (Recommended)? (y/n): " ; read psad_answer
if [ "$psad_answer" == "y" ]; then
     echo -n " Type an Email Address to Receive PSAD Alerts: " ; read inbox1
     apt-get install psad
     sed s/INBOX/$inbox1/g templates/psad.conf
     sed s/hostname/$host_name.$domain_name/g templates/psad.conf > /etc/psad/psad.conf
     psad --sig-update
     service psad restart
     echo "Installation and Configuration Complete"
     echo "Run service psad status, for detected events"
     echo ""
     say_done
else
     echo "OK"
     say_done
fi
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
    chmod 000 /usr/bin/as >/dev/null 2>&1
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
    echo " OK"
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
    echo " Restricting Access to Apache Config Files......"
    spinner
     chmod 750 /etc/apache2/conf* >/dev/null 2>&1
     chmod 511 /usr/sbin/apache2 >/dev/null 2>&1
     chmod 750 /var/log/apache2/ >/dev/null 2>&1
     chmod 640 /etc/apache2/conf-available/* >/dev/null 2>&1
     chmod 640 /etc/apache2/conf-enabled/* >/dev/null 2>&1
     chmod 640 /etc/apache2/apache2.conf >/dev/null 2>&1
     echo " OK"
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
  echo -n " ¿Do you Wish to Enable Unattended Security Updates? (y/n): "; read unattended
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
  echo 'deb http://repo.suhosin.org/ ubuntu-trusty main' >> /etc/apt/sources.list
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

#Install and enable auditd

install_auditd(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Installing auditd"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  apt-get install auditd
  cp templates/audit.rules /etc/audit/audit.rules
  sysv-rc-conf auditd on
  service auditd restart
  echo "OK"
  say_done
}
##############################################################################################################

#Install and Enable sysstat

install_sysstat(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Installing and enabling sysstat"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  apt-get install sysstat
  sed -i 's/ENABLED="false"/ENABLED="true"/g' /etc/default/sysstat
  service sysstat start
  echo "OK"
  say_done
}

##############################################################################################################

#Install ArpWatch

install_arpwatch(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m ArpWatch Install"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  echo "ArpWatch is a tool for monitoring ARP traffic on System. It generates log of observed pairing of IP and MAC."
  echo ""
  echo -n " Do you want to Install ArpWatch on this Server? (y/n): " ; read arp_answer
  if [ "$arp_answer" == "y" ]; then
     echo "Installing ArpWatch"
     spinner
     apt-get install -y arpwatch
     sysv-rc-conf arpwatch on
     service arpwatch start
     echo "OK"
     say_done
  else
     echo "OK"
     say_done
  fi
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
    echo -n " ¿Were you able to connect via SSH to the Server using $username? (y/n): "; read answer
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
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m SELECT THE DESIRED OPTION"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo "1. LAMP Deployment"
echo "2. Reverse Proxy Deployment With Apache"
echo "3. LEMP Deployment (Under Development, Testing)"
echo "4. Reverse Proxy Deployment with Nginx (ModSecurity)"
echo "5. Running With SecureWPDeployer or JSDeployer Script"
echo "6. Customized Run (Only run desired Options)"
echo "7. Exit"
echo

read choice

case $choice in

1)
check_root
config_host
config_timezone
update_system
restrictive_umask
admin_user
rsa_keygen
rsa_keycopy
secure_ssh
set_iptables
install_fail2ban
install_secure_mysql
install_apache
install_secure_php
install_modsecurity
set_owasp_rules
secure_optimize_apache
install_modevasive
install_qos_spamhaus
config_fail2ban
additional_packages
tune_secure_kernel
install_rootkit_hunter
tune_nano_vim_bashrc
daily_update_cronjob
install_portsentry
additional_hardening
install_unhide
install_tiger
install_psad
disable_compilers
secure_tmp
apache_conf_restrictions
unattended_upgrades
enable_proc_acct
install_auditd
install_sysstat
install_arpwatch
install_phpsuhosin
reboot_server
;;

2)
check_root
config_host
config_timezone
update_system
restrictive_umask
admin_user
rsa_keygen
rsa_keycopy
secure_ssh
set_iptables
install_fail2ban
install_apache
install_modsecurity
set_owasp_rules
secure_optimize_apache
install_modevasive
install_qos_spamhaus
config_fail2ban
additional_packages
tune_secure_kernel
install_rootkit_hunter
tune_nano_vim_bashrc
daily_update_cronjob
install_portsentry
additional_hardening
install_unhide
install_tiger
install_psad
disable_compilers
secure_tmp
apache_conf_restrictions
unattended_upgrades
enable_proc_acct
install_auditd
install_sysstat
install_arpwatch
reboot_server
;;

3)
check_root
config_host
config_timezone
update_system
restrictive_umask
admin_user
rsa_keygen
rsa_keycopy
secure_ssh
set_iptables
install_fail2ban
install_secure_mysql
install_nginx_modsecurity
set_nginx_vhost
set_nginx_modsec_OwaspRules
install_php_nginx
config_fail2ban
additional_packages
tune_secure_kernel
install_rootkit_hunter
tune_nano_vim_bashrc
daily_update_cronjob
install_portsentry
additional_hardening
install_unhide
install_tiger
install_psad
disable_compilers
secure_tmp
unattended_upgrades
enable_proc_acct
install_auditd
install_sysstat
install_arpwatch
install_phpsuhosin
reboot_server
;;

4)
check_root
config_host
config_timezone
update_system
restrictive_umask
admin_user
rsa_keygen
rsa_keycopy
secure_ssh
set_iptables
install_fail2ban
install_nginx_modsecurity
set_nginx_vhost_nophp
set_nginx_modsec_OwaspRules
config_fail2ban
additional_packages
tune_secure_kernel
install_rootkit_hunter
tune_nano_vim_bashrc
daily_update_cronjob
install_portsentry
additional_hardening
install_unhide
install_tiger
install_psad
disable_compilers
secure_tmp
unattended_upgrades
enable_proc_acct
install_auditd
install_sysstat
install_arpwatch
reboot_server
;;

5)
check_root
config_host
config_timezone
update_system
restrictive_umask
admin_user
rsa_keygen
rsa_keycopy
secure_ssh
set_iptables
install_fail2ban
install_secure_mysql
install_apache
install_secure_php
install_modsecurity
set_owasp_rules
secure_optimize_apache
install_modevasive
install_qos_spamhaus
config_fail2ban
additional_packages
tune_secure_kernel
install_rootkit_hunter
tune_nano_vim_bashrc
daily_update_cronjob
install_portsentry
additional_hardening
install_unhide
install_tiger
install_psad
disable_compilers
secure_tmp
apache_conf_restrictions
unattended_upgrades
enable_proc_acct
install_auditd
install_sysstat
install_arpwatch
install_phpsuhosin
;;

6)

menu=""
until [ "$menu" = "33" ]; do

clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m SELECT THE DESIRED OPTION"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo "1. Configure Host Name, Create Legal Banners, Update Hosts Files"
echo "2. Configure Timezone"
echo "3. Update System"
echo "4. Create Admin User"
echo "5. Instructions to Generate and move Private/Public key Pair"
echo "6. Secure SSH Configuration"
echo "7. Set Restrictive IPTable Rules"
echo "8. Install and Configure Fail2Ban"
echo "9. Install, Optimize and Secure Apache"
echo "10. Install Nginx with ModSecurity Module and Set OwaspRules"
echo "11. Set Nginx Vhost with PHP"
echo "12. Set Nginx Vhost"
echo "13. Install and Secure PHP for Apache Server"
echo "14. Install and Secure PHP for Nginx Server"
echo "15. Install ModSecurity (Apache)and Set Owasp Rules"
echo "16. Install ModEvasive"
echo "17. Install ModQos and SpamHaus"
echo "18. Tune and Secure Linux Kernel"
echo "19. Install RootKit Hunter"
echo "20. Tune Vim, Nano, Bashrc"
echo "21. Install PortSentry"
echo "22. Secure tty, root home, grub configs, cron"
echo "23. Install Unhide"
echo "24. Install Tiger"
echo "25. Disable Compilers"
echo "26. Enable Unnatended Upgrades"
echo "27. Enable Process Accounting"
echo "28. Install PHP Suhosin"
echo "29. Install and Secure MySQL"
echo "30. Set More Restrictive UMASK Value (027)"
echo "31. Secure /tmp Directory"
echo "32. Install PSAD IDS"
echo "33. Exit"
echo " "

read menu
case $menu in

1)
config_host
;;

2)
config_timezone
;;

3)
update_system
;;

4)
admin_user
;;

5)
rsa_keygen
rsa_keycopy
;;

6)
echo "key Pair must be created "
echo "What user will have access via SSH? " ; read username
rsa_keygen
rsa_keycopy
secure_ssh
;;

7)
set_iptables
;;

8)
echo "Type Email to receive Alerts: " ; read inbox
install_fail2ban
config_fail2ban
;;

9)
install_apache
secure_optimize_apache
apache_conf_restrictions
;;

10)
install_nginx_modsecurity
set_nginx_modsec_OwaspRules
;;

11)
set_nginx_vhost
;;


12)
set_nginx_vhost_nophp
;;

13)
install_secure_php
;;

14)
install_php_nginx
;;

15)
install_modsecurity
set_owasp_rules
;;

16)
install_modevasive
;;

17)
install_qos_spamhaus
;;

18)
tune_secure_kernel
;;

19)
install_rootkit_hunter
;;

20)
tune_nano_vim_bashrc
;;

21)
install_portsentry
;;

22)
additional_hardening
;;

23)
install_unhide
;;

24)
install_tiger
;;

25)
disable_compilers;
;;

26)
unattended_upgrades
;;

27)
enable_proc_acct
;;

28)
install_phpsuhosin
;;

29)
install_secure_mysql
;;

30)
restrictive_umask
;;

31)
secure_tmp
;;

32)
install_psad
;;

33)
break ;;

*) ;;

esac
done
;;

7)
exit 0
;;

esac
##############################################################################################################
