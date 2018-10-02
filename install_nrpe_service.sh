#!/bin/bash

# If use proxy, set "proxy=1". If don't use proxy, set "proxy=0"
proxy=1

# Check root access
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${CRED}Sorry, you need to run this as root${CEND}"
	exit 1
fi

echo "nrpe            5666/tcp                # NRPE" >> /etc/services

if [ $proxy -eq 1 ]
then
  echo -e "https_proxy = http://proxy.hcm.fpt.vn:80/\nhttp_proxy = http://proxy.hcm.fpt.vn:80/" >> /etc/yum.conf
fi

# Install required libraries
echo -e "\n---------------------------------- Installing required libraries ----------------------------------\n"
yum -y install bind-utils openssl-devel make gcc wget perl unzip

if [ $proxy -eq 1 ]
then
  echo -e "https_proxy = http://proxy.hcm.fpt.vn:80/\nhttp_proxy = http://proxy.hcm.fpt.vn:80/" >> /etc/wgetrc
fi

# Install nrpe
echo -e "\n---------------------------------- Installing nrpe ----------------------------------\n"
yum -y install nrpe nagios-plugins nagios-plugins-nrpe

# Backup iptable rules
echo -e "\n---------------------------------- Backup iptable rules ----------------------------------\n"
mkdir -p /backup && cp /etc/sysconfig/iptables /backup

# Add iptable rules
echo -e "\n---------------------------------- Adding iptable rules ----------------------------------\n"

iptables -A INPUT -p tcp -s 172.20.19.100 -m tcp --dport 10050 -m comment --comment "Allow Zabbix" -j ACCEPT
iptables -A INPUT -s 172.31.2.21 -m comment --comment "Opview New" -j ACCEPT
iptables -A INPUT -s 210.245.31.162 -m comment --comment "Opview New" -j ACCEPT
iptables -A INPUT -s 118.70.7.112 -p tcp -m tcp --dport 22 -m comment --comment "Allow CA-PAM"  -j ACCEPT
iptables -A INPUT -s 210.245.31.154 -p tcp -m tcp --dport 22 -m comment --comment "Allow CA-PAM"  -j ACCEPT
iptables -A INPUT -s 210.245.31.160 -p icmp -m icmp --icmp-type 8 -m state --state NEW,RELATED,ESTABLISHED -m comment --comment "Allow  Ping" -j ACCEPT
iptables -A INPUT -s 210.245.31.149 -p icmp -m icmp --icmp-type 8 -m state --state NEW,RELATED,ESTABLISHED -m comment --comment "Allow  Ping" -j ACCEPT
iptables -A INPUT -s 210.245.0.128/25 -p icmp -m icmp --icmp-type 8 -m state --state NEW,RELATED,ESTABLISHED -m comment --comment "Allow  Ping" -j ACCEPT
iptables -A INPUT -s 210.245.0.128/25 -p tcp -m tcp --dport 5666 -m state --state NEW,RELATED,ESTABLISHED -m comment --comment "Allow OpsView" -j ACCEPT
iptables -A INPUT -s 210.245.0.128/25 -p udp -m udp --dport 161 -m state --state NEW,RELATED,ESTABLISHED -m comment --comment "Allow SNMP monitor" -j ACCEPT
iptables -A OUTPUT -d 210.245.31.160 -p icmp -m icmp --icmp-type 0 -m state --state RELATED,ESTABLISHED -m comment --comment "Allow Monitor Ping" -j ACCEPT
iptables -A OUTPUT -d 210.245.31.149 -p icmp -m icmp --icmp-type 0 -m state --state RELATED,ESTABLISHED -m comment --comment "Allow Monitor Ping" -j ACCEPT
iptables -A OUTPUT -d 210.245.0.128/25 -p icmp -m icmp --icmp-type 0 -m state --state RELATED,ESTABLISHED -m comment --comment "Allow Monitor Ping" -j ACCEPT
iptables -A OUTPUT -d 210.245.0.128/25 -p udp -m udp --dport 161 -m state --state NEW,RELATED,ESTABLISHED -m comment --comment "Allow SNMP monitor" -j ACCEPT
iptables -A INPUT -p icmp -m icmp --icmp-type 8 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT

service iptables save
service iptables reload

echo Done \!

# Backup nrpe configuration file
echo -e "\n---------------------------------- Backup NRPE configuration file ----------------------------------\n"
mkdir -p /backup && cp /etc/nagios/nrpe.cfg /backup

