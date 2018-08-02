#!/bin/bash

# Check root access
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${CRED}Sorry, you need to run this as root${CEND}"
	exit 1
fi

# Remove nginx if it was installed by yum
echo -e "\n---------------------------------- Remove nginx if it was installed by yum ----------------------------------\n"
yum -y remove nginx

# Install "Development Tools" and Vim editor
echo -e "\n---------------------------------- Installing "Development Tools" and Vim editor ----------------------------------\n"
yum groupinstall -y 'Development Tools' && sudo yum install -y vim

# Install Extra Packages for Enterprise Linux (EPEL):
echo -e "\n---------------------------------- Installing Extra Packages for Enterprise Linux (EPEL) ----------------------------------\n"
yum install -y epel-release

# Download and install optional NGINX dependencies:
echo -e "\n---------------------------------- Downloading and installing optional NGINX dependencies: ----------------------------------\n"
yum install -y perl perl-devel perl-ExtUtils-Embed libxslt libxslt-devel libxml2 libxml2-devel gd gd-devel GeoIP GeoIP-devel

# Download NGINX 1.14.0:
echo -e "\n---------------------------------- Downloading NGINX 1.14.0 ----------------------------------\n"
mkdir ~/nginx_src
cd ~/nginx_src
wget http://nginx.org/download/nginx-1.14.0.tar.gz 

# Extract NGINX source:
echo -e "\n---------------------------------- Extracting NGINX source ----------------------------------\n"
tar zxf nginx-*.tar.gz

# Download zlib version 1.2.11:
echo -e "\n---------------------------------- Downloading zlib version 1.2.11 ----------------------------------\n"
wget https://www.zlib.net/zlib-1.2.11.tar.gz && tar xzf zlib-1.2.11.tar.gz

# Install PCRE
echo -e "\n---------------------------------- Installing PCRE ----------------------------------\n"
yum -y install pcre-devel

# Install OpenSSL-devel
echo -e "\n---------------------------------- Installing OpenSSL-devel ----------------------------------\n"
yum -y install openssl-devel

# Setting NGINX manual page:
echo -e "\n---------------------------------- Setting NGINX manual page ----------------------------------\n"
cd ~/nginx_src/nginx-1.14.0
cp ~/nginx_src/nginx-1.14.0/man/nginx.8 /usr/share/man/man8
gzip /usr/share/man/man8/nginx.8

# Download modules: nginx-module-sts, nginx-module-stream-sts, ModSecurity
cd ~/nginx_src

# Download module: nginx-module-sts
echo -e "\n---------------------------------- Downloading module: nginx-module-sts ----------------------------------\n"
git clone https://github.com/vozlt/nginx-module-sts.git 

# Download module: nginx-module-stream-sts
echo -e "\n---------------------------------- Downloading module: nginx-module-stream-sts ----------------------------------\n"
git clone https://github.com/vozlt/nginx-module-stream-sts.git

# Install ModSecurity 3.0:
echo -e "\n---------------------------------- Installing ModSecurity 3.0 ----------------------------------\n"
cd ~/nginx_src
yum -y install gcc-c++ flex bison yajl yajl-devel curl-devel curl GeoIP-devel doxygen zlib-devel

git clone https://github.com/SpiderLabs/ModSecurity
cd ~/nginx_src/ModSecurity
git checkout -b v3/master origin/v3/master
sh build.sh
git submodule init
git submodule update
./configure

make
make install

# Download nginx connector
echo -e "\n---------------------------------- Downloading nginx connector ----------------------------------\n"
export MODSECURITY_INC="/root/nginx_src/ModSecurity/headers/"
export MODSECURITY_LIB="/root/nginx_src/ModSecurity/src/.libs/"

cd ~/nginx_src
git clone https://github.com/SpiderLabs/ModSecurity-nginx

# Compile NGINX
echo -e "\n---------------------------------- Compiling NGINX ----------------------------------\n"
mkdir /home/nginx
mkdir /home/nginx/temp
mkdir /home/nginx/logs
mkdir /home/nginx/modsec
mkdir /home/nginx/src
mkdir /home/nginx/config


cd ~/nginx_src/nginx-1.14.0

./configure --prefix=/home/nginx \
            --sbin-path=/usr/sbin/nginx \
            --conf-path=/home/nginx/config/nginx.conf \
            --pid-path=/var/run/nginx.pid \
            --error-log-path=/home/nginx/logs/error.log \
            --http-log-path=/home/nginx/logs/access.log \
            --http-client-body-temp-path=/home/nginx/temp/client_temp \
            --http-proxy-temp-path=/home/nginx/temp/proxy_temp \
            --http-fastcgi-temp-path=/home/nginx/temp/fastcgi_temp \
            --http-uwsgi-temp-path=/home/nginx/temp/uwsgi_temp \
            --http-scgi-temp-path=/home/nginx/temp/scgi_temp \
            --user=nginx \
            --group=nginx \
            --with-select_module \
            --with-poll_module \
            --with-http_addition_module \
            --with-http_sub_module \
            --with-http_dav_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_random_index_module \
            --with-http_secure_link_module \
            --with-http_stub_status_module \
            --with-http_auth_request_module \
            --with-http_ssl_module \
            --with-stream \
            --add-module=/root/nginx_src/nginx-module-sts \
            --add-module=/root/nginx_src/nginx-module-stream-sts \
            --add-module=/root/nginx_src/ModSecurity-nginx 

make
make install

# Write NGINX systemd
echo -e "\n---------------------------------- Writting NGINX systemd ----------------------------------\n"
systemd_file="/usr/lib/systemd/system/nginx.service"
cat > $systemd_file << EOF
[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nginx
systemctl restart nginx






