FROM nginx:1.21.3-alpine

WORKDIR /usr/src/app

RUN apk add --no-cache apache2-utils

COPY default.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html

COPY start.sh .
RUN chmod +x start.sh

# CMD [ "/usr/src/app/start.sh" ]
