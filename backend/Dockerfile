# 阶段一：使用官方的 Maven + Temurin JDK 17 镜像进行编译
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# 复制后端代码并编译打包
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# 阶段二：使用轻量级 alpine 版本的运行时 JRE 17 镜像，大大减小线上镜像体积
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# 从编译阶段复制打包好的 jar 包
COPY --from=build /app/target/*.jar app.jar

# 暴露 Spring Boot 端口
EXPOSE 8080

# 启动命令
ENTRYPOINT ["java", "-jar", "app.jar"]