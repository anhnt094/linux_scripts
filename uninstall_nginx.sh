#!/bin/bash

# Check root access
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${CRED}Sorry, you need to run this as root${CEND}"
	exit 1
fi

while [[ $CONF !=  "y" && $CONF != "n" ]]; do
	read -p "       Remove configuration files ? [y/n]: " -e CONF
done
while [[ $LOGS !=  "y" && $LOGS != "n" ]]; do
	read -p "       Remove logs files ? [y/n]: " -e LOGS
done

# Stop Nginx
echo -e "\n---------------------------------- Stopping nginx ----------------------------------\n"
systemctl stop nginx

# Removing Nginx files and modules files
echo -e "\n---------------------------------- Removing Nginx files ----------------------------------\n"
rm -rf /home/nginx/src \
/usr/sbin/nginx* \
/etc/logrotate.d/nginx \
/home/nginx/temp \
/lib/systemd/system/nginx.service \
/etc/systemd/system/multi-user.target.wants/nginx.service >> /tmp/nginx-uninstall.log 2>&1

# Remove conf files
if [[ "$CONF" = 'y' ]]; then
	echo -e "\n---------------------------------- Removing configuration files ----------------------------------\n"
	rm -rf /home/nginx/config >> /tmp/nginx-uninstall.log 2>&1
fi

# Remove logs
if [[ "$LOGS" = 'y' ]]; then
	echo -e "\n---------------------------------- Removing log files ----------------------------------\n"
	rm -rf /home/nginx/logs >> /tmp/nginx-uninstall.log 2>&1
fi

# We're done !
echo ""
echo "       Installation log: /tmp/nginx-uninstall.log"
echo ""