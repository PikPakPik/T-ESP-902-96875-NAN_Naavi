FROM eclipse-temurin:24.0.1_9-jre-alpine-3.21

WORKDIR /app

COPY target/naavi-hike.jar /app/naavi-hike.jar

EXPOSE 8080

CMD ["java", "-jar", "/app/naavi-hike.jar"]