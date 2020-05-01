#!/bin/bash
# THIS IS TO ALLOW SSH, NO REQUESTS LIMITS PER MONTH AS DYNAMIC DNS, ADD TO CRON TO BE EXECUTED AS MANY TIMES YOU WANT

# without touch, no log file would be created if not already exist
touch /var/log/youshallnotpass.log

#please note you have to specify full path for this to work from crontab
LOGSIZ=$( stat -c %s /var/log/youshallnotpass.log)
if (( $LOGSIZ > 50000 )); then
    echo >/var/log/youshallnotpass.log
    echo Log too big, wiping it.
fi

#save datetime to logs
date

# ADD YOUR CONFIGURATION BELOW
# please avoid using same filename ip.txt since the filename is the identifier for the device

echo ---- WHITELIST IP ALLOW ADMIN ----
./web-portknock-update.sh https://yourwebsite.com/myip/ip.txt
./web-portknock-update.sh http://freewebhosting.com/backupaccess/johnsmith.txt
