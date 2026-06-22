# ================= 阶段一：前端打包 =================
FROM node:18-alpine AS frontend-build
WORKDIR /frontend
# 复制前端代码
COPY ../frontend/package*.json ./
RUN npm install
COPY frontend ./
# 执行打包，由于配置了 vite.config.js，它会自动把产物吐到后端的 static 目录
RUN npm run build

# ================= 阶段二：后端编译 =================
FROM maven:3.9.6-eclipse-temurin-17 AS backend-build
WORKDIR /app
COPY backend/pom.xml .
COPY backend/src ./src

# 关键：从阶段一中，把前端打包好的静态文件，复制到后端的静态资源目录中
COPY --from=frontend-build /backend/src/main/resources/static ./src/main/resources/static

# 执行后端打包
RUN mvn clean package -DskipTests

# ================= 阶段三：轻量运行时 =================
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=backend-build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]