#!/bin/bash

# Uses dns-servers.txt file for dns server and API token
# format is 1 entry per line:
# dns-server-name,ipaddress,api-token,path-to-backup/

# removes backups older than 30 days per server, but keeps the latest in the event there hasn't been anything new in 30 days.


# run in crontab with this command:
# * * * * * /home/manderse/bin/technitium-backup.sh /home/manderse/bin/dns-servers.txt >> /home/manderse/log/technitium-backup-$(date +\%Y-\%m-\%d).log 2>&1
# cleanups log files over 30 days 
LOGFILEDIR="/home/manderse/log"

# Check input file  
if [ $# -eq 0 ]; then
  echo "Usage: $0 <dns-servers.txt>" 
  exit 1
fi
TIMESTAMP=$(date +%Y%m%d-%H-%M-%S)
echo "----------------------------------------"
echo $TIMESTAMP
echo "----------------------------------------"

# Get input file
DNS_FILE=$1

# Read lines
while read -r line; do
  HOSTNAME=$(echo $line | cut -d',' -f1)
  IP=$(echo $line | cut -d',' -f2)
  TOKEN=$(echo $line | cut -d',' -f3)
  BACKUPPATH=$(echo $line | cut -d',' -f4)
  
  # Construct API URL with IP and token, change any unwanted settings below to false as documented in https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md#backup-settings
  URL="http://$IP:5380/api/settings/backup?token=$TOKEN&blockLists=true&logs=false&scopes=true&apps=true&stats=true&zones=true&allowedZones=true&blockedZones=true&dnsSettings=true&logSettings=true&authConfig=true"
  

  # Construct output file name 
  FILE_NAME=$BACKUPPATH$HOSTNAME-$IP-$(date +%Y%m%d-%H-%M).zip

  # Call API
  curl $URL -o $FILE_NAME  
  #clean up files older than 30 days but keep 1
  find /mnt/fs02-docker/backup/dns-servers/dns01 -type f -mtime +30 -printf '%T@ %p\n' | sort -n | head -n -1 | cut -d' ' -f2- |  xargs -r rm --
  
done < $DNS_FILE

#cleanup log files


# Find matching files, sorted by modification time (oldest first)
files=($(find "$LOGFILEDIR" -type f -name "technitium*" -printf "%T@ %p\n" | sort -n | awk '{print $2}'))

# Get the number of files
total=${#files[@]}

# If more than 5 files
if (( total > 5 )); then
    # Skip the oldest 5 files and process the rest
    for ((i=5; i<total; i++)); do
        file="${files[i]}"
        # Check if file is older than 30 days
        if [[ $(find "$file" -mtime +30) ]]; then
            echo "Deleting $file"
            rm "$file"
        fi
    done
else
    echo "Less than or equal to 5 technitium files, nothing to delete."
fi