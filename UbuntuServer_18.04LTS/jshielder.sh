#!/usr/bin/env bash

# JShielder v2.4
# Deployer for Ubuntu Server 18.04 LTS
#
# Jason Soto
# www.jasonsoto.com
# www.jsitech-sec.com
# Twitter = @JsiTech

# Based from JackTheStripper Project
# Credits to Eugenia Bahit

# A lot of Suggestion Taken from The Lynis Project
# www.cisofy.com/lynis
# Credits to Michael Boelen @mboelen

#Credits to Center for Internet Security CIS


source helpers.sh
MYNAME="$(basename "${0%.sh}" )"

##############################################################################################################

f_banner(){
	clear
	echo "


     ██╗███████╗██╗  ██╗██╗███████╗██╗     ██████╗ ███████╗██████╗
     ██║██╔════╝██║  ██║██║██╔════╝██║     ██╔══██╗██╔════╝██╔══██╗
     ██║███████╗███████║██║█████╗  ██║     ██║  ██║█████╗  ██████╔╝
██   ██║╚════██║██╔══██║██║██╔══╝  ██║     ██║  ██║██╔══╝  ██╔══██╗
╚█████╔╝███████║██║  ██║██║███████╗███████╗██████╔╝███████╗██║  ██║
╚════╝ ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═╝

For Ubuntu Server 18.04 LTS
Developed By Jason Soto @Jsitech

"

}

##############################################################################################################

# Check if running with root User

check_root() {
if [ "${CUID}" -ne 0 ]; then
	perr "You must be root to run this script!"
	exit 1
else
	jshielder_home=$(pwd)
	cat templates/texts/welcome
fi
}

##############################################################################################################

# Installing Dependencies
# Needed Prerequesites will be set up here
install_dep(){
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m Setting some Prerequisites"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   spinner
   add-apt-repository universe\
		 && say_done
}

##############################################################################################################

# Configure Hostname
config_host() {
	echo -n " ¿Do you Wish to Set a HostName? (y/n): "; read -r config_host
	if [ "$config_host" == "y" ]; then
		__get_ip
		echo " Type a Name to Identify this server :"
		echo -n " (For Example: myserver): "; read -r host_name
		echo -n " ¿Type Domain Name?: "; read -r domain_name
		echo "${host_name}" > /etc/hostname && hostname -F /etc/hostname
		printf "%s\t%s\t%s\n"\
			"127.0.0.1"    "localhost.localdomain"      "localhost"\
			"$serverip"    "$host_name.$domain_name"    "$host_name" >> /etc/hosts
		# Creating Legal Banner for unauthorized Access
		perr "Creating legal Banners for unauthorized access"
		spinner
		# Retain execution context, create command list
		{
			sed -i s/server.com/"${host_name}.${domain_name}"/g templates/motd\
				&& cat templates/motd > /etc/motd\
				&& cat templates/motd > /etc/issue\
				&& cat templates/motd > /etc/issue.net
		} && echo "OK "
	fi
	say_done
}

##############################################################################################################

# Configure TimeZone
config_timezone(){
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m We will now Configure the TimeZone"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo ""
   dpkg-reconfigure tzdata && say_done
}

##############################################################################################################

# Update System, Install sysv-rc-conf tool
update_system(){
 f_banner
 echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
 echo -e "\e[93m[+]\e[00m Updating the System"
 echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
 {
	 apt update && apt upgrade -y && apt dist-upgrade -y
 } >/dev/null && say_done
}

##############################################################################################################

# Setting a more restrictive UMASK
restrictive_umask(){
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m Setting UMASK to a more Restrictive Value (027)"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   spinner
   cp templates/login.defs /etc/login.defs && echo "OK"
   say_done
}

#############################################################################################################

#Disabling Unused Filesystems

unused_filesystems(){
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m Disabling Unused FileSystems"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   spinner
	 printf "install %s /bin/true"\
		 "cramfs"\
		 "freevxfs"\
		 "jffs2"\
		 "hfs"\
		 "hfsplus"\
		 "squashfs"\
		 "udf"\
		 "vfat"\
		 >> /etc/modprobe.d/CIS.conf && echo " OK"
   say_done
}

