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

iptables -F

#Defaults

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

#Rules for PSAD

iptables -A INPUT -j LOG
iptables -A FORWARD -j LOG

# INPUT

# Aceptar loopback input

iptables -A INPUT -i lo -p all -j ACCEPT



# Allow three-way Handshake

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT



# Stop Masked Attackes

iptables -A INPUT -p icmp --icmp-type 13 -j DROP
iptables -A INPUT -p icmp --icmp-type 17 -j DROP
iptables -A INPUT -p icmp --icmp-type 14 -j DROP
iptables -A INPUT -p icmp -m limit --limit 1/second -j ACCEPT


# Discard invalid Packets

iptables -A INPUT -m state --state INVALID -j DROP

iptables -A FORWARD -m state --state INVALID -j DROP

iptables -A OUTPUT -m state --state INVALID -j DROP


### Drop Spoofing attacks
iptables -A INPUT -s 10.0.0.0/8 -j DROP
iptables -A INPUT -s 169.254.0.0/16 -j DROP
iptables -A INPUT -s 172.16.0.0/12 -j DROP
iptables -A INPUT -s 127.0.0.0/8 -j DROP
iptables -A INPUT -s 192.168.0.0/24 -j DROP

iptables -A INPUT -s 224.0.0.0/4 -j DROP
iptables -A INPUT -d 224.0.0.0/4 -j DROP
iptables -A INPUT -s 240.0.0.0/5 -j DROP
iptables -A INPUT -d 240.0.0.0/5 -j DROP
iptables -A INPUT -s 0.0.0.0/8 -j DROP
iptables -A INPUT -d 0.0.0.0/8 -j DROP
iptables -A INPUT -d 239.255.255.0/24 -j DROP
iptables -A INPUT -d 255.255.255.255 -j DROP

# Drop packets with excessive RST to avoid Masked attacks

iptables -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT



# Any IP that performs a PortScan will be blocked for 24 hours

iptables -A INPUT   -m recent --name portscan --rcheck --seconds 86400 -j DROP

iptables -A FORWARD -m recent --name portscan --rcheck --seconds 86400 -j DROP



# After 24 hours remove IP from block list

iptables -A INPUT   -m recent --name portscan --remove

iptables -A FORWARD -m recent --name portscan --remove



# This rule logs the port scan attempt

iptables -A INPUT   -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "Portscan:"

iptables -A INPUT   -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP



iptables -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "Portscan:"

iptables -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP



# Inbound Rules

# smtp

iptables -A INPUT -p tcp -m tcp --dport 25 -j ACCEPT

# http

iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT

# https

iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT

# ssh & sftp

iptables -A INPUT -p tcp -m tcp --dport 372 -j ACCEPT



# Allow Ping

iptables -A INPUT -p icmp --icmp-type 0 -j ACCEPT


# Limit SSH connection from a single IP

iptables -A INPUT -p tcp --syn --dport 372 -m connlimit --connlimit-above 2 -j REJECT