# Edit nrpe configuration file
echo -e "\n---------------------------------- Editing NRPE configuration file ----------------------------------\n"

sed -ie '/^server_port=/c\server_port=5666' /etc/nagios/nrpe.cfg
sed -ie '/^nrpe_user=/c\nrpe_user=nrpe' /etc/nagios/nrpe.cfg
sed -ie '/^nrpe_group=/c\nrpe_group=nrpe' /etc/nagios/nrpe.cfg
sed -ie '/^allowed_hosts=/c\allowed_hosts=127.0.0.1,210.245.31.162,210.245.0.129,210.245.0.134,210.245.0.210,210.245.0.211,210.245.0.212,210.245.0.213,210.245.0.214,210.245.0.219,118.69.163.194,118.69.163.195,118.69.163.196,118.69.163.197,118.69.163.199,118.69.163.200,118.69.163.201,118.69.163.202,118.69.163.203,210.245.31.159,210.245.31.149,210.245.31.160,210.245.0.128\/25' /etc/nagios/nrpe.cfg
sed -ie '/^dont_blame_nrpe=/c\dont_blame_nrpe=1' /etc/nagios/nrpe.cfg

sed -ie '/^command\[check_users\]=/c\command[check_users]=/usr/lib64/nagios/plugins/check_users -w 5 -c 10' /etc/nagios/nrpe.cfg
sed -ie '/^command\[check_load\]=/c\command\[check_load\]=/usr/lib64/nagios/plugins/check_load -r -w 14.4,12.8,11.2 -c 15.2,14.4,12.8' /etc/nagios/nrpe.cfg


sed -ie '/^command\[check_hda1\]=/c\command\[check_hda1\]=\/usr\/lib64\/nagios\/plugins\/check_disk -w 20% -c 10% -p \/dev\/hda1' /etc/nagios/nrpe.cfg
sed -ie '/^command\[check_zombie_procs\]=/c\command\[check_zombie_procs\]=\/usr\/lib64\/nagios\/plugins\/check_procs -w 5 -c 10 -s Z' /etc/nagios/nrpe.cfg
sed -ie '/^command\[check_total_procs\]=/c\command\[check_total_procs\]=\/usr\/lib64\/nagios\/plugins\/check_procs -w 150 -c 200' /etc/nagios/nrpe.cfg
sed -ie '/command\[check_procs\]=/c\command\[check_procs\]=\/usr\/lib64\/nagios\/plugins\/check_procs -w :600 -c :900' /etc/nagios/nrpe.cfg

echo -e "command[check_memory]=/usr/lib64/nagios/plugins/check_snmp -H 127.0.0.1 -P 2c -C public -o .1.3.6.1.4.1.2021.4.6.0 -w 300000: -c 50000:" >> /etc/nagios/nrpe.cfg
echo -e "command[check_swap]=/usr/lib64/nagios/plugins/check_snmp -H 127.0.0.1 -P 2c -C public -o .1.3.6.1.4.1.2021.4.4.0 -w 3000000: -c 1000000:" >> /etc/nagios/nrpe.cfg

# Add NAGIOS plugin
echo -e "\n---------------------------------- Adding NAGIOS plugin ----------------------------------\n"
mkdir ~/nrpe_src
cd ~/nrpe_src
wget https://github.com/hungpt91/plugins/archive/master.zip
unzip master.zip
mv plugins-master plugins
echo y | cp -r plugins/* /usr/lib64/nagios/plugins/
chmod 755 -R /usr/lib64/nagios/plugins/*
chown nrpe. -R /usr/lib64/nagios/plugins/*
chkconfig nrpe on
service nrpe restart 

# Check NRPE
echo -e "\n---------------------------------- Checking NRPE ----------------------------------\n"
ps ax | grep nrpe
echo ""
netstat -tulpn | grep 5666

# Install snmp
echo -e "\n---------------------------------- Installing snmp ----------------------------------\n"

yum -y install net-snmp net-snmp-utils
mv -i /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.orig
echo "rocommunity public" > /etc/snmp/snmpd.conf
chkconfig snmpd on
service snmpd restart

# Check SNMP
echo -e "\n---------------------------------- Checking snmp ----------------------------------\n"
/usr/lib64/nagios/plugins/check_snmp -H 127.0.0.1 -P 2c -C public -o .1.3.6.1.4.1.2021.4.6.0
