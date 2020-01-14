# Start with a base image containing maven
FROM maven:3.6.2-jdk-11-slim AS mvnbuild

# copy the project files
COPY . .

# build all dependencies for offline use
RUN mvn dependency:go-offline -B -q

# USER maven
RUN mvn test -q \
 && mvn --offline -B -Dmaven.test.skip=true package

# Then, continue with a base image containing Java runtime
FROM amazoncorretto:11.0.2

RUN curl --silent --location -o /rds-combined-ca-bundle.pem https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem

# Bundle app source built by Maven
COPY --from=mvnbuild /target/spring-petclinic-*.jar /spring-petclinic.jar

# Add a volume pointing to /tmp
VOLUME /tmp

ENTRYPOINT ["java", "-Dspring.profiles.active=rds", "-jar", "spring-petclinic.jar"]

EXPOSE 8080