#!/bin/bash
##################################
#####Date 2023/12/07
##################################
echo "*******************************************************"
echo "------------------- Start Install Server for New User"
echo "*******************************************************"
echo "*******************************************************"
echo "------------------- Update and upgrade repository"
echo "*******************************************************"
apt update -y && apt upgrade -y
if [ $? -eq 0 ]; then
	echo "*******************************************************"
	echo "------------------- apdate and upgrade successfully .. "
	echo "*******************************************************"
else
	echo "*******************************************************"
	echo "------------------- update and upgrade Error please check"
	echo "*******************************************************"
	exit 0
fi
echo "*******************************************************"
echo "------------------- Install Docker"
echo "*******************************************************"
apt install docker -y
if [ $? -eq 0 ]; then
        echo "*******************************************************"
        echo "------------------- docker installed and successfully .. "
        echo "*******************************************************"
else
        echo "*******************************************************"
        echo "------------------- docker install Error please check"
        echo "*******************************************************"
        exit 1
fi
echo "*******************************************************"
echo "------------------- Install Docker-compose"
echo "*******************************************************"
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose
if [ $? -eq 0 ]; then
        echo "*******************************************************"
        echo "------------------- docker-compose installed and successfully .. "
        echo "*******************************************************"
else
        echo "*******************************************************"
        echo "------------------- docker-compose install Error please check"
        echo "*******************************************************"
        exit 2
fi
echo "*******************************************************"
echo "------------------- Install Docker.io"
echo "*******************************************************"
apt install docker.io -y
if [ $? -eq 0 ]; then
        echo "*******************************************************"
        echo "------------------- docker.io installed and successfully .. "
        echo "*******************************************************"
else
        echo "*******************************************************"
        echo "------------------- docker.io install Error please check"
        echo "*******************************************************"
        exit 1
fi
echo "*******************************************************"
echo "------------------- Install Docker.io"
echo "*******************************************************"
apt install sharutils
if [ $? -eq 0 ]; then
        echo "*******************************************************"
        echo "------------------- docker.io installed and successfully .. "
        echo "*******************************************************"
else
        echo "*******************************************************"
        echo "------------------- docker.io install Error please check"
        echo "*******************************************************"
        exit 1
fi
echo "*******************************************************"
echo "------------------- Enter data User"
echo "*******************************************************"

read -p "Enter domain name for service: (Example elyashaddad.com) " Domain_Name

#create password for db
DB_PASSWORD=$(dd if=/dev/urandom count=1 2> /dev/null | uuencode -m - | sed -ne 2p | cut -c-12)

if [ -z ${Domain_Name+x} ]; then
    MY_IP=$(hostname -I | awk '{ print $1 }')
    echo "don't set"
    echo $MY_IP
else
    MY_IP=$Domain_Name
    echo "set"
    echo $MY_IP
fi



echo "------------------- All image pull for install server"
echo "*******************************************************"
echo "*******************************************************"
echo "------------------- docker pull image mysql 5.5"
echo "*******************************************************"
docker pull mysql:5.5.62 
if [ $? -eq 0 ]; then
        echo "*******************************************************"
        echo "------------------- image pull mysql 5.5 successfully .. "
        echo "*******************************************************"
else
        echo "*******************************************************"
        echo "------------------- image pull mysql 5.5 Error please check"
        echo "*******************************************************"
        exit 1
fi
echo "*******************************************************"
echo "------------------- docker pull image phpmyadmin/phpmyadmin"
echo "*******************************************************"
docker pull phpmyadmin/phpmyadmin
if [ $? -eq 0 ]; then
        echo "*******************************************************"
        echo "------------------- image pull phpmyadmin/phpmyadmin successfully .. "
        echo "*******************************************************"
else
        echo "*******************************************************"
        echo "------------------- image pull phpmyadmin/phpmyadmin Error please check"
        echo "*******************************************************"
        exit 1
fi
echo "*******************************************************"
echo "------------------- docker pull image nginx-php5.4"
echo "*******************************************************"
docker pull danielmeneses/nginx-php5.4:latest
if [ $? -eq 0 ]; then
        echo "*******************************************************"
        echo "------------------- image pull nginx-php5.4 successfully .. "
        echo "*******************************************************"
else
        echo "*******************************************************"
        echo "------------------- image pull nginx-php5.4 Error please check"
        echo "*******************************************************"
        exit 1
