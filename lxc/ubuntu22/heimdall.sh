#!/bin/bash
#sources:
#https://docs.organizr.app/installation/installing-organizr#ubuntu-and-debian
#https://www.reddit.com/r/selfhosted/comments/g0fgbr/run_heimdall_in_an_lxc_instead_of_docker/
#https://partrobot.ai/blog/heimdall-nginx/

#Script details
service_name="Heimdall"
config="php7.4, nginx"

echo "This script will install:$service_name."
echo "The configuration is based on:$config."

echo "Running as root..."

#Common LXC setup
default_user=$1
echo "Creating default user $default_user"
adduser $default_user
usermod -aG sudo $default_user

apt update -y
apt upgrade -y

#Install service
echo "Installing $service_name..."
#repo to get php7.4 on ubuntu 22
apt install -y software-properties-common git nginx sqlite3 openssl
add-apt-repository ppa:ondrej/php
apt update

apt install -y php7.4 php7.4-fpm php7.4-sqlite3 php7.4-xml php7.4-zip php7.4-curl php7.4-mbstring php7.4-common

git clone https://github.com/linuxserver/Heimdall.git /opt/heimdall

rm -R /var/www/html
ln -s /opt/heimdall/public/ /var/www/html

cat <<EOF > /etc/nginx/sites-enabled/default
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;

        index index.php index.html default.php welcome.php index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                try_files \$uri \$uri/ /index.php?\$query_string;
                autoindex on;
                sendfile off;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        }

        location ~ /\.ht {
                deny all;
        }
}

EOF

cd /opt/heimdall

#call twice in case the first attempt is skipped due to default "no"
php artisan key:generate
php artisan key:generate

chown -R www-data:www-data /opt/heimdall/
chmod -R 755 /opt/heimdall/

systemctl restart nginx

echo "Heimdall installation complete!"