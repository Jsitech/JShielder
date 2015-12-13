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



# Permitir Handshake de tres vias

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT



# Detener Ataques Enmascarados

iptables -A INPUT -p icmp --icmp-type 13 -j DROP
iptables -A INPUT -p icmp --icmp-type 17 -j DROP
iptables -A INPUT -p icmp --icmp-type 14 -j DROP
iptables -A INPUT -p icmp -m limit --limit 1/second -j ACCEPT


# Descartar Paquetes Inválidos

iptables -A INPUT -m state --state INVALID -j DROP

iptables -A FORWARD -m state --state INVALID -j DROP

iptables -A OUTPUT -m state --state INVALID -j DROP


### Descartar Ataques de Spoofing
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

# Descartar paquetes RST Excesivos para Evitar Ataques Enmascarados

iptables -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT



# Cualquier IP que intente un Escaneo de Puertos sera Bloqueada por 24 Horas.

iptables -A INPUT   -m recent --name portscan --rcheck --seconds 86400 -j DROP

iptables -A FORWARD -m recent --name portscan --rcheck --seconds 86400 -j DROP



# Pasadas las 24 Horas, remover la IP Bloqueada por Escaneo de Puertos

iptables -A INPUT   -m recent --name portscan --remove

iptables -A FORWARD -m recent --name portscan --remove



# Esta Regla agrega el Escaner de Puertos a la Lista de PortScan y Registra el Evento.

iptables -A INPUT   -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "Portscan:"

iptables -A INPUT   -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP



iptables -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "Portscan:"

iptables -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP



# Permitir estos puertos desde Fuera

# smtp

iptables -A INPUT -p tcp -m tcp --dport 25 -j ACCEPT

# http

iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT

# https

iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT

# ssh & sftp

iptables -A INPUT -p tcp -m tcp --dport 372 -j ACCEPT



# Permitir el Ping

iptables -A INPUT -p icmp --icmp-type 0 -j ACCEPT


# OUTPUT

iptables -A OUTPUT -o lo -j ACCEPT

iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT



# Permitir estos puertos desde Fuera

# smtp

iptables -A OUTPUT -p tcp -m tcp --dport 25 -j ACCEPT

# http

iptables -A OUTPUT -p tcp -m tcp --dport 80 -j ACCEPT

# https

iptables -A OUTPUT -p tcp -m tcp --dport 443 -j ACCEPT

# ssh & sftp

iptables -A OUTPUT -p tcp -m tcp --dport 372 -j ACCEPT

# Limit SSH connection from a single IP

iptables -A INPUT -p tcp --syn --dport 372 -m connlimit --connlimit-above 2 -j REJECT



# Permitir Pings

iptables -A OUTPUT -p icmp --icmp-type 0 -j ACCEPT

# No Permitir Forward

iptables -A FORWARD -j REJECT
