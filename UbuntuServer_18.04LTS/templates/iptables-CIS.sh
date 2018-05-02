#! /bin/sh
### BEGIN INIT INFO
# Provides:          iptables
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Applies Iptable Rules
# Description:
### END INIT INFO


# Flush Iptables rules
 iptables -F

# Default deny Firewall policy
 iptables -P INPUT DROP
 iptables -P OUTPUT DROP
 iptables -P FORWARD DROP

# Ensure loopback traffic is configured
 iptables -A INPUT -i lo -j ACCEPT
 iptables -A OUTPUT -o lo -j ACCEPT
 iptables -A INPUT -s 127.0.0.0/8 -j DROP

# Ensure outbound and established connections are configured
 iptables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
 iptables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
 iptables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
 iptables -A INPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
 iptables -A INPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
 iptables -A INPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT

# Open inbound ssh(22) connections
 iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT