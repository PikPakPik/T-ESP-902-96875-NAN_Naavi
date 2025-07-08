FROM maven:3.9-eclipse-temurin-21-alpine

WORKDIR /usr/share/app

RUN apk add --no-cache inotify-tools

CMD ["sh", "/usr/share/watch.sh"]