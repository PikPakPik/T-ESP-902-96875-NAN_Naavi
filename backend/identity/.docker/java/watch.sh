#!/bin/sh

JAVA_PID=0

mvn spring-boot:run -Pdev &
JAVA_PID=$!
echo "Application lancée initialement avec PID=$JAVA_PID"

inotifywait -m -r -e close_write --format '%w%f' --exclude '.*\.swp$' /usr/share/app/src/main/java | while read file; do
    echo "Modification détectée : $file"

    echo "Killing process java PID=$JAVA_PID"
    kill $JAVA_PID
    wait $JAVA_PID 2>/dev/null

    echo "Redémarrage de l'application avec mvn spring-boot:run..."
    mvn spring-boot:run -Pdev &
    JAVA_PID=$!
    echo "Nouvelle instance java lancée avec PID=$JAVA_PID"
done
