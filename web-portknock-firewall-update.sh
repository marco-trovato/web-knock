# remember you can always do this if needed by other programs, in this case ping
# it passes the curl output, the file content, as parameter of ping
# curl -sS http://yourwebsite.com/ip/ip.txt | xargs ping

#create folder only if not exist
[ -d /etc/web-portknock ] || mkdir /etc/web-portknock
HOST=$1
#basename extracts the file on a path, perfect to erase the base url and keep the filename. it also doesnt care for the http string
HOSTFILE="/etc/web-portknock/$(basename $HOST)"
CHAIN="INPUT"  # change this to whatever chain you want.
IPTABLES="/sbin/iptables"

echo Allowing SSH:

#show datetime for log
date
echo Host: $1

# check to make sure we have enough args passed.
if [ "${#@}" -ne "1" ]; then
    echo "$0 hostname"
    echo "You must supply a hostname to update in iptables. No changes, exiting."
    exit
fi

# lookup host name from dns tables
HOST="$1"
#new method with curl, no dyndns or fixed ip required!
IP=$(curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36" -sS $HOST)
#new system to validate ip
if [[ $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "Valid IP: $IP"
else
    echo "Couldn't download or read correctly, the IP is invalid. No changes, exiting."
    echo "DEBUG INFO - The invalid IP was: $IP"
    exit
fi

OLDIP=""
if [ -a $HOSTFILE ]; then
    OLDIP=`cat $HOSTFILE`
    # echo "CAT returned: $?"
fi

# has address changed?
if [ "$OLDIP" == "$IP" ]; then
    echo "Old and new IP addresses match ($OLDIP). Doing nothing."
    #this happens often, writing a new line to help log readability
    echo ""
    exit
fi

# save off new ip.
echo "Saving IP in $HOSTFILE"
echo $IP>$HOSTFILE

echo "It is a new IP. Updating $1 in iptables."
if [ "${#OLDIP}" != "0" ]; then
    echo "Removing old rule ($OLDIP)"
#   version without perl, after further testing i noticed $OLDIP was not parsed on awk between the slashes
    OLDIP_RULENUM=$( $IPTABLES -L $CHAIN -n --line-numbers | grep $OLDIP | awk '/tcp/ {print $1;exit}' )

    echo Rule number: $OLDIP_RULENUM
    `$IPTABLES -D $CHAIN $OLDIP_RULENUM`
fi
echo "Inserting new rule ($IP)"
`$IPTABLES -A $CHAIN -p tcp -s $IP -m multiport --dports 21,22 -m state --state NEW,ESTABLISHED -j ACCEPT`
echo ------------
