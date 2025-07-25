FROM eclipse-temurin:24.0.1_9-jre-alpine-3.21

WORKDIR /app

COPY target/naavi-identity.jar /app/naavi-identity.jar

EXPOSE 8080

CMD ["java", "-jar", "/app/naavi-identity.jar"]