##############################################################################################################

uncommon_netprotocols(){
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m Disabling Uncommon Network Protocols"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   spinner
	 printf "install %s /bin/true"\
		 "dccp"\
		 "sctp"\
		 "rds"\
		 "tipc"\
		 >> /etc/modprobe.d/CIS.conf && echo " OK"
   say_done
}

##############################################################################################################

# Create Privileged User
admin_user(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m We will now Create a New User"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
		## XXX: Consider using an until loop here to loop until a user is successfully created
    printf "\n Type the new username: "; read -r username
    adduser "${username}"
		say_done
}

##############################################################################################################

# Instruction to Generate RSA Keys
rsa_keygen(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Instructions to Generate an RSA KEY PAIR"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo " *** IF YOU DONT HAVE A PUBLIC RSA KEY, GENERATE ONE ***"
    echo "     Follow the Instruction and Hit Enter When Done"
    echo "     To receive a new Instruction"
    echo " "
		## XXX: Look at supporting additional key types, should not be particularly difficult
    echo "    RUN THE FOLLOWING COMMANDS"
    echo -n "     a) ssh-keygen -t rsa -b 4096 "; read -r foo1
    echo -n "     b) cat /home/${username}/.ssh/id_rsa.pub >> /home/${username}/.ssh/authorized_keys "; read -r foo2
    say_done
}
##############################################################################################################

# Move the Generated Public Key
rsa_keycopy(){
    echo " Run the Following Command to copy the Key"
    echo " Press ENTER when done "
    echo " ssh-copy-id -i ${HOME}/.ssh/id_rsa.pub ${username}@${serverip} "
    say_done
}
##############################################################################################################

#Securing /tmp Folder
secure_tmp(){
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Securing /tmp Folder"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  echo -n " ¿Did you Create a Separate /tmp partition during the Initial Installation? (y/n): "; read -r tmp_answer
	# Change behaviour to require explicit "y"
  if [ "$tmp_answer" == "y" ]; then
      echo "Nice Going, Remember to set proper permissions in /etc/fstab"
      echo ""
      echo "Example:"
      echo ""
      echo "/dev/sda4   /tmp   tmpfs  loop,nosuid,noexec,rw  0 0 "
      say_done
  else
      echo "We will create a FileSystem for the /tmp Directory and set Proper Permissions "
      spinner
			# May not actually be a valid fstab entry on Linux, modeled after usage on DragonFly BSD
			# however, only minor modification should be necessary to ensure correct flags are set
      echo "tmpfs  /tmp    tmpfs   loop,nosuid,nodev,noexec,mode=1777,uid=0,gid=0,size=2g,rw  0 0" >> /etc/fstab\
				&& perr "On the next reboot run 'rm -rf /tmp/* && reboot' to ensure settings are applied correctly"
      say_done
  fi
}

##############################################################################################################

# Secure SSH
secure_ssh(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Securing SSH"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " Securing SSH..."
    spinner
    sed s/USERNAME/"${username}"/g templates/sshd_config > /etc/ssh/sshd_config && echo "OK"\
			&& service ssh restart\
			&& chattr -i /home/"${username}"/.ssh/authorized_keys
    say_done
}

##############################################################################################################

# Set IPTABLES Rules
set_iptables(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Setting IPTABLE RULES"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " Setting Iptables Rules..."
    spinner
    sh templates/iptables.sh\
			&& cp templates/iptables.sh /etc/init.d/\
			&& chmod +x /etc/init.d/iptables.sh\
			&& ln -s /etc/init.d/iptables.sh /etc/rc2.d/S99iptables.sh
    say_done
}

##############################################################################################################

# Install fail2ban
    # To Remove a Fail2Ban rule use:
    # iptables -D fail2ban-ssh -s IP -j DROP
install_fail2ban(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing Fail2Ban"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
		## XXX: This should be replaced with something like dma or opensmtpd
		MTA="sendmail"
    apt install "${MTA}" fail2ban
    say_done
}

##############################################################################################################

