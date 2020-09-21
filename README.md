# JShielder

**JShielder Automated Hardening Script for Linux Servers**

JSHielder is an Open Source Bash Script developed to help SysAdmin and developers secure there Linux Servers in which they will be deploying any web application or services. This tool automates the process of installing all the necessary packages to host a web application and Hardening a Linux server with little interaction from the user. Newly added script follows CIS Benchmark Guidance to establish a Secure configuration posture for Linux systems.

This tool is a Bash Script that hardens the Linux Server security automatically and the steps followed are:

* Configures a hostname
* Reconfigures the timezone
* Updates the entire System
* Creates a new admin user so you can manage your server safely without the need of doing remote connections with root.
* Helps the user generate Secure RSA Keys, so that remote access to your server is done exclusive from your local pc and no conventional password
* Configures, optimizes and secures the SSH Server (Some Settings Following CIS Benchmark)
* Configures IPTABLES rules to protect the server from common attacks
* Disables unused fileSystems and network protocols
* Protects the server against Brute Force attacks by installing and configuring fail2ban
* Installs and configures Artillery as a Honeypot, Monitoring, Blocking and Alerting tool
* Installs PortSentry
* Installs, configures, and optimizes MySQL
* Installs the Apache Web Server
* Installs, configures and secures PHP
* Secures Apache via configuration file and with installation of the Modules ModSecurity with the OWASP ModSecurity Core Rule Set (CRS3), ModEvasive, Qos and SpamHaus
* Secures NginX with the Installation of ModSecurity NginX module and the OWASP ModSecurity Core Rule Set (CRS3)
* Installs RootKit Hunter
* Secures root home and grub configuration files
* Installs Unhide to help detect malicious hidden processes
* Installs Tiger, A security auditing and Intrusion Prevention System
* Restricts access to Apache config files
* Disables compilers
* Creates Daily cronjob for system updates
* Hardens the kernel via sysctl configuration file (Tweaked)
* /tmp directory hardening
* PSAD IDS installation
* Enables Process Accounting
* Enables Unattended Upgrades
* MOTD and Banners for Unauthorized access
* Disables USB Support for Improved Security (Optional)
* Configures a restrictive default UMASK
* Configures and enables Auditd
* Configures Auditd rules following CIS benchmark 
* Installs Sysstat
* Installs ArpWatch
* Additional Hardening steps following CIS Benchmark
* Secures cron
* Automates the process of setting a GRUB bootloader password
* Secures Boot Settings
* Sets Secure File Permissions for Critical System Files

#NEW!!

* LEMP Deployment with ModSecurity and the OWASP ModSecurity Core Rule Set (CRS3)


# CIS Benchmark JShielder Script Added

* Separate Hardening Script Following CIS Benchmark Guidance
  https://www.cisecurity.org/benchmark/ubuntu_linux/


# To Run the tool


./jshielder.sh

As the Root user


# Issues


Having Problems, please open a New Issue for JShielder on Github.

# Distro Availability

* Ubuntu Server 16.04LTS
* Ubuntu Server 18.04LTS

# ChangeLog

v2.4 Added LEMP Deployment with ModSecurity and the OWASP ModSecurity Core Rule Set (CRS3)

v2.3 More Hardening steps Following some CIS Benchmark items for LAMP Deployer

v2.2.1 Removed suhosing installation on Ubuntu 16.04, Fixed MySQL Configuration, GRUB Bootloader Setup function,
Server IP now obtain via ip route to not rely on interface naming

v2.2 Added new Hardening option following CIS Benchmark Guidance

v2.1 Hardened SSH Configuration, Tweaked Kernel Security Config, Fixed iptables rules not loading on Boot. Added auditd, sysstat, arpwatch install.

v2.0 More Deployment Options, Selection Menu, PHP Suhosin installation, Cleaner Code,

v1.0 - New Code


Developed by ***Jason Soto***

https://www.jasonsoto.com

https://github.com/jsitech

Twitter = [**@JsiTech**](http://www.twitter.com/JsiTech)
