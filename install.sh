#!/bin/bash
set -e

echo "🚀 Installing Gates Networks ISP Platform"

apt update && apt upgrade -y

apt install -y \
nginx mariadb-server redis mongodb \
php8.2 php8.2-cli php8.2-mysql php8.2-curl \
php8.2-mbstring php8.2-xml php8.2-zip \
nodejs npm freeradius freeradius-mysql \
wireguard git curl unzip keepalived

systemctl enable nginx mariadb freeradius mongodb

mysql <<EOF
CREATE DATABASE radius;
CREATE DATABASE isp_core;
CREATE USER 'gatescore'@'localhost' IDENTIFIED BY '1Am!w2k@!';
GRANT ALL PRIVILEGES ON . TO 'gatescore'@'localhost';
FLUSH PRIVILEGES;
EOF

mysql radius < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql
mysql isp_core < core/backend/database/schema.sql

cd core/backend && composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --force
php artisan optimize

cd ../frontend && npm install && npm run build

npm install -g genieacs
genieacs-cwmp & genieacs-nbi & genieacs-ui & genieacs-fs &

cd ../../whatsapp && npm install && node server.js &

wg-quick up vpn/wireguard/wg0.conf
systemctl enable wg-quick@wg0


echo "✅ INSTALL COMPLETE"