# Install, Configure and Optimize MySQL
install_secure_mysql(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing, Configuring and Optimizing MySQL"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt install mysql-server
    printf "\n configuring MySQL............ "
    spinner
    cp templates/mysql /etc/mysql/mysqld.cnf && echo " OK"\
			&& mysql_secure_installation\
			&& cp templates/usr.sbin.mysqld /etc/apparmor.d/local/usr.sbin.mysqld\
			&& service mysql restart
    say_done
}

##############################################################################################################

# Install Apache
install_apache(){
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Installing Apache Web Server"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  apt install apache2
  say_done
}

##############################################################################################################

# Install Nginx
install_nginx(){
  f_banner 
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Installing NginX Web Server"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
	perr "Updating repos to include Nginx PPA"
  echo "deb http://nginx.org/packages/ubuntu/ bionic nginx" >> /etc/apt/sources.list
  echo "deb-src http://nginx.org/packages/ubuntu/ bionic nginx" >> /etc/apt/sources.list
  curl -O https://nginx.org/keys/nginx_signing.key\
		&& apt-key add ./nginx_signing.key\
		&& apt update\
		&& apt install nginx
  say_done
}

##############################################################################################################

#Compile ModSecurity for NginX

compile_modsec_nginx(){
  f_banner 
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Install Prerequisites and Compiling ModSecurity for NginX"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""

	apt install bison flex make automake gcc pkg-config libtool doxygen git curl zlib1g-dev libxml2-dev libpcre3-dev build-essential libyajl-dev yajl-tools liblmdb-dev rdmacm-utils libgeoip-dev libcurl4-openssl-dev liblua5.2-dev libfuzzy-dev openssl libssl-dev

	# Start a subshell since we're changing directory
	(
		cd /opt/ && git clone https://github.com/SpiderLabs/ModSecurity

		cd ModSecurity\
			&& git checkout v3/master\
			&& git submodule init\
			&& git submodule update\
			&& ./build.sh\
			&& ./configure\
			&& make\
			&& make install

		cd ..

		nginx_version=$(dpkg -l |grep nginx | awk '{print $3}' | cut -d '-' -f1)

		wget "http://nginx.org/download/nginx-${nginx_version}.tar.gz"\
			&& tar xzvf "nginx-${nginx_version}.tar.gz"

		git clone https://github.com/SpiderLabs/ModSecurity-nginx

		cd "nginx-${nginx_version}"\
			&& ./configure --with-compat --add-dynamic-module=/opt/ModSecurity-nginx\
			&& make modules\
			&& cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/

		cd /etc/nginx/ || perr "Cannot chdir to /etc/nginx!"

		mkdir -p /etc/nginx/modsec
		cd /etc/nginx/modsec\
			&& git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git\
			&& mv /etc/nginx/modsec/owasp-modsecurity-crs/crs-setup.conf.example /etc/nginx/modsec/owasp-modsecurity-crs/crs-setup.conf\
			&& cp /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf\
			&& printf "Include /etc/nginx/modsec/%s\n"\
				"modsecurity.conf"\
				"owasp-modsecurity-crs/crs-setup.conf"\
				'owasp-modsecurity-crs/rules/*.conf'\
				>> /etc/nginx/modsec/main.conf\
			&& wget -P /etc/nginx/modsec/ https://github.com/SpiderLabs/ModSecurity/raw/v3/master/unicode.mapping
	)

  f_banner 
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Configuring ModSecurity for NginX"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  spinner
  cp templates/nginx /etc/nginx/nginx.conf\
		&& cp templates/nginx_default /etc/nginx/conf.d/default.conf\
		&& service nginx restart
  say_done

}

##############################################################################################################

# Install, Configure and Optimize PHP
install_secure_php(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing, Configuring and Optimizing PHP"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    apt install -y php php-cli php-pear php-mysql python-mysqldb libapache2-mod-php7.2
    echo ""
    echo -n " Replacing php.ini..."
    spinner
    cp templates/php /etc/php/7.2/apache2/php.ini; echo " OK"
    cp templates/php /etc/php/7.2/cli/php.ini; echo " OK"
    service apache2 restart
    say_done
}

##############################################################################################################

# Install, Configure and Optimize PHP for Nginx
install_secure_php_nginx(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing, Configuring and Optimizing PHP for NginX"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt install -y php-fpm php-mysql
    echo ""
    echo -n " Removing insecure configuration on php.ini..."
    spinner
    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.2/fpm/php.ini; echo " OK"
    service php7.2-fpm restart
    say_done
}

##############################################################################################################

# Install ModSecurity
install_modsecurity(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing ModSecurity"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt install libxml2 libxml2-dev libxml2-utils libaprutil1 libaprutil1-dev libapache2-mod-security2\
			&& service apache2 restart
    say_done
}

##############################################################################################################

# Configure OWASP ModSecurity Core Rule Set (CRS3)
set_owasp_rules(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Setting UP OWASP ModSecurity Core Rule Set (CRS3)"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"

    spinner
    echo "OK"

    sed s/SecRuleEngine\ DetectionOnly/SecRuleEngine\ On/g /etc/modsecurity/modsecurity.conf-recommended > salida\
			&& mv salida /etc/modsecurity/modsecurity.conf

		printf "%s\n"\
			'SecServerSignature "AntiChino Server 1.0.4 LS"'\
			'Header set X-Powered-By "Plankalkül 1.0"'\
			'Header set X-Mamma "Mama mia let me go"'\
			>> /usr/share/modsecurity-crs/modsecurity_crs_10_setup.conf\
			&& a2enmod headers\
			&& service apache2 restart
    say_done
}

##############################################################################################################

# Configure and optimize Apache
secure_optimize_apache(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Optimizing Apache"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    cp templates/apache /etc/apache2/apache2.conf
    echo " -- Enabling ModRewrite"
    spinner
    a2enmod rewrite && service apache2 restart
    say_done
}

##############################################################################################################

# Install ModEvasive
install_modevasive(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing ModEvasive"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    printf " Type Email to Receive Alerts "; read -r inbox
    apt install libapache2-mod-evasive\
			&& mkdir /var/log/mod_evasive\
			&& chown www-data:www-data /var/log/mod_evasive/\
			&& sed s/MAILTO/"${inbox}"/g templates/mod-evasive > /etc/apache2/mods-available/mod-evasive.conf\
			&& service apache2 restart
    say_done
}

##############################################################################################################

# Install Mod_qos/spamhaus
install_qos_spamhaus(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing Mod_Qos/Spamhaus"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt -y install libapache2-mod-qos libapache2-mod-spamhaus\
			&& cp templates/qos /etc/apache2/mods-available/qos.conf\
			&& cp templates/spamhaus /etc/apache2/mods-available/spamhaus.conf\
			&& service apache2 restart
    say_done
}

##############################################################################################################

# Configure fail2ban
config_fail2ban(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Configuring Fail2Ban"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo " Configuring Fail2Ban......"
    spinner
    sed s/MAILTO/"${inbox}"/g templates/fail2ban > /etc/fail2ban/jail.local\
			&& cp /etc/fail2ban/jail.local /etc/fail2ban/jail.conf\
			&& /etc/init.d/fail2ban restart
    say_done
}

##############################################################################################################

# Install Additional Packages
additional_packages(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing Additional Packages"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
		## XXX: This should be a loop to collect which packages to install
    echo "Install tree............."; apt install tree
    echo "Install Python-MySQLdb..."; apt install python-mysqldb
    echo "Install WSGI............."; apt install libapache2-mod-wsgi
    echo "Install PIP.............."; apt install python-pip
    echo "Install Vim.............."; apt install vim
    echo "Install Nano............."; apt install nano
    echo "Install pear............."; apt install php-pear
    echo "Install DebSums.........."; apt install debsums
    echo "Install apt-show-versions"; apt install apt-show-versions
    echo "Install PHPUnit..........";
    pear config-set auto_discover 1
    mv phpunit-patched /usr/share/phpunit
    echo include_path = ".:/usr/share/phpunit:/usr/share/phpunit/PHPUnit" >> /etc/php/7.2/cli/php.ini
    echo include_path = ".:/usr/share/phpunit:/usr/share/phpunit/PHPUnit" >> /etc/php/7.2/apache2/php.ini
    service apache2 restart
    say_done
}

