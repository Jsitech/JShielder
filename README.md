# JShielder



###JShielder Automated Hardening Script for Linux Servers

JSHielder is an Open Source tool developed to help SysAdmin and developers secure there Linux Servers in which they will be deploying any web application or services. This tool automates the process of installing all the necessary packages to host a web application and Hardening a Linux server with little interaction from the user. Newly added script follows CIS Benchmark Guidance to establish a Secure configuration posture for Linux systems.

This tool is a Bash Script that hardens the Linux Server security automatically and the steps followed are:

* Configures a Hostname
* Reconfigures the Timezone
* Updates the entire System
* Creates a New Admin user so you can manage your server safely without the need of doing remote connections with root.
* Helps user Generate Secure RSA Keys, so that remote access to your server is done exclusive from your local pc and no Conventional password
* Configures, Optimize and secures the SSH Server (Some Settings Following CIS Benchmark Ubuntu 16.04)
* Configures IPTABLES Rules to protect the server from common attacks
* Protects the server against Brute Force attacks by installing a configuring fail2ban
* Stop Portscans by blocking intrusive IP via IPTABLES using portsentry
* Install, configure, and optimize MySQL
* Install the Apache Web Server
* Install, configure and secure PHP
* Secure Apache via configuration file and with installation of the Modules ModSecurity, ModEvasive, Qos and SpamHaus
* Installs RootKit Hunter
* Secures Root Home and Grub Configuration Files
* Installs Unhide to help Detect Malicious Hidden Processes
* Installs Tiger, A Security Auditing and Intrusion Prevention system
* Restrict Access to Apache Config Files
* Disable Compilers
* Creates Daily Cron job for System Updates
* Kernel Hardening via sysctl configuration File (Tweaked)

# Other Hardening Steps


* Added PHP Suhosin Installation to protect PHP Code and Core for Known and Unknown flaws (Removed on Ubuntu 16.04)
* Use of Function for code execution customization
* Distro Selection Menu
* Function Selection Menu
* Deployment Selection Menu (LAMP, LEMP, Reverse Proxy)
* Added LEMP Deployment with ModSecurity
* Added /tmp folder Hardening
* Added PSAD IDS installation
* Added Process Accounting
* Added Unattended Upgrades
* Added MOTD and Banners for Unauthorized access
* Disable USB Support for Improved Security (Optional)
* Restrictive Default UMASK
* Added Additional Hardening Steps
* Auditd install (New)
* Sysstat install (New)
* ArpWatch install (New)
* Hardening steps following CIS Benchmark
* Secures Cron
* Disables Unused Filesystems and Uncommon Network protocols
* Configure Auditd rules following CIS benchmark (Ubuntu 16.04)
* Automates the process of setting a GRUB Bootloader Password
* Secures Boot Settings
* Sets Secure File Permissions for Critical System Files


# NEWLY ADDED FUNCTION

* Separate Hardening Script Following CIS Benchmark Guidance
  https://www.cisecurity.org/benchmark/ubuntu_linux/ (Ubuntu 16.04)


# To Run the tool


./jshielder.sh

As the Root user


# Issues


Having Problems, please open a New Issue for JShielder on Github.

# Notes

After Final Release of Ubuntu 18.04LTS, will not be maintaining Jshielder for Ubuntu 14.04. Will focus on last 2 major LTS Releases.

# ChangeLog

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
