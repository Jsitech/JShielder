# 1.1.2.1: Ensure /tmp is a separate partition. (On Installation)
# 1.1.2.2: Ensure nodev option set on /tmp partition. (Requires separate partition)
# 1.1.2.3: Ensure noexec option set on /tmp partition. (Requires separate partition)
# 1.1.2.4: Ensure nosuid option set on /tmp partition. (Requires separate partition)
# 1.1.3.1: Ensure separate partition exists for /var. (On Installation)
# 1.1.3.2: Ensure nodev option set on /var partition. (Requires separate partition)
# 1.1.3.3: Ensure nosuid option set on /var partition. (Requires separate partition)
# 1.1.4.1: Ensure separate partition exists for /var/tmp. (On Installation)
# 1.1.4.2: Ensure noexec option set on /var/tmp partition. (Requires seperate partition)
# 1.1.4.3: Ensure nosuid option set on /var/tmp partition. (Requires seperate partition)
# 1.1.4.4: Ensure nodev option set on /var/tmp partition. (Requires seperate partition)
# 1.1.5.1: Ensure separate partition exists for /var/log. (On Installation)
# 1.1.5.2: Ensure nodev option set on /var/log partition. (Requires seperate partition)
# 1.1.5.3: Ensure noexec option set on /var/log partition. (Requires seperate partition)
# 1.1.5.4: Ensure nosuid option set on /var/log partition. (Requires seperate partition)
# 1.1.6.1: Ensure separate partition exists for /var/log/audit. (On Installation)
# 1.1.6.2: Ensure noexec option set on /var/log/audit partition. (Requires seperate partition)
# 1.1.6.3: Ensure nodev option set on /var/log/audit partition. (Requires seperate partition)
# 1.1.6.4: Ensure nosuid option set on /var/log/audit partition. (Requires seperate partition)
# 1.1.7.1: Ensure separate partition exists for /home. (On Installation)
# 1.1.7.2: Ensure nodev option set on /home partition. (Requires seperate partition)
# 1.1.7.3: Ensure nosuid option set on /home partition. (Requires seperate partition)
# 1.1.8.1: Ensure nodev option set on /dev/shm partition. (Requires seperate partition)
# 1.1.8.2: Ensure noexec option set on /dev/shm partition. (Requires seperate partition)
# 1.1.8.3: Ensure nosuid option set on /dev/shm partition. (Requires seperate partition)
# 1.1.9: Disable Automounting.
## Check if autofs is installed or if there're packages depending on it.
if [ $(dpkg-query -W -f='${Status}' autofs 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  echo "autofs is not installed"
else
  echo "autofs is installed"
  apt remove --purge autofs -y
fi
if

# 1.3.1: Ensure AIDE is installed.
apt-get install -y aide
aideinit

# 1.3.2: Ensure filesystem integrity is regularly checked.
# Configure cron job for AIDE
echo "0 5 * * * /usr/bin/aide.wrapper --config /etc/aide/aide.conf --check" >> /etc/cron.d/aide
service cron restart

cp templates/aide/aidecheck.service /etc/systemd/system/aidecheck.service
cp templates/aide/aidecheck.timer /etc/systemd/system/aidecheck.timer

chmod 644 /etc/systemd/system/aidecheck.*
systemctl daemon-reload
systemctl enable --now aidecheck.service aidecheck.timer

# 1.4.1: Ensure bootloader password is set. (Skipped - Would require manual intervention on reboot).

# grub-mkpasswd-pbkdf2 | tee grubpassword.tmp
# grubpassword=$(cat grubpassword.tmp | sed -e '1,2d' | cut -d ' ' -f7)
# echo " set superusers="root" " >> /etc/grub.d/40_custom
# echo " password_pbkdf2 root $grubpassword " >> /etc/grub.d/40_custom
# rm grubpassword.tmp
# update-grub

# 1.4.2: Ensure permissions on bootloader config are configured.
chown root:root /boot/grub/grub.cfg
chmod u-wx,go-rwx /boot/grub/grub.cfg.

# 1.4.3: Ensure authentication required for single user mode. (Scored)
passwd root

# 1.5.2: Ensure prelink is not installed.
apt remove --purge prelink -y

# 1.5.3: Ensure Automatic Error Reporting is not enabled (Scored)
# 1.5.4: Ensure core dumps are restricted.
echo "* hard core 0" >> /etc/security/limits.conf
cp templates/sysctl/sysctl-CIS.conf /etc/sysctl.conf
sysctl -e -p

## Check if systemd-coredump is installed.
if [ $(dpkg-query -W -f='${Status}' systemd-coredump 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  echo "systemd-coredump is not installed"
else
  echo "systemd-coredump is installed"
  # Edit /etc/systemd/coredump.conf
  sed -i 's/#Storage=external/Storage=none/g' /etc/systemd/coredump.conf
  sed -i 's/#ProcessSizeMax=2G/ProcessSizeMax=0/g' /etc/systemd/coredump.conf
fi

# 1.6.1.1: Ensure AppArmor is installed.
apt install apparmor apparmor-utils -y

# 1.6.1.2: Ensure AppArmor is enabled in the bootloader configuration.
# Edit /etc/default/grub
sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="apparmor=1 security=apparmor"/g' /etc/default/grub
update-grub

# 1.6.1.3: Ensure all AppArmor Profiles are in enforce or complain mode.
aa-enforce /etc/apparmor.d/*
# aa-complain /etc/apparmor.d/*

# 1.6.1.4: Ensure all AppArmor Profiles are enforcing (Scored on 1.6.1.3)
# 1.7.1: Ensure message of the day is configured properly.
# 1.7.2: Ensure local login warning banner is configured properly.
# 1.7.3: Ensure remote login warning banner is configured properly.
cat templates/texts/motd-CIS > /etc/motd
cat templates/texts/motd-CIS > /etc/issue
cat templates/texts/motd-CIS > /etc/issue.net
# 1.7.4: Ensure permissions on /etc/motd are configured.
# 1.7.5: Ensure permissions on /etc/issue are configured.
# 1.7.6: Ensure permissions on /etc/issue.net are configured.
chown root:root /etc/motd /etc/issue /etc/issue.net
chmod u-x,go-wx /etc/motd /etc/issue /etc/issue.net

# 1.8.1: Ensure GNOME Display Manager is removed. (Scored)
# 1.8.10: Ensure XDCMP is not enabled (Scored)

# 1.9: Ensure updates, patches, and additional security software are installed.
apt update -y && apt upgrade -y && apt dist-upgrade -y

# 2.1.2.2: Ensure chrony is running as user _chrony.
echo "user _chrony" >> /etc/chrony/conf.d/chrony_user.conf

# 2.1.2.3: Ensure chrony is enabled and running.
systemctl unmask chrony.service
systemctl enable --now chrony.service


# IF CHRONY IS NOT USED, USE NTP
# apt remove --purge chrony -y

# 2.1.3.1: Ensure systemd-timesyncd configured with authorized timeserver.
apt install systemd-timesyncd -y
mkdir /etc/systemd/timesyncd.conf.d
cp templates/timesyncd/timesyncd.conf /etc/systemd/timesyncd.conf.d/50-timesyncd.conf

# 2.1.3.2: Ensure systemd-timesyncd is enabled and running.
systemctl mask --now systemd-timesyncd.service

## if chrony is used, disable systemd-timesyncd
# systemctl disable --now systemd-timesyncd.service
# systemctl mask systemd-timesyncd.service

# 2.1.4.1: Ensure ntp access control is configured. (scored)
# 2.1.4.2: Ensure ntp is configured with authorized timeserver.
cp templates/ntp/ntp.conf /etc/ntp.conf
system restart ntp

# 2.1.4.3: Ensure ntp is running as user ntp (Scored)
# 2.1.4.4: Ensure ntp is enabled and running.
systemctl enable --now ntp.service

# 2.2.1: Ensure X Window System is not installed.
apt purge xserver-xorg* -y

# 2.2.2: Ensure Avahi Server is not installed. (Scored)
# 2.2.3: Ensure CUPS is not installed. (Scored)
# 2.2.4: Ensure DHCP Server is not installed. (Scored)
# 2.2.5: Ensure LDAP server is not installed. (Scored)
# 2.2.6: Ensure NFS is not installed. (Scored)
# 2.2.7: Ensure DNS Server is not installed. (Scored)
# 2.2.8: Ensure FTP Server is not installed. (Scored)
# 2.2.9: Ensure HTTP server is not installed. (Scored)
# 2.2.10: Ensure IMAP and POP3 server are not installed. (Scored)
# 2.2.11: Ensure Samba is not installed. (Scored)
# 2.2.12: Ensure HTTP Proxy Server is not installed. (Scored)
# 2.2.13: Ensure SNMP Server is not installed. (Scored)
# 2.2.14: Ensure NIS Server is not installed. (Scored)
# 2.2.15: Ensure mail transfer agent is configured for local-only mode. (Scored)
# 2.2.16: Ensure rsync service is either not installed or masked. (Scored)
# 2.3.1: Ensure NIS Client is not installed. (Scored)
# 2.3.2: Ensure rsh client is not installed. (Scored)
# 2.3.3: Ensure talk client is not installed. (Scored)
# 2.3.4: Ensure telnet client is not installed. (Scored)
# 2.3.5: Ensure LDAP client is not installed. (Scored)
# 2.3.6: Ensure RPC is not installed. (Scored)

# 3.5.1.1: Ensure ufw is installed. (Not Applicable)
# 3.5.1.2: Ensure iptables-persistent is not installed with ufw.

# 3.5.1.3: Ensure ufw service is enabled. (Not Applicable)
# 3.5.1.4: Ensure ufw loopback traffic is configured. (Not Applicable)
# 3.5.1.7: Ensure ufw default deny firewall policy. (Not Applicable)
# 3.5.2.1: Ensure nftables is installed.


# 3.5.2.2: Ensure ufw is uninstalled or disabled with nftables.


# 3.5.2.3: Ensure iptables are flushed with nftables.


# 3.5.2.4: Ensure a nftables table exists.


# 3.5.2.5: Ensure nftables base chains exist.


# 3.5.2.6: Ensure nftables loopback traffic is configured.


# 3.5.2.8: Ensure nftables default deny firewall policy.


# 3.5.2.9: Ensure nftables service is enabled.


# 3.5.3.1.1: Ensure iptables packages are installed.


# 3.5.3.1.2: Ensure nftables is not installed with iptables.


# 3.5.3.1.3: Ensure ufw is uninstalled or disabled with iptables.


# 3.5.3.2.1: Ensure iptables default deny firewall policy.


# 3.5.3.2.2: Ensure iptables loopback traffic is configured.


# 3.5.3.3.1: Ensure ip6tables default deny firewall policy.


# 3.5.3.3.2: Ensure ip6tables loopback traffic is configured.


# 4.1.1.1: Ensure auditd is installed.


# 4.1.1.2: Ensure auditd service is enabled and active.


# 4.1.1.3: Ensure auditing for processes that start prior to auditd is enabled.


# 4.1.1.4: Ensure audit_backlog_limit is sufficient.


# 4.1.2.1: Ensure audit log storage size is configured.


# 4.1.2.2: Ensure audit logs are not automatically deleted.


# 4.1.2.3: Ensure system is disabled when audit logs are full.


# 4.1.3.1: Ensure changes to system administration scope (sudoers) is collected.


# 4.1.3.2: Ensure actions as another user are always logged.


# 4.1.3.4: Ensure events that modify date and time information are collected.


# 4.1.3.5: Ensure events that modify the system's network environment are collected.


# 4.1.3.7: Ensure unsuccessful file access attempts are collected.


# 4.1.3.8: Ensure events that modify user/group information are collected.


# 4.1.3.9: Ensure discretionary access control permission modification events are collected.


# 4.1.3.10: Ensure successful file system mounts are collected.


# 4.1.3.11: Ensure session initiation information is collected.


# 4.1.3.12: Ensure login and logout events are collected.


# 4.1.3.13: Ensure file deletion events by users are collected.


# 4.1.3.14: Ensure events that modify the system's Mandatory Access Controls are collected.


# 4.1.3.15: Ensure successful and unsuccessful attempts to use the chcon command are recorded.


# 4.1.3.16: Ensure successful and unsuccessful attempts to use the setfacl command are recorded.


# 4.1.3.17: Ensure successful and unsuccessful attempts to use the chacl command are recorded.


# 4.1.3.18: Ensure successful and unsuccessful attempts to use the usermod command are recorded.


# 4.1.3.19: Ensure kernel module loading unloading and modification is collected.


# 4.1.3.20: Ensure the audit configuration is immutable.


# 4.1.3.21: Ensure the running and on disk configuration is the same.


# 4.1.4.3: Ensure only authorized groups are assigned ownership of audit log files.


# 4.1.4.5: Ensure audit configuration files are 640 or more restrictive.


# 4.1.4.6: Ensure audit configuration files are owned by root.


# 4.1.4.7: Ensure audit configuration files belong to group root.


# 4.1.4.8: Ensure audit tools are 755 or more restrictive.


# 4.1.4.9: Ensure audit tools are owned by root.


# 4.1.4.10: Ensure audit tools belong to group root.


# 4.2.1.1.1: Ensure systemd-journal-remote is installed.


# 4.2.1.1.3: Ensure systemd-journal-remote is enabled.


# 4.2.1.1.4: Ensure journald is not configured to recieve logs from a remote client.


# 4.2.1.2: Ensure journald service is enabled.


# 4.2.1.3: Ensure journald is configured to compress large log files.


# 4.2.1.4: Ensure journald is configured to write logfiles to persistent disk.


# 4.2.1.5: Ensure journald is not configured to send logs to rsyslog.


# 4.2.2.1: Ensure rsyslog is installed.


# 4.2.2.2: Ensure rsyslog service is enabled.


# 4.2.2.3: Ensure journald is configured to send logs to rsyslog.


# 4.2.2.4: Ensure rsyslog default file permissions are configured.


# 4.2.2.7: Ensure rsyslog is not configured to receive logs from a remote client.


# 5.1.1: Ensure cron daemon is enabled and running.


# 5.1.2: Ensure permissions on /etc/crontab are configured.


# 5.1.3: Ensure permissions on /etc/cron.hourly are configured.


# 5.1.4: Ensure permissions on /etc/cron.daily are configured.


# 5.1.5: Ensure permissions on /etc/cron.weekly are configured.


# 5.1.6: Ensure permissions on /etc/cron.monthly are configured.


# 5.1.7: Ensure permissions on /etc/cron.d are configured.


# 5.1.8: Ensure cron is restricted to authorized users.


# 5.1.9: Ensure at is restricted to authorized users.


# 5.2.1: Ensure permissions on /etc/ssh/sshd_config are configured.


# 5.2.4: Ensure SSH access is limited.


# 5.2.5: Ensure SSH LogLevel is appropriate.


# 5.2.6: Ensure SSH PAM is enabled.


# 5.2.7: Ensure SSH root login is disabled.


# 5.2.8: Ensure SSH HostbasedAuthentication is disabled.


# 5.2.9: Ensure SSH PermitEmptyPasswords is disabled.


# 5.2.10: Ensure SSH PermitUserEnvironment is disabled.


# 5.2.11: Ensure SSH IgnoreRhosts is enabled.


# 5.2.12: Ensure SSH X11 forwarding is disabled.


# 5.2.13: Ensure only strong Ciphers are used.


# 5.2.14: Ensure only strong MAC algorithms are used.


# 5.2.15: Ensure only strong Key Exchange algorithms are used.


# 5.2.16: Ensure SSH AllowTcpForwarding is disabled.


# 5.2.17: Ensure SSH warning banner is configured.


# 5.2.18: Ensure SSH MaxAuthTries is set to 4 or less.


# 5.2.19: Ensure SSH MaxStartups is configured.


# 5.2.20: Ensure SSH MaxSessions is set to 10 or less.


# 5.2.21: Ensure SSH LoginGraceTime is set to one minute or less.


# 5.2.22: Ensure SSH Idle Timeout Interval is configured.


# 5.3.1: Ensure sudo is installed.


# 5.3.2: Ensure sudo commands use pty.


# 5.3.3: Ensure sudo log file exists.


# 5.3.4: Ensure users must provide password for privilege escalation.


# 5.3.5: Ensure re-authentication for privilege escalation is not disabled globally.


# 5.3.6: Ensure sudo authentication timeout is configured correctly.


# 5.3.7: Ensure access to the su command is restricted.


# 5.4.1: Ensure password creation requirements are configured.


# 5.4.2: Ensure lockout for failed password attempts is configured.


# 5.4.3: Ensure password reuse is limited.


# 5.4.4: Ensure password hashing algorithm is up to date with the latest standards.


# 5.5.1.1: Ensure minimum days between password changes is configured.


# 5.5.1.2: Ensure password expiration is 365 days or less.


# 5.5.1.3: Ensure password expiration warning days is 7 or more.


# 5.5.1.4: Ensure inactive password lock is 30 days or less.


# 5.5.3: Ensure default group for the root account is GID 0.


# 6.1.1: Ensure permissions on /etc/passwd are configured.


# 6.1.2: Ensure permissions on /etc/passwd- are configured.


# 6.1.3: Ensure permissions on /etc/group are configured.


# 6.1.4: Ensure permissions on /etc/group- are configured.


# 6.1.5: Ensure permissions on /etc/shadow are configured.


# 6.1.6: Ensure permissions on /etc/shadow- are configured.


# 6.1.7: Ensure permissions on /etc/gshadow are configured.


# 6.1.8: Ensure permissions on /etc/gshadow- are configured.


# 6.2.1: Ensure accounts in /etc/passwd use shadowed passwords.


# 6.2.2: Ensure /etc/shadow password fields are not empty.


# 6.2.10: Ensure root is the only UID 0 account.


