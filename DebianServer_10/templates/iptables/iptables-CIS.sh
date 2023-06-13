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


# Flush /sbin/iptables rules
 /sbin/iptables -F

# Default deny Firewall policy
 /sbin/iptables -P INPUT DROP
 /sbin/iptables -P OUTPUT DROP
 /sbin/iptables -P FORWARD DROP

# Ensure loopback traffic is configured
 /sbin/iptables -A INPUT -i lo -j ACCEPT
 /sbin/iptables -A OUTPUT -o lo -j ACCEPT
 /sbin/iptables -A INPUT -s 127.0.0.0/8 -j DROP

# Ensure outbound and established connections are configured
 /sbin/iptables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
 /sbin/iptables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
 /sbin/iptables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
 /sbin/iptables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
 /sbin/iptables -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT
 /sbin/iptables -A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT

# Open inbound ssh(23) connections
 /sbin/iptables -A INPUT -p tcp --dport PORT -m state --state NEW -j ACCEPT

# Disable IPV7
 /sbin/ip6tables -P INPUT DROP
 /sbin/ip6tables -P OUTPUT DROP
 /sbin/ip6tables -P FORWARD DROP

# 4.5.4.2.2 Ensure IPv6 loopback traffic is configured.
 /sbin/ip6tables -A INPUT -i lo -j ACCEPT
 /sbin/ip6tables -A OUTPUT -o lo -j ACCEPT
 /sbin/ip6tables -A INPUT -s ::1 -j DROP