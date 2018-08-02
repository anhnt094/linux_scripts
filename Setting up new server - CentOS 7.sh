#!/bin/bash

# https://www.tecmint.com/things-to-do-after-minimal-rhel-centos-7-installation/

# Check root access
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${CRED}Sorry, you need to run this as root${CEND}"
	exit 1
fi

ip=""
netmask=""
gateway=""
dns1=""
dns2=""

hostname=""
proxy=""
bypass_proxy="localhost,127.0.0.0/8,172.16.0.0/12,192.168.0.0/16"


# Setting IP Address
ip_config_file=`ls /etc/sysconfig/network-scripts/ifcfg-e*`
if [ "$ip" != "" ];
then
	echo -e "\n---------------------------------- Setting IP ----------------------------------\n"
	sed -i "/IPADDR=.*/d" $ip_config_file
	echo IPADDR=$ip >> $ip_config_file
	echo Set IP to $ip
fi

if [ "$netmask" != "" ];
then
	echo -e "\n---------------------------------- Setting NETMASK ----------------------------------\n"	
	sed -i "/NETMASK=.*/d" $ip_config_file
	echo NETMASK=$netmask >> $ip_config_file
	echo Set NETMASK to $netmask
fi

if [ "$gateway" != "" ];
then
	echo -e "\n---------------------------------- Setting GATEWAY ----------------------------------\n"	
	sed -i "/GATEWAY=.*/d" $ip_config_file
	echo GATEWAY=$gateway >> $ip_config_file
	echo Set GATEWAY to $gateway
fi

if [ "$dns1" != "" ];
then
	echo -e "\n---------------------------------- Setting DNS1 ----------------------------------\n"	
	sed -i "/DNS1=.*/d" $ip_config_file
	echo DNS1=$dns1 >> $ip_config_file
	echo Set DNS1 to $dns1
fi

if [ "$dns2" != "" ];
then
	echo -e "\n---------------------------------- Setting DNS2 ----------------------------------\n"	
	sed -i "/DNS2=.*/d" $ip_config_file
	echo DNS2=$dns2 >> $ip_config_file
	echo Set DNS2 to $dns2
fi

# Disable IPv6
echo -e "\n---------------------------------- Disabling IPv6 ----------------------------------\n"	
echo net.ipv6.conf.all.disable_ipv6 = 1 >> /etc/sysctl.conf
echo net.ipv6.conf.default.disable_ipv6 = 1 = 1 >> /etc/sysctl.conf

systemctl restart network


# Setting hostname
if [ "$hostname" != "" ];
then
	echo -e "\n---------------------------------- Setting hostname ----------------------------------\n"
	hostnamectl set-hostname $hostname
fi

# Setting proxy
if [ "$proxy" != "" ];
then
	echo -e "\n---------------------------------- Setting proxy ----------------------------------\n"
	
	# Delete old proxy config
	sed -i "/^export http_proxy=.*/d" /etc/profile
	sed -i "/^export https_proxy=.*/d" /etc/profile
	sed -i "/^proxy=.*/d" /etc/yum.conf
	
	# New config
	http_proxy=$proxy
	https_proxy=$http_proxy
	no_proxy=$bypass_proxy
	
	export http_proxy https_proxy no_proxy

	echo export http_proxy=\"http://proxy.hcm.fpt.vn:80/\" >> /etc/profile
	echo export https_proxy=\"http://proxy.hcm.fpt.vn:80/\" >> /etc/profile
	echo proxy=$http_proxy >> /etc/yum.conf

    echo Set proxy to $http_proxy
fi





# Update
echo -e "\n---------------------------------- Update ----------------------------------\n"
yum -y update && yum -y upgrade

# Install net-tools
echo -e "\n---------------------------------- Installing net-tools ----------------------------------\n"
yum -y install net-tools

# Install wget
echo -e "\n---------------------------------- Installing wget ----------------------------------\n"
yum -y install wget

# Install curl
echo -e "\n---------------------------------- Installing curl ----------------------------------\n"
yum -y install curl

# Install vim
echo -e "\n---------------------------------- Installing vim ----------------------------------\n"
yum -y install vim

# Installing Telnet
echo -e "\n---------------------------------- Installing telnet ----------------------------------\n"
yum -y install telnet

# Install iptables
echo -e "\n---------------------------------- Disabling firewalld & Installing iptables ----------------------------------\n"
systemctl stop firewalld
systemctl disable firewalld
yum -y install iptables iptables-services
systemctl enable iptables
systemctl restart iptables

# Install openssl
echo -e "\n---------------------------------- Installing openssl ----------------------------------\n"
yum -y install openssl

# Install htop
echo -e "\n---------------------------------- Installing htop ----------------------------------\n"
wget dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
rpm -ihv epel-release-7-11.noarch.rpm 
yum -y install htop

# Install Development Tools
echo -e "\n---------------------------------- Installing Development Tools ----------------------------------\n"
yum -y groupinstall 'Development Tools'

# Install Java
echo -e "\n---------------------------------- Installing java ----------------------------------\n"
yum -y install java
java -version

# Install Nmap to Monitor Open Ports
echo -e "\n---------------------------------- Installing nmap ----------------------------------\n"
yum -y install nmap
nmap 127.0.01

# Disable SELinux
echo -e "\n---------------------------------- Disabling SELinux ----------------------------------\n"
sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
echo "Need a reboot !"

# Datetime
echo -e "\n---------------------------------- Setting datetime ----------------------------------\n"
timedatectl set-timezone Asia/Ho_Chi_Minh
timedatectl

yum -y install ntp
systemctl start ntpd
systemctl enable ntpd

