#!/bin/bash
# Version   Date        Author  Changes 
# 1.0       08/10/2016  Steven  Add more substitution  


FILE_NAME="file.txt"
# TMP_RESULT="tmp_result.csv"
RESULT_FILE="KPI.csv"
ERR_FILE="error.txt"

# CONSTANT SERVICE NAME (23)
APPLICATION_GATEWAY="application gateway"
AUTOMATION="automation"
BACKUP="backup"
CDN="cdn"
CLOUD_SERVICES="cloud services"
EVENT_HUBS="event hubs"
HDINSIGHT="hdinsight"
IDENTITY="identity"
MEDIA_SERVICES="media services"
MOBILE_SERVICES="mobile services"
MYSQL="mysql"
NETWORKING="networking"
NOTIFICATION_HUBS="notification hubs"
REDIS_CACHE="redis cache"
SCHEDULER="scheduler"
SERVICE_BUS="service bus"
SITE_RECOVERY="site recovery"
SQL_DATABASES="sql databases"
SDW="sql data warehouse"
STRETCH_DB="sql server stretch database"
STORAGE="storage"
TRAFFIC_MANAGER="traffic manager"
VIRTUAL_MACHINES="virtual machines"
VIRTUAL_MACHINES_WINDOWS="virtual machines windows"
VIRTUAL_MACHINES_LINUX="virtual machines linux"
WEB_SITES="web sites"
BATCH="batch"
SERVICE_FABRIC="service fabric"
AZURE_PORTAL="azure portal"
KEY_VAULT="key vault"
IOT_HUB="iot hub"
MFA="mfa"
STREAM_ANALYTICS="stream analytics"
VPN_GATEWAY="vpn gateway"
OTHERS="others"

# Clear the screen
clear

# Change directory to ACN
if [ -d $ACN ]; then
    cd $ACN && echo "Change directory to ACN Success"
else
    echo "$ACN does not exists."
    exit 55
fi

# Clean last time result
rm $ERR_FILE 2>/dev/null
rm $RESULT_FILE 2>/dev/null

# Print usage
if [ "$#" -ne 0 ]; then
	echo "Usage: run.sh"
	exit 0
fi

# Find markdown files with relative path
find articles/ -type f -name "*.md" > $FILE_NAME 2>/dev/null

if [ $? -eq 0 ]; then
	echo -e "\033[1;32m [Done] \033[1;0m Finish reading file list"
else
	echo -e "\033[1;31m [Error] \033[1;0m No markdown file in current directory"
	exit 0
fi

echo -e "\033[1;33m Please wait while processing...\033[1;0m"
while read line;
do
	# Cut first field, most related service
	tmpService=$(grep -o -P 'ms.service=\".*?\"' "$line")
	date=$(grep -o -P 'wacn.date=\".*?\"' "$line")
	# Check if there is no that tags
	if [ -z "$tmpService" ] || [ -z "$date" ]; then
		echo $line >> $ERR_FILE
	else
		# Get first clean service name
		cleanService=$(echo $tmpService | sed -e 's/ms.service=//g' -e 's/\"//g' -e 's/ //g' | cut -f1 -d',' | tr A-Z a-z)
        cleanDate=$(echo $date | sed -e 's/wacn.date=//g' -e 's/\"//g')

        if [ -z "$cleanService" ] || [ -z "$cleanDate" ]; then
            echo $line >> $ERR_FILE
        else 
            # Let's do the replacing using if else, sed got mis-replacing some times and maybe slow.
            if [ "$cleanService" == "virtual-machines-linux" ]; then
                service=$VIRTUAL_MACHINES_LINUX
            elif [ "$cleanService" == "virtual-machines-windows" ]; then
                service=$VIRTUAL_MACHINES_WINDOWS
            elif [ "$cleanService" == "active-directory" ] || [ "$cleanService" == "azure-active-directory-connect" ] || [ "$cleanService" == "azure-identity-connect" ] || [ "$cleanService" == "ad" ] ; then
                service=$IDENTITY
            elif [ "$cleanService" == "application-gateway" ]; then
                service=$APPLICATION_GATEWAY
            elif [ "$cleanService" == "cloud-services" ]; then
                service=$CLOUD_SERVICES
            elif [ "$cleanService" == "service-bus" ]; then
                service=$SERVICE_BUS
            elif [ "$cleanService" == "sql-database" ]; then
                service=$SQL_DATABASES
            elif [ "$cleanService" == "traffic-manager" ]; then
                service=$TRAFFIC_MANAGER
            elif [ "$cleanService" == "app-service-web" ] || [ "$cleanService" == "app-service" ] || [ "$cleanService" == "websites" ] || [ "$cleanService" == "web-sites" ]; then
                service=$WEB_SITES
            elif [ "$cleanService" == "media-services" ]; then
                service=$MEDIA_SERVICES
            elif [ "$cleanService" == "redis-cache" ] || [ "$cleanService" == "cache" ]; then
                service=$REDIS_CACHE
            elif [ "$cleanService" == "event-hubs" ]; then
                service=$EVENT_HUBS
            elif [ "$cleanService" == "site-recovery" ]; then
                service=$SITE_RECOVERY		
            elif [ "$cleanService" == "mobile" ] || [ "$cleanService" == "mobile-services" ]; then
                service=$MOBILE_SERVICES
            elif [ "$cleanService" == "virtual-network" ]; then
                service=$NETWORKING
            elif [ "$cleanService" == "notification-hubs" ]; then
                service=$NOTIFICATION_HUBS
            elif [ "$cleanService" == "service-fabric" ]; then
                service=$SERVICE_FABRIC
            elif [ "$cleanService" == "azure-portal" ]; then
                service=$AZURE_PORTAL
            elif [ "$cleanService" == "key-vault" ]; then
                service=$KEY_VAULT
            elif [ "$cleanService" == "cdn_en" ]; then
                service=$CDN
            elif [ "$cleanService" == "iot-hub" ]; then
                service=$IOT_HUB
            elif [ "$cleanService" == "multi-factor-authentication" ]; then
                service=$MFA
            elif [ "$cleanService" == "mysql_en" ]; then
                service=$MYSQL
            elif [ "$cleanService" == "sql-data-warehouse" ]; then
                service=$SDW
            elif [ "$cleanService" == "sql-server-stretch-database" ]; then
                service=$STRETCH_DB
            elif [ "$cleanService" == "stream-analytics" ]; then
                service=$STREAM_ANALYTICS
            elif [ "$cleanService" == "vpn-gateway" ]; then
                service=$VPN_GATEWAY
            else
                service=$cleanService
            fi
            echo "${line},${service},${cleanDate}"
        fi
	fi
done < $FILE_NAME > $RESULT_FILE

# let's clean our results
# ms.service= wacn.date= " " "
# bugfix: put s/ad//g last positon to avoid mulitple replace
# sed -e 's/wacn.date=//g' -e 's/\"//g' $TMP_RESULT > $RESULT_FILE

# rm $TMP_RESULT 2>/dev/null
# Keep filelist
# rm $FILE_NAME 2>/dev/null

# Make \n to \r\n
unix2dos $RESULT_FILE >/dev/null 2>&1
unix2dos $ERR_FILE >/dev/null 2>&1

echo -e "\033[1;32m [Done]\033[1;0m  Finish scanning"
echo -e "\033[1;34m [TIP]\033[1;0m  Please check \033[1;32m KPI.csv\033[1;0m and \033[1;31m error.txt\033[1;0m for detailed info"

exit 0
