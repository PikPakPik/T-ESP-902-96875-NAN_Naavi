FROM maven:3.9-eclipse-temurin-21-alpine

WORKDIR /usr/share/app

RUN apk add --no-cache inotify-tools openssl

RUN mkdir -p /usr/share/naavi_shared_data

RUN openssl genrsa -passout pass:defaultPassword -out /usr/share/naavi_shared_data/default.private.pem -aes256 4096
RUN openssl rsa -pubout -in /usr/share/naavi_shared_data/default.private.pem -out /usr/share/naavi_shared_data/default.public.pem -passin pass:defaultPassword

RUN openssl genrsa -passout pass:defaultPassword -out /usr/share/naavi_shared_data/auth.private.pem -aes256 4096
RUN openssl rsa -pubout -in /usr/share/naavi_shared_data/auth.private.pem -out /usr/share/naavi_shared_data/auth.public.pem -passin pass:defaultPassword

RUN openssl genrsa -passout pass:defaultPassword -out /usr/share/naavi_shared_data/exchange.private.pem -aes256 4096
RUN openssl rsa -pubout -in /usr/share/naavi_shared_data/exchange.private.pem -out /usr/share/naavi_shared_data/exchange.public.pem -passin pass:defaultPassword

CMD ["sh", "/usr/share/watch.sh"]