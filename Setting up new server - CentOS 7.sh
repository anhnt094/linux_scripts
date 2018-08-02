#!/bin/bash

# https://www.tecmint.com/things-to-do-after-minimal-rhel-centos-7-installation/

# Manual Setting:
# - hostname (reboot), selinux (reboot), ip, proxy

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
