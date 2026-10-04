FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -B dependency:go-offline
COPY src ./src
RUN mvn -B verify
FROM eclipse-temurin:21-jre
RUN groupadd --system finance && useradd --system --gid finance finance
WORKDIR /app
RUN mkdir /app/data && chown finance:finance /app/data
COPY --from=build /build/target/home-finance-1.0.0.jar /app/app.jar
USER finance
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