##############################################################################################################

# Tune and Secure Kernel
tune_secure_kernel(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Tuning and Securing the Linux Kernel"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo " Securing Linux Kernel"
    spinner
    echo "* hard core 0" >> /etc/security/limits.conf
    cp templates/sysctl.conf /etc/sysctl.conf; echo " OK"
    cp templates/ufw /etc/default/ufw
    sysctl -e -p
    say_done
}

##############################################################################################################

# Install RootKit Hunter
install_rootkit_hunter(){
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
		(
			cd rkhunter-1.4.6/\
				&& sh installer.sh --layout /usr --install
		) && rkhunter --update && rkhunter --propupd
    echo ""
    echo " ***To Run RootKit Hunter ***"
    echo "     rkhunter -c --enable all --disable none"
    echo "     Detailed report on /var/log/rkhunter.log"
    say_done
}

##############################################################################################################

# Tuning
tune_nano_vim_bashrc(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Tuning bashrc, nano and Vim"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""

# Tune .bashrc
    echo "Tuning .bashrc......"
    spinner
    cp templates/bashrc-root /root/.bashrc\
			&& cp templates/bashrc-user /home/"${username}"/.bashrc\
			&& chown "${username}":"${username}" /home/"${username}"/.bashrc
    echo "OK"


# Tune Vim
    echo "Tuning Vim......"
    spinner
    tuning vimrc
    echo "OK"


# Tune Nano
    echo "Tuning Nano......"
    spinner
    tuning nanorc
    echo "OK"
    say_done
}

##############################################################################################################

# Add Daily Update Cron Job
daily_update_cronjob(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Adding Daily System Update Cron Job"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Creating Daily Cron Job"
    spinner
    job="@daily apt update; apt dist-upgrade -y"
    touch job\
			&& echo "${job}" > job\
			&& crontab job\
			&& rm job
    say_done
}

##############################################################################################################

# Install PortSentry
install_portsentry(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing PortSentry"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt install portsentry\
			&& mv /etc/portsentry/portsentry.conf /etc/portsentry/portsentry.conf-original\
			&& cp templates/portsentry /etc/portsentry/portsentry.conf\
			&& sed s/tcp/atcp/g /etc/default/portsentry > salida.tmp\
			&& mv salida.tmp /etc/default/portsentry\
			&& /etc/init.d/portsentry restart
    say_done
}

##############################################################################################################

# Install and Configure Artillery
install_artillery (){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Cloning Repo and Installing Artillery"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
		(
			git clone https://github.com/BinaryDefense/artillery\
				&& cd artillery/\
				&& python setup.py
		)
    echo ""
    echo "Setting Iptable rules for artillery"
    spinner
		printf "iptables -A INPUT -p tcp -m tcp --dport %d -j ACCEPT\n"\
				"22"\
				"1433"\
				"8080"\
				"21"\
				"5900"\
				"53"\
				"110"\
				"1723"\
				"1337"\
				"10000"\
				"5800"\
				"44443"\
				"16993"\
				>> /etc/init.d/iptables.sh
    echo ""
    echo "Artillery configuration file is /var/artillery/config"
    say_done  
}
##############################################################################################################

# Additional Hardening Steps
additional_hardening(){
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
    #Remove AT and Restrict Cron
    apt purge at && apt install -y libpam-cracklib
    echo ""
    echo " Securing Cron "
    spinner
    touch /etc/cron.allow
    chmod 600 /etc/cron.allow
    awk -F: '$1 !~ /root/ {print $1;}' /etc/passwd > /etc/cron.deny
    echo ""
    echo -n " Do you want to Disable USB Support for this Server? (y/n): " ; read -r usb_answer
    if [ "$usb_answer" == "y" ]; then
       echo ""
       echo "Disabling USB Support"
       spinner
       echo "blacklist usb-storage" | sudo tee -a /etc/modprobe.d/blacklist.conf
       update-initramfs -u
       echo "OK"
    else
       echo "OK"
    fi
		say_done
}

##############################################################################################################

