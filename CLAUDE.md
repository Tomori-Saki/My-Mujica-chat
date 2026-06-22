# CLAUDE.md - BanGchat Fullstack Refactor Spec

## 1. 技术栈 (Tech Stack)
- **后端 (Backend)**: Java 17, Spring Boot 3.x, MyBatis
- **前端 (Frontend)**: Vue 3 (Composition API), Vite, Tailwind CSS
- **数据库 (Database)**: SQLite (本地单文件存储 `bangchat.db`)
- **认证 (Auth)**: Spring Security + JWT 令牌认证 (前期提供单账号 `admin` 鉴权)
- **AI 交互**: 兼容 OpenAI 格式的 /v1/chat/completions, 后端支持 SSE (Server-Sent Events) 流式转发

## 2. 架构风格 (Architecture Style)
- **前后端完全分离**: 前端 Vue 通过 Axios 统一调用后端 RESTful API。
- **标准的领域驱动分层**: 后端遵循 `Controller` (控制层) -> `Service` (业务逻辑层) -> `Mapper` (MyBatis 持久层) -> `DO/VO/DTO` (数据对象模型) 架构。
- **状态物理隔离**: 严格禁止跨时间线数据混淆。所有聊天记录 (`chat_message` 表) 必须包含 `timeline_id` 字段，持久层检索必须强制挂载 `WHERE timeline_id = ?` 参数化条件。

## 3. 工作日志规范 (Mandatory Work Log)
每次会话/功能实现结束后，必须在末尾追记工作日志：
1. **实现功能**: 清晰写明这一次实现了什么业务功能。
2. **文件变动**: 列出本次新增或修改的文件路径，并说明其具体用途。
3. **验证状态**: 明确该功能是否经过验证 (或通过何种方式测试)。

## 4. 代码编写规范
编写代码的时候，在每一个方法里都要用标准的javadoc写明注释，包含功能描述，参数描述，返回值和可能抛出的异常。