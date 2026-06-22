# ================= 阶段一：前端打包 =================
FROM node:20-alpine AS frontend-build
WORKDIR /frontend
# 此时位于根目录，直接访问 frontend 文件夹
COPY frontend/package*.json ./
RUN npm install
COPY frontend ./
# 执行前端打包（产物会自动进到 backend/src/main/resources/static）
RUN npm run build

# ================= 阶段二：后端编译 =================
FROM maven:3.9.6-eclipse-temurin-17 AS backend-build
WORKDIR /app
# 复制后端代码
COPY backend/pom.xml .
COPY backend/src ./src

# 从阶段一中，把前端打包好的静态文件，复制到后端的静态资源目录中
COPY --from=frontend-build /frontend/dist ./src/main/resources/static

# 执行后端打包
RUN mvn clean package -DskipTests

# ================= 阶段三：轻量运行时 =================
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=backend-build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]