# ================= 阶段一：前端打包 =================
FROM node:20-alpine AS frontend-build
WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend ./
# 执行前端打包（这次让它生成在默认的 frontend/dist 里）
RUN npm run build

# ================= 阶段二：后端编译 =================
FROM maven:3.9.6-eclipse-temurin-17 AS backend-build
WORKDIR /app
COPY backend/pom.xml .
COPY backend/src ./src

# 👉 核心修改：明确从阶段一的 /frontend/dist 中，将打包好的前端静态资源
# 强行复制到 Maven 正在编译的后端的 target/classes/static 目录下（这是最终打包进 Jar 里的绝对路径）
COPY --from=frontend-build /frontend/dist ./target/classes/static

# 执行后端打包
RUN mvn clean package -DskipTests

# ================= 阶段三：轻量运行时 =================
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=backend-build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]