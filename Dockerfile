# Use AdoptOpenJDK base image for Java 11
FROM adoptopenjdk:11-jre-hotspot

# Set the working directory inside the container
WORKDIR /app

# Copy the packaged jar file into the container
COPY target/us-apigateway-0.0.1-SNAPSHOT.jar app.jar

# Expose the port that your Spring Boot application uses (default is 8080)
EXPOSE 4444

# Command to run the Spring Boot application when the container starts
CMD ["java", "-jar", "app.jar"]
