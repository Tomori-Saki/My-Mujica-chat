# ================= 阶段一：前端打包 =================
FROM node:20-alpine AS frontend-build
WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend ./
RUN npm run build

# ================= 阶段二：后端编译 =================
FROM maven:3.9.6-eclipse-temurin-17 AS backend-build
WORKDIR /app
COPY backend/pom.xml .
COPY backend/src ./src

# 👉 核心修正：先把前端产物拷贝到源码的 resources/static 目录下
COPY --from=frontend-build /frontend/dist ./src/main/resources/static

# 👉 核心修正：去掉 clean，直接 package！
# 这样 Maven 打包时就会把 src/main/resources/static 里的前端文件稳稳地打包进最终的 Jar 包中
RUN mvn package -DskipTests

# ================= 阶段三：轻量运行时 =================
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=backend-build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]