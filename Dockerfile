FROM openjdk:21
EXPOSE 8070
ARG JAR_FILE
ADD target/${JAR_FILE} /final-barista-service.jar
ENTRYPOINT ["java", "-Duser.timezone=Asia/Taipei", "-jar", "/final-barista-service.jar"]