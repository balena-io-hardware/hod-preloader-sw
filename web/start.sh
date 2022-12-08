# !/bin/bash

htpasswd -b -c /etc/apache2/.htpasswd $NGINX_USER $NGINX_PASS
rc-service apache2 nginx