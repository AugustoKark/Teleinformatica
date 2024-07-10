#!/bin/bash

sudo apt-get update
sudo apt-get install -y nginx

sudo rm -f /etc/nginx/sites-enabled/default

sudo tee /etc/nginx/conf.d/lb.conf << EOF
server {
  listen 80;
  location / {
    proxy_pass http://${app_ip}:3000;
  }
}
EOF
sudo service nginx restart