fi
echo "*******************************************************"
echo "------------------- Create Directory for server data"
echo "*******************************************************"
mkdir -p /usr/service-data/etc/nginx/
mkdir -p /usr/service-data/var/www/
mkdir -p /usr/service-data/etc/php/
mkdir -p /usr/service-data/etc/mysql/

echo "*******************************************************"
echo "------------------- Create Directory for server data"
echo "*******************************************************"
mv files/php-fpm.d files/php-zts.d files/php.d files/php-fpm.conf files/php.ini files/php.ini.rpmnew /usr/service-data/etc/php/
rm -rf files
cat > /usr/service-data/etc/nginx/nginx.conf << EOF
server {
        listen 80 default_server;
        location / {
                root /var/www;
                location ~ \.php$ {
                        fastcgi_split_path_info  ^(.+\.php)(/.+)$;
                        fastcgi_index            api.php;
                        fastcgi_pass 127.0.0.1:9000;
                        include fastcgi_params;
                        fastcgi_param   PATH_INFO  \$fastcgi_path_info;
                        fastcgi_param   SCRIPT_FILENAME \$document_root\$fastcgi_script_name;

        }
        }
        location /phpmyadmin {
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$remote_addr;
                proxy_set_header Host \$host;
                proxy_pass http://phpmyadmin.local/;
                #fastcgi_param   SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                #include fastcgi_params;
                #fastcgi_param   PATH_INFO  \$fastcgi_path_info;
        }
}
EOF
cat > docker-compose.yml << EOF
version: '3.8'
services:
  nginx-php:
    image: danielmeneses/nginx-php5.4
    container_name: nginx-php
    hostname: nginx-php-mysql.local
    restart: unless-stopped
    networks:
          network-bridge:
            aliases:
              - nginx-php.local
    ports:
      - 80:80
      - 443:443
      - 11211:11211
    volumes:
      - /usr/service-data/var/www/:/var/www/:rw
      - /usr/service-data/etc/nginx/:/etc/nginx/conf.d/:rw
      - /usr/service-data/etc/php/php-fpm.d/:/etc/php-fpm.d/:rw
      - /usr/service-data/etc/php/php-zts.d/:/etc/php-zts.d/:rw
      - /usr/service-data/etc/php/php.d/:/etc/php.d/:rw
      - /usr/service-data/etc/php/php-fpm.conf:/etc/php-fpm.conf:rw
      - /usr/service-data/etc/php/php.ini:/etc/php.ini:rw
      - /usr/service-data/etc/php/php.ini.rpmnew:/etc/php.ini.rpmnew:rw
  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: phpmyadmin
    hostname: phpmyadmin.local
    restart: unless-stopped
    networks:
          network-bridge:
            aliases:
              - phpmyadmin.local
    environment:
      - PMA_HOST=mysql.local
      - PMA_ABSOLUTE_URI=http://${MY_IP}/phpmyadmin/
    depends_on:
      - database
      - nginx-php
  database:
    image: mysql:5.5.62
    container_name: mysql
    hostname: mysql.local
    restart: unless-stopped
    networks:
          network-bridge:
            aliases:
              - mysql.local
    volumes:
      - /usr/service-data/etc/mysql/:/var/lib/mysql/:rw
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_PASSWORD}

networks:
    network-bridge:
        driver: bridge
EOF

echo "*******************************************************"
echo "------------------- Run docker compose"
echo "*******************************************************"
docker-compose up -d
if [ $? -eq 0 ]; then
        echo "*******************************************************"
        echo "------------------- Run docker compose successfully .. "
        echo "*******************************************************"
else
        echo "*******************************************************"
        echo "------------------- Run docker compose Error please check"
        echo "*******************************************************"
        exit 1
fi

echo "*******************************************************"
echo "*******************************************************"
echo "------------------- Service Install Finished********** .. "
echo "*******************************************************"
echo "*******************************************************"
echo "*******************************************************"
echo "------------------- Your data is:"
echo "*******************************************************"
echo "phpmyadmi address :" http://${MY_IP}"/phpmyadmin/"
echo "database user :" "root"
echo "database password :" ${DB_PASSWORD}
echo "*******************************************************"
echo "------------------- How use service?"
echo "*******************************************************"
echo "please pull data on location : /usr/service-data/var/www/"