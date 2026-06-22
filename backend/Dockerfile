# 阶段一：使用 Maven 镜像在云端编译
FROM maven:3.8.5-openjdk-17-slim AS build
WORKDIR /app

# 复制后端代码并编译打包
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# 阶段二：使用轻量级 JDK 运行
FROM openjdk:17-jdk-slim
WORKDIR /app

# 从编译阶段复制打包好的 jar 包
COPY --from=build /app/target/*.jar app.jar

# 暴露 Spring Boot 端口
EXPOSE 8080

# 启动命令
ENTRYPOINT ["java", "-jar", "app.jar"]