# Install Unhide
install_unhide(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing UnHide"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Unhide is a forensic tool to find hidden processes and TCP/UDP ports by rootkits / LKMs or by another hidden technique."
    sleep 1
    apt -y install unhide
    echo ""
    echo " Unhide is a tool for Detecting Hidden Processes "
    echo " For more info about the Tool use the manpages "
    echo " man unhide "
    say_done
}

##############################################################################################################

# Install Tiger
#Tiger is and Auditing and Intrusion Detection System
install_tiger(){
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing Tiger"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Tiger is a security tool that can be use both as a security audit and intrusion detection system"
    sleep 1
    apt -y install tiger
    echo ""
    echo " For More info about the Tool use the ManPages "
    echo " man tiger "
    say_done
}

##############################################################################################################

#Install PSAD
#PSAD actively monitors firewall logs to determine if a scan or attack is taking place
install_psad(){
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
echo -n " Do you want to install PSAD (Recommended)? (y/n): " ; read -r psad_answer
if [ "$psad_answer" == "y" ]; then
     echo -n " Type an Email Address to Receive PSAD Alerts: " ; read -r inbox1
     apt install psad\
			 && sed -i s/INBOX/"${inbox1}"/g templates/psad.conf\
			 && sed -i s/CHANGEME/"${host_name}.${domain_name}"/g templates/psad.conf  \
			 && cp templates/psad.conf /etc/psad/psad.conf\
			 && psad --sig-update\
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
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Disabling Compilers"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Disabling Compilers....."
    spinner
		for x in as byacc yacc bcc kgcc cc gcc cpp;
		do
			if [ "${x}" = cpp ]
			then
				chmod 000 /usr/bin/*c++ >/dev/null 2<&-
				chmod 000 /usr/bin/*g++ >/dev/null 2<&-
			else
				chmod 000 "/usr/bin/${x}" >/dev/null 2<&-
			fi
		done
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
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Enable Unattended Security Updates"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  echo -n " ¿Do you Wish to Enable Unattended Security Updates? (y/n): "; read -r unattended
  if [ "$unattended" == "y" ]; then
      dpkg-reconfigure -plow unattended-upgrades
  else
      clear
  fi
}

##############################################################################################################

# Enable Process Accounting
enable_proc_acct(){
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Enable Process Accounting"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  apt install acct && touch /var/log/wtmp
  echo "OK"
}

##############################################################################################################

#Install and enable auditd

install_auditd(){
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Installing auditd"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  apt install auditd

  # Using CIS Benchmark configuration
  
  #Ensure auditing for processes that start prior to auditd is enabled 
  echo ""
  echo "Enabling auditing for processes that start prior to auditd"
  spinner
  sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="audit=1"/g' /etc/default/grub
  update-grub

  echo ""
  echo "Configuring Auditd Rules"
  spinner

  cp templates/audit-CIS.rules /etc/audit/rules.d/audit.rules

  find / -xdev \( -perm -4000 -o -perm -2000 \) -type f | awk '{print \
  "-a always,exit -F path=" $1 " -F perm=x -F auid>=1000 -F auid!=4294967295 \
  -k privileged" } ' >> /etc/audit/rules.d/audit.rules

  echo " " >> /etc/audit/rules.d/audit.rules
  echo "#End of Audit Rules" >> /etc/audit/rules.d/audit.rules
  echo "-e 2" >>/etc/audit/rules.d/audit.rules

  systemctl enable auditd.service
  service auditd restart
  echo "OK"
  say_done
}
##############################################################################################################

#Install and Enable sysstat

install_sysstat(){
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Installing and enabling sysstat"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  apt install sysstat\
		&& sed -i 's/ENABLED="false"/ENABLED="true"/g' /etc/default/sysstat\
		&& service sysstat start
  echo "OK"
  say_done
}

##############################################################################################################

#Install ArpWatch

install_arpwatch(){
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m ArpWatch Install"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  echo "ArpWatch is a tool for monitoring ARP traffic on System. It generates log of observed pairing of IP and MAC."
  echo ""
  echo -n " Do you want to Install ArpWatch on this Server? (y/n): " ; read -r arp_answer
  if [ "$arp_answer" == "y" ]; then
     echo "Installing ArpWatch"
     spinner
     apt install -y arpwatch\
			 && systemctl enable arpwatch.service\
			 && service arpwatch start
     echo "OK"
     say_done
  else
     echo "OK"
     say_done
  fi
}

##############################################################################################################

set_grubpassword(){
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m GRUB Bootloader Password"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  echo "It is recommended to set a password on GRUB bootloader to prevent altering boot configuration (e.g. boot in single user mode without password)"
  echo ""
  echo -n " Do you want to set a GRUB Bootloader Password? (y/n): " ; read -r grub_answer
  if [ "$grub_answer" == "y" ]; then
    grub-mkpasswd-pbkdf2 | tee grubpassword.tmp
    grubpassword=$(sed -e '1,2d' grubpassword.tmp | cut -d ' ' -f7)
    printf "%s\n"\
			"set superusers=\"root\""\
			"password_pbkdf2 root ${grubpassword} "\
			>> /etc/grub.d/40_custom\
			&& rm grubpassword.tmp\
			&& update-grub
    echo "On every boot enter root user and the password you just set"
  fi
	echo "OK"
	say_done

	echo -e ""
	echo -e "Securing Boot Settings"
	spinner
	sleep 2
	chown root:root /boot/grub/grub.cfg
	chmod og-rwx /boot/grub/grub.cfg
	say_done

}    

##############################################################################################################

file_permissions(){
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Setting File Permissions on Critical System Files"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  spinner
  sleep 2
  chmod -R g-wx,o-rwx /var/log/*

  chown root:root /etc/ssh/sshd_config
  chmod og-rwx /etc/ssh/sshd_config

  chown root:root /etc/passwd
  chmod 644 /etc/passwd

  chown root:shadow /etc/shadow
  chmod o-rwx,g-wx /etc/shadow

  chown root:root /etc/group
  chmod 644 /etc/group

  chown root:shadow /etc/gshadow
  chmod o-rwx,g-rw /etc/gshadow

  chown root:root /etc/passwd-
  chmod 600 /etc/passwd-

  chown root:root /etc/shadow-
  chmod 600 /etc/shadow-

  chown root:root /etc/group-
  chmod 600 /etc/group-

  chown root:root /etc/gshadow-
  chmod 600 /etc/gshadow-


  echo -e ""
  echo -e "Setting Sticky bit on all world-writable directories"
  sleep 2
  spinner

  df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t

  echo " OK"
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
    sed -i s/USERNAME/"${username}"/g templates/texts/bye
    sed -i s/SERVERIP/"${serverip}"/g templates/texts/bye
    cat templates/texts/bye
    echo -n " ¿Were you able to connect via SSH to the Server using $username? (y/n): "; read -r answer
    if [ "$answer" == "y" ]; then
        rm -rf /tmp/* ; reboot
    else
        echo "Server will not Reboot"
        echo "Bye."
    fi
}

##################################################################################################################

main() {
	f_banner
	echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
	echo -e "\e[93m[+]\e[00m SELECT THE DESIRED OPTION"
	echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
	echo ""
	printf "\t%d. %s\n"\
		"1" "LAMP Deployment"\
		"2" "LEMP Deployment"\
		"3" "Reverse Proxy Deployment With Apache"\
		"4" "General Purpose (without WebServer or DBServer)"\
		"5" "Running With SecureWPDeployer or JSDeployer Script"\
		"6" "Customized Run (Only run desired Options)"\
		"7" "CIS Benchmark Hardening"\
		"8" "Exit"

	read -r choice; case $choice in

	1)
	check_root
	install_dep
	config_host
	config_timezone
	update_system
	restrictive_umask
	unused_filesystems
	uncommon_netprotocols
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
	install_artillery
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
	set_grubpassword
	file_permissions
	reboot_server
	;;


	2)
	check_root
	install_dep
	config_host
	config_timezone
	update_system
	restrictive_umask
	unused_filesystems
	uncommon_netprotocols
	admin_user
	rsa_keygen
	rsa_keycopy
	secure_ssh
	set_iptables
	install_fail2ban
	install_secure_mysql
	install_nginx
	compile_modsec_nginx
	install_secure_php_nginx
	config_fail2ban
	additional_packages
	tune_secure_kernel
	install_rootkit_hunter
	tune_nano_vim_bashrc
	daily_update_cronjob
	install_artillery
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
	set_grubpassword
	file_permissions
	reboot_server
	;;

	3)
	check_root
	install_dep
	config_host
	config_timezone
	update_system
	restrictive_umask
	unused_filesystems
	uncommon_netprotocols
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
	install_artillery
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
	set_grubpassword
	file_permissions
	reboot_server
	;;

	4)
	check_root
	install_dep
	config_host
	config_timezone
	update_system
	restrictive_umask
	unused_filesystems
	uncommon_netprotocols
	admin_user
	rsa_keygen
	rsa_keycopy
	secure_ssh
	set_iptables
	install_fail2ban
	config_fail2ban
	additional_packages
	tune_secure_kernel
	install_rootkit_hunter
	tune_nano_vim_bashrc
	daily_update_cronjob
	install_artillery
	additional_hardening
	install_unhide
	install_tiger
	install_psad
	disable_compilers
	secure_tmp
	unattended_upgrades
	enable_proc_acct
	install_auditd
	install_arpwatch
	set_grubpassword
	file_permissions
	;;


	5)
	check_root
	install_dep
	config_host
	config_timezone
	update_system
	restrictive_umask
	unused_filesystems
	uncommon_netprotocols
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
	install_artillery
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
	set_grubpassword
	file_permissions
	;;

	6)

	menu=""
	until [ "$menu" = "34" ]; do

	clear
	f_banner
	echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
	echo -e "\e[93m[+]\e[00m SELECT THE DESIRED OPTION"
	echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
	echo ""
	printf "\t%d. %s\n"\
		"1" "Configure Host Name, Create Legal Banners, Update Hosts Files"\
		"2" "Configure Timezone"\
		"3" "Update System"\
		"4" "Create Admin User"\
		"5" "Instructions to Generate and move Private/Public key Pair"\
		"6" "Secure SSH Configuration"\
		"7" "Set Restrictive IPTable Rules"\
		"8" "Install and Configure Fail2Ban"\
		"9" "Install, Optimize and Secure Apache"\
		"10" "Install Nginx with ModSecurity Module and Set OwaspRules"\
		"11" "Set Nginx Vhost with PHP"\
		"12" "Set Nginx Vhost"\
		"13" "Install and Secure PHP for Apache Server"\
		"14" "Install and Secure PHP for Nginx Server"\
		"15" "Install ModSecurity (Apache)and Set Owasp Rules"\
		"16" "Install ModEvasive"\
		"17" "Install ModQos and SpamHaus"\
		"18" "Tune and Secure Linux Kernel"\
		"19" "Install RootKit Hunter"\
		"20" "Tune Vim, Nano, Bashrc"\
		"21" "Install PortSentry"\
		"22" "Secure tty, root home, grub configs, cron"\
		"23" "Install Unhide"\
		"24" "Install Tiger"\
		"25" "Disable Compilers"\
		"26" "Enable Unnatended Upgrades"\
		"27" "Enable Process Accounting"\
		"28" "Install PHP Suhosin (Disabled for Now)"\
		"29" "Install and Secure MySQL"\
		"30" "Set More Restrictive UMASK Value (027)"\
		"31" "Secure /tmp Directory"\
		"32" "Install PSAD IDS"\
		"33" "Set GRUB Bootloader Password"\
		"34" "Exit"

	read -r menu; case $menu in

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
	echo "What user will have access via SSH? " ; read -r username
	rsa_keygen
	rsa_keycopy
	secure_ssh
	;;

	7)
	set_iptables
	;;

	8)
	echo "Type Email to receive Alerts: " ; read -r inbox
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

	#28)
	#install_phpsuhosin
	#;;

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
	set_grubpassword
	;;

	34)
	break ;;

	*) ;;

	esac
	done
	;;

	7)
	chmod +x jshielder-CIS.sh
	./jshielder-CIS.sh
	;;


	8)
	exit 0
	;;

	esac
}

##############################################################################################################
main

