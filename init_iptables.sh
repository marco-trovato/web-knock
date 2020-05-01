#!/bin/bash

echo "Please read this script before executing it, so you can change it according to your needs and make sure all services on your server will continue working."
echo "It works on my machine ¯\_(ツ)_/¯"
read -p "Press ENTER to continue..."

###############
# INIT

echo Flushing rules...

# flush everything!
iptables -F
iptables -F INPUT
iptables -F OUTPUT
iptables -F FORWARD
iptables -F -t mangle
iptables -F -t nat
iptables -X


###############
# BASIC DENIAL RULES

echo Setting default security policy...
# set default policy
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

echo Allowing loopback connections for mysql etc...
# the following seems to be required
iptables -A INPUT -p tcp -s localhost -d localhost -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

###############
# FURTHER PROTECTIONS AND LIMITS

# DROP INVALID
iptables -A INPUT -m state --state INVALID -j DROP
# 1. MAKE SURE NEW INCOMING TCP CONNECTIONS ARE SYN PACKETS; OTHERWISE WE NEED TO DROP THEM - THIS IS GOOD!
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
# 2. DROP PACKETS WITH OUTGOING FRAGMENTS. THIS ATTACK RESULT INTO LINUX SERVER PANIC SUCH DATA LOSS
iptables -A INPUT -f -j DROP
iptables -A OUTPUT -f -j DROP
# 3. DROP OUTGOING MALFORMED XMAS or NULL PACKETS - THIS IS GOOD!
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# -------------------------------------------------------------------------

###############
# ALLOWANCES

# allow incoming estabilished traffic - allow all previously initiated and accepted exchanges to bypass rule checking
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

echo Allowing UDP packets and DNS requests...
# Allow answer to dns request, to resolve dyndns hostname for trusted ssh access
iptables -A INPUT -p udp -m state --state ESTABLISHED,RELATED -m udp --sport 53 -j ACCEPT
# Unfortunately with sport, the firewall can be compromised by using source port 53 for any new connections into the server.
# An attacker can choose to use port 53 as his source port and walk right through the front door.
# Use stateful packet inspection -m state, DNS query response will match ESTABLISHED/RELATED when truly related.

echo Allowing email and WEB TRAFFIC...
# Allowing: HTTP, HTTPS (80-443), SMTP (postfix) and IMAP (imap-imaps are 143-993, smtp-smtps are 25-465, pop3 are 110-995)
iptables -A INPUT -p tcp -m multiport --dports 80,443,143,993,9560,25,465 -m state --state NEW,ESTABLISHED -j ACCEPT

echo Adding access from trusted IP - This could take few seconds if using dynamic dns...
# allow SSH for tunnel, from trusted STATIC IP
#iptables -A INPUT -p tcp -s 184.25.24.144 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
#iptables -A INPUT -p tcp -s 132.18.20.5 -m state --state NEW,ESTABLISHED -j ACCEPT

echo "Now going for IPs that are not static..."
echo "Init web-portknock..."
#re-init all previously saved ips
rm -f /etc/web-portknock/*
echo "Executing web-portknock..."
/root/web-portknock.sh >> /var/log/youshallnotpass.log
echo "Please read the log file if you want to verify that the IP were added successfully."

echo Allowing ping...
# Allow ping (in and out)
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

######################  BLACKLISTS  #######################


echo Setting up blacklist...
# Reject Invalid networks (Spoof)
iptables -A INPUT -s 10.0.0.0/8       -j DROP           # (Spoofed network)
iptables -A INPUT -s 192.0.0.1/24     -j DROP           # (Spoofed network)
iptables -A INPUT -s 169.254.0.0/16   -j DROP           # (Spoofed network)
iptables -A INPUT -s 172.16.0.0/12    -j DROP           # (Spoofed network)
iptables -A INPUT -s 224.0.0.0/4      -j DROP           # (Spoofed network)
iptables -A INPUT -d 224.0.0.0/4      -j DROP           # (Spoofed network)
iptables -A INPUT -s 240.0.0.0/5      -j DROP           # (Spoofed network)
iptables -A INPUT -d 240.0.0.0/5      -j DROP           # (Spoofed network)
iptables -A INPUT -s 0.0.0.0/8        -j DROP           # (Spoofed network)
iptables -A INPUT -d 0.0.0.0/8        -j DROP           # (Spoofed network)
iptables -A INPUT -d 239.255.255.0/24 -j DROP           # (Spoofed network)
iptables -A INPUT -d 255.255.255.255  -j DROP           # (Spoofed network)

echo Done.

# no need to execute this script on startup:
# save actual situation, to reload it on startup. THIS IS IMPORTANT TO KEEP CHANGES AFTER REBOOT!!
echo Saving current rules in case you want to reload on boot...
iptables-save > /etc/iptables.conf
echo "If you want these changes to be permanent after reboot"
echo "Please: nano /etc/network/if-pre-up.d/iptables-up"
# of course cant do it directly from this script, because it would do it every time it is executed
echo "and put inside:"
echo "#!/bin/sh"
echo "/sbin/iptables-restore < /etc/iptables.conf"
echo "Then make it executable: chmod +x /etc/network/if-pre-up.d/iptables-up"
