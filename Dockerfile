# ================= 阶段一：前端打包 =================
FROM node:20-alpine AS frontend-build
WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend ./
# 执行前端打包（因为配置了 vite.config.js，产物会直接吐进 backend 目录）
RUN npm run build

# ================= 阶段二：后端编译 =================
FROM maven:3.9.6-eclipse-temurin-17 AS backend-build
WORKDIR /app

# 先把包含前端打包产物的全部后端代码复制进来
COPY backend/pom.xml .
COPY backend/src ./src

# 👉 核心修改：删掉了之前报错的 COPY --from=frontend-build 行。
# 因为在“阶段一”中，文件已经通过相对路径进到 backend/src/main/resources/static 了，所以不需要二次复制。

# 执行后端打包
RUN mvn clean package -DskipTests

# ================= 阶段三：轻量运行时 =================
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=backend-build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]