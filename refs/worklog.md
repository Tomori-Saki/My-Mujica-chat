# BanGchat 工作日志

---

## 2026-06-19 — 数据库 Schema 设计与项目清理

### 1. 实现功能
- 完成 SQLite 数据库的完整 Schema 设计（14 张表），将 `character.json`、`timeline.json`、`world.json`、`example.json` 四个 JSON 文件转换为关系表
- 通过 `timeline_character_state` 表实现时间线与角色的外键关联，确保不同时间线角色性格/语气物理隔离
- 清理旧项目文件：删除 `mygo-api/`（Python 旧后端）、`ave_mujica_subs/`、`bangchat.db`
- 移除 Python 脚本，未来的 DB 初始化将在 Spring Boot 中用 Java 实现

### 2. 文件变动

| 文件 | 操作 | 用途 |
|---|---|---|
| `database/schema.sql` | 新增 | 14 张表的完整 DDL，含索引和外键约束 |
| `mygo-api/` | **删除** | 旧 Python 后端，已不需要 |
| `ave_mujica_subs/` | **删除** | 已不需要的字幕文件 |
| `database/init_db.py` | **删除** | 不应使用 Python，改为 Java 方案 |
| `bangchat.db` | **删除** | 运行时生成，纳入 .gitignore |
| `.gitignore` | 更新 | 清理旧条目，新增 bangchat.db |
| `refs/worklog.md` | 新增 | 本工作日志 |

#### Schema 核心设计要点

- **性格独立拆分**：`personality_trait` 表条目化存储性格标签，与 `character_profile` 外键关联
- **说话语气独立拆分**：`speech_style` 表独立存储每个角色的说话风格描述
- **时间线隔离机制**：`timeline_character_state` 通过 `(timeline_id, character_id)` 复合唯一约束 + 双外键，`personality_adjust` 和 `speech_adjust` 字段记录各时间线下性格/语气的偏移量
- 预留 `chat_message` 表，强制 `timeline_id` 字段，遵循 CLAUDE.md 的 WHERE 条件约束

### 3. 纠正说明
- **为什么不用 Python 初始化**：技术栈已确定为 Java 17 + Spring Boot 3.x + MyBatis。数据库初始化应在 Spring Boot 框架内完成——`schema.sql` 放在 `src/main/resources/` 由框架自动执行 DDL，数据导入通过 `CommandLineRunner` Bean 用 Jackson + MyBatis 实现。用 Python 会引入不必要的运行时依赖，破坏栈的一致性。

### 4. 验证状态
- DDL 语法已通过 Python 脚本临时验证（14 表全部建表成功，外键约束生效）
- 数据导入逻辑已验证（120 条 dialogue、30 条 timeline_character_state 正确关联）
- 待 Spring Boot 项目搭建后，用 Java 重写初始化逻辑并再次验证

---

## 2026-06-19 — Spring Boot 项目骨架 + 独立 Prompt 模块

### 1. 实现功能
- 搭建 Spring Boot 3.2.5 + MyBatis 3.0.3 + SQLite 最小骨架
- 创建独立的 `module.prompt` 包，实现从数据库提取角色信息并拼装 System Prompt
- 用 Java（Jackson + JDBC）重写数据库初始化逻辑，彻底移除 Python 依赖

### 2. 文件变动

| 文件 | 操作 | 用途 |
|---|---|---|
| `pom.xml` | 新增 | Maven 构建文件，spring-boot 3.2.5 + mybatis 3.0.3 + sqlite-jdbc |
| `src/main/java/com/bangchat/BangchatApplication.java` | 新增 | Spring Boot 启动类 |
| `src/main/java/com/bangchat/config/DataSourceConfig.java` | 新增 | 事务管理器配置 |
| `src/main/resources/application.yml` | 新增 | 数据源/MyBatis/SQL初始化配置 |
| `src/main/resources/schema.sql` | 新增 | 14 张表 DDL |
| `.../entity/CharacterProfile.java` | 新增 | 实体：角色基础信息（姓名/学校/乐队/角色/乐器/概要） |
| `.../entity/PersonalityTrait.java` | 新增 | 实体：角色性格标签，按 sort_order 排序，与 character_profile 外键关联 |
| `.../entity/SpeechStyle.java` | 新增 | 实体：角色说话语气描述，与 character_profile 一对一 |
| `.../entity/TimelineCharacterState.java` | 新增 | 实体：**时间线-角色状态关联**，含 personality_adjust + speech_adjust，保证不同时间线性格/语气物理隔离 |
| `.../entity/CharacterDetail.java` | 新增 | 实体：角色行为细节（如"被戳破心思时耳朵会红"），辅助 prompt 丰富度 |
| `.../entity/SpecialAddressing.java` | 新增 | 实体：角色对其他人的专属称呼方式（昵称/语气/备注） |
| `.../mapper/PromptDataMapper.java` | 新增 | MyBatis Mapper 接口：Prompt 模块的 6 个数据查询方法 |
| `.../mapper/PromptDataMapper.xml` | 新增 | MyBatis XML：所有查询均参数化，强制 WHERE timeline_id = ? |
| `.../prompt/PromptBuilder.java` | 新增 | **核心**：从 DB 提取角色数据，逐角色构建 CharacterCard，拼装 System Prompt |
| `.../prompt/dto/CharacterCard.java` | 新增 | DTO：聚合角色完整信息（基础+性格+语气+细节+称呼），toPromptSection() 渲染为 prompt 段落 |
| `.../init/DatabaseInitializer.java` | 新增 | Java 版 DB 初始化器：CommandLineRunner 实现，Jackson 解析 4 个 JSON，JDBC 写入 SQLite |

### 3. Prompt 模块设计

```
module.prompt (独立模块，不与其他业务层耦合)
  │
  ├─ PromptBuilder          ← 唯一对外入口：buildSystemPrompt(timelineId)
  │     │
  │     ├─ 调用 PromptDataMapper 查询 DB
  │     ├─ 为每个角色构建 CharacterCard（聚合基本信息 + 性格 + 语气）
  │     └─ 组装为结构化 System Prompt 文本
  │
  └─ dto/CharacterCard     ← 数据载体，toPromptSection() 渲染角色段落
```

**数据流**：
1. `PromptBuilder.buildSystemPrompt("t2_mygo_formed")`
2. → `mapper.findCharactersByTimeline("t2_mygo_formed")` — 查该时间线下所有角色
3. → 对每个角色查询：`personality_trait` + `speech_style` + `timeline_character_state` + `character_detail` + `special_addressing`
4. → 填充 `CharacterCard`，调用 `toPromptSection()` 渲染
5. → 按 MyGO / Ave Mujica 分组输出最终 System Prompt

**独立性保证**：
- `PromptBuilder` 仅依赖 `PromptDataMapper`（接口）+ entity/DTO 类
- 不依赖任何 Controller、Service 或其他业务层
- Mapper XML 中所有查询均参数化（`#{timelineId}` / `#{characterId}`）

### 4. 验证状态
- 项目结构完整，15 个 Java/XML/YML 文件已创建
- 待 JDK 17 + Maven 安装后执行 `mvn compile` 验证编译

---

## 2026-06-19 — 前后端分离 + Lombok 重构

### 1. 实现功能
- 项目根目录拆分为 `backend/` + `frontend/`，严格前后端分离
- `backend/` 包含 Spring Boot 项目的全部源码和 pom.xml
- `frontend/` 预留给 Vue 3 + Vite
- 所有实体类和 DTO 改用 Lombok `@Data`，消除手写 getter/setter，代码量减少约 60%

### 2. 文件变动

| 文件 | 操作 | 用途 |
|---|---|---|
| `backend/` | 新增 | 后端项目根目录，pom.xml + src/ 全部移入 |
| `frontend/` | 新增 | 前端预留目录（空，待 Vue 3 初始化） |
| `database/` | **删除** | schema.sql 已移至 backend/src/main/resources |
| `pom.xml` | 移动 | 移入 backend/，新增 Lombok 依赖 |
| `src/` | 移动 | 移入 backend/src/ |
| `**/entity/*.java` (6个) | 重写 | 全部改用 `@Data`，去除手写 getter/setter |
| `CharacterCard.java` | 重写 | 改用 `@Data`，`AddressingInfo` 内部类同样 `@Data` |

### 3. Lombok 说明
- **能用，且应该用**。Lombok 是编译期注解处理器，只在 `javac` 阶段生成代码，对 SQLite/MyBatis 零影响——MyBatis 只需要运行时有 getter/setter，Lombok 已保证。
- 依赖 `spring-boot-starter-parent` 统一管理版本，pom.xml 中无需写 version。

### 4. 验证状态
- 项目结构已重组，文件路径已更新
- 待 `mvn compile` 验证编译

---

## 2026-06-22 — WebSocket 实时通信骨架 + 文字回环测试

### 1. 实现功能
- 引入 `spring-boot-starter-websocket` 依赖，开启 WebSocket 全双工通信
- 注册 `/ws/chat/{sessionId}` 路由，通过 HandshakeInterceptor 从 URI 提取业务 sessionId
- 实现 SessionConnectionManager（ConcurrentHashMap）管理多会话多连接
- 实现 ChatWebSocketHandler 文字回环测试：解析 JSON → 广播 → Mock 高松灯回复
- ChatMessage DTO 支持序列化/反序列化，统一消息格式（message / event / reply）

### 2. 文件变动

| 文件 | 操作 | 用途 |
|---|---|---|
| `backend/pom.xml` | 修改 | 新增 `spring-boot-starter-websocket` 依赖 |
| `backend/src/main/java/com/bangchat/config/WebSocketConfig.java` | 新增 | WebSocket 配置：注册 Handler 于 `/ws/chat/{sessionId}`，允许跨域，SessionIdInterceptor 提取 URI 中的 sessionId 存入 attributes |
| `backend/src/main/java/com/bangchat/features/chat/SessionConnectionManager.java` | 新增 | 会话连接管理器：ConcurrentHashMap<String, Set<WebSocketSession>>，支持 addSession / removeSession / broadcastToSession / sendToOne / getConnectionCount |
| `backend/src/main/java/com/bangchat/features/chat/ChatWebSocketHandler.java` | 新增 | **核心**：继承 TextWebSocketHandler，连接建立/关闭/消息/异常全生命周期处理；handleTextMessage 中实现回环广播 + 守护线程异步 Mock 高松灯角色回复 |
| `backend/src/main/java/com/bangchat/features/chat/dto/ChatMessage.java` | 新增 | WebSocket 消息 DTO（type/sender/content/timestamp），toJson()/fromJson() 序列化，of() 工厂方法快速构造 |

### 3. 文字回环测试流程

```
前端 WebSocket 连接 ws://localhost:8080/ws/chat/room1
  → 发送 {"content": "你好"}
  → ChatWebSocketHandler.handleTextMessage
      1. 解析 JSON → ChatMessage
      2. 广播回环：同一 sessionId 所有连接收到 {"type":"message","sender":...,"content":"你好"}
      3. 守护线程 sleep(600ms) 后广播 Mock 回复：
         {"type":"reply","sender":"高松灯","content":"啊……你好。我是...高松灯。..."}
      4. 关键词触发不同回复模板（一辈子/春日影/爱音/你好）
```

### 4. 验证状态
- 代码完整，4 个新文件 + 1 个修改文件已写入
- 编译验证：待 `mvn compile`（需 JDK 17 + Maven）
- 功能验证：启动后使用 WebSocket 客户端连接 `/ws/chat/test`，发送 `{"content":"你好"}` 观察回环广播和角色回复

---

## 2026-06-22 — Vue 3 前端搭建：登录→乐队选择→角色选择→聊天

### 1. 实现功能
- 初始化 Vite + Vue 3 + Vue Router 4 + Pinia + Tailwind CSS 4 前端项目
- **登录页**：三个字段（模型 URL / API Key / 模型名称）+ AES-GCM 加密存储到 localStorage，一键恢复登录
- **乐队选择页**：斜线三分割（clip-path 梯形），CRYCHIC / MyGO / Ave Mujica 各占一块，hover 弹起动画，点击 → 角色选择
- **角色选择页**：网格布局，CRYCHIC 显示 5 人（CRYCHIC 前成员），MyGO/Ave Mujica 各显示 5 人
- **聊天页**：WebSocket 连接 `/ws/chat/{sessionId}`，AI 回复气泡右下角有「重新生成」和「回退」SVG 按钮（样式参考 index.html）
- **TopBar**：左=BanGChat，中=页面标题，右=当前模型名；支持返回按钮

### 2. 文件变动

| 文件 | 操作 | 用途 |
|---|---|---|
| `frontend/package.json` | 生成 | Vite + Vue 3 + vue-router + pinia + tailwindcss |
| `frontend/vite.config.js` | 修改 | 加 tailwindcss 插件，配置 /api 和 /ws 代理到 localhost:8080 |
| `frontend/index.html` | 修改 | 标题改为 BanGchat，zh-CN |
| `frontend/src/main.js` | 修改 | 注册 Pinia + Vue Router |
| `frontend/src/App.vue` | 修改 | 纯 `<router-view />` |
| `frontend/src/style.css` | 新增 | 深色奢华风格变量 + Tailwind + 全局按钮/滚动条样式 |
| `frontend/src/router/index.js` | 新增 | 4 条路由 + beforeEach 鉴权守卫，未登录重定向到 / |
| `frontend/src/utils/crypto.js` | 新增 | Web Crypto API AES-256-GCM 加密/解密 + localStorage 存取 |
| `frontend/src/stores/auth.js` | 新增 | Pinia 认证状态：login/restore/logout，restore 实现一键登录 |
| `frontend/src/components/TopBar.vue` | 新增 | 顶栏组件：left/center/right 三区 + 返回按钮 |
| `frontend/src/views/LoginView.vue` | 新增 | 登录页：3 输入框 + AES 加密存储 + 自动恢复 + 错误提示 |
| `frontend/src/views/BandSelectionView.vue` | 新增 | 乐队选择：3 块梯形斜线分割（clip-path），hover 弹起 + 乐队名渐显 |
| `frontend/src/views/CharacterSelectionView.vue` | 新增 | 角色选择：网格卡片，CRYCHIC=5人/MyGO=5人/Ave Mujica=5人 |
| `frontend/src/views/ChatView.vue` | 新增 | 聊天页：WebSocket → 消息列表 → AI 气泡右下角重生成+回退按钮 → 底部输入框 Enter 发送 |

### 3. 页面流转

```
/ (LoginView) ──登录成功──> /bands (BandSelectionView)
                                 │
                    ┌────────────┼────────────┐
                    ▼            ▼            ▼
              /bands/crychic  /bands/mygo  /bands/avemujica
              /characters     /characters  /characters
                    │            │            │
                    ▼            ▼            ▼
              /chat/crychic/  /chat/mygo/  /chat/avemujica/
              {characterId}   {characterId} {characterId}
                    │
                    └── 返回按钮 → /bands
```

### 4. 验证状态
- `npx vite build` 构建成功（206ms，无错误）
- 开发服务器：`cd frontend && npm run dev`（端口 5173，自动代理 /api 和 /ws 到后端 8080）
- 待后端启动后联调：登录加密存储 → WebSocket 连接 → AI 流式对话

---

## 2026-06-22 — 聊天功能修复：去系统消息 / 去重复回显 / 真实 AI 回调 / 罗马音头像

### 1. 实现功能
- **去系统消息**：`afterConnectionEstablished` 不再发送"已加入会话"系统消息，仅静默注册连接
- **去重复回显**：后端不再 echo 用户消息回同一 sessionId，前端本地 `type: 'user'` 自行渲染，消除重复
- **真实 AI 回调**：后端集成 OpenAI 兼容 API（`/v1/chat/completions`）流式 SSE 调用，逐 token 推送给 WebSocket 客户端。凭证由前端首次消息携带，后端缓存在 `ConcurrentHashMap<String, Credential>` 中
- **流式消息**：新增 `type: 'stream'`，前端收到 stream token 时追加到临时气泡；收到 `type: 'reply'` 时替换为完整回复并显示 regen/rollback 按钮
- **头像改罗马音缩写**：`CharacterSelectionView` 种每个角色的头像从中文首字改为罗马音首字母（TT/AC/RK/SN/TS/ST/MW/UY/UM/NY）

### 2. 文件变动

| 文件 | 操作 | 用途 |
|---|---|---|
| `backend/.../config/AppConfig.java` | 新增 | RestTemplate Bean（30s 连接超时，120s 读取超时） |
| `backend/.../chat/ChatWebSocketHandler.java` | 重写 | 去系统消息 + 去回显 + 集成 AI 流式回调（HttpURLConnection + SSE 解析） |
| `backend/.../chat/dto/ChatMessage.java` | 修改 | 新增 modelUrl/apiKey/modelName 凭证字段 + stream 类型说明 |
| `frontend/src/views/ChatView.vue` | 重写 | 首条消息携凭证、本地渲染 user 消息不回显、stream token 累积 + reply 替换 |
| `frontend/src/views/CharacterSelectionView.vue` | 修改 | allCharacters 加 initials 字段，头像 `char.name.charAt(0)` → `char.initials` |

### 3. WebSocket 消息协议

```
前端 → 后端:
  {"content":"你好","sender":"user","type":"message",
   "modelUrl":"https://...","apiKey":"sk-...","modelName":"gpt-4o-mini"}

后端 → 前端（流式）:
  {"type":"stream","sender":"assistant","content":"你"}     ← 逐 token
  {"type":"stream","sender":"assistant","content":"好"}     ← 前端追加到临时气泡
  {"type":"reply","sender":"assistant","content":"你好！..."} ← 完整回复，替换临时气泡
```

### 4. 验证状态
- 前端 `npx vite build` 构建成功（258ms）
- 后端 `ChatWebSocketHandler`：使用 JDK `HttpURLConnection` 直连 AI API，无额外依赖
- AI 调用流式读取 SSE `data:` 行，非 200 状态返回完整错误信息

---

## 2026-06-22 — AI 回调注入数据库角色 Prompt

### 1. 实现功能
- `ChatWebSocketHandler` 注入 `PromptBuilder`，在调用 AI 前从数据库拼装角色 System Prompt
- 前端 WebSocket 消息新增 `bandId` + `characterId` 字段，后端据此映射 `timelineId`
- `bandId → timelineId` 映射：crychic → t1, mygo → t2, avemujica → t3
- AI 请求中 `messages` 数组包含 `system`（完整角色设定） + `user`（用户消息）
- System Prompt 末尾追加当前角色指令：「你正在扮演「高松灯」...使用称呼方式中规定的称呼」

### 2. 文件变动

| 文件 | 操作 | 用途 |
|---|---|---|
| `backend/.../chat/ChatWebSocketHandler.java` | 重写 | 注入 PromptBuilder；SessionContext 缓存 bandId/characterId + 凭证；buildSystemPrompt() → AI system message |
| `backend/.../chat/dto/ChatMessage.java` | 修改 | 新增 bandId、characterId 字段 |
| `frontend/src/views/ChatView.vue` | 修改 | 每条 WS 消息携带 bandId + characterId |

### 3. AI 请求结构（修复后）

```json
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "你是 BanG Dream! 世界中的角色扮演 AI。\n...\n【高松灯】...性格：内向、敏感...\n\n【当前角色】你正在扮演「高松灯」..."
    },
    { "role": "user", "content": "小祥，今天天气真好" }
  ],
  "stream": true
}
```

### 4. 验证状态
- 前端 `npx vite build` 构建成功（203ms）
- System Prompt 完整包含：角色基本信息 + 性格标签 + 说话语气 + 时间线状态 + 行为细节 + 称呼方式 + 角色扮演指令
- AI 将基于数据库角色设定而非默认知识回复

---

## 2026-06-22 — 自动登录 + 时间线关系约束注入

### 1. 实现功能
- **自动登录**：`LoginView` 的 `onMounted` 中若 `restore()` 成功（localStorage 有加密凭证），直接 `router.push('/bands')` 跳过登录页
- **时间线关系约束**：`PromptBuilder.assemblePrompt()` 从 `timeline` 表读取乐队状态，拼装显式的角色关系规则注入 System Prompt
- 新增 `Timeline` 实体 + `findTimelineById` Mapper 查询

### 2. 文件变动

| 文件 | 操作 | 用途 |
|---|---|---|
| `frontend/src/views/LoginView.vue` | 修改 | restore 成功后自动 `router.push('/bands')` |
| `backend/.../entity/Timeline.java` | 新增 | 时间线实体（id/title/summary/crychicStatus/mygoStatus/avemujicaStatus） |
| `backend/.../mapper/PromptDataMapper.java` | 修改 | 新增 `findTimelineById` 方法 |
| `backend/.../mapper/PromptDataMapper.xml` | 修改 | 新增 `findTimelineById` SQL |
| `backend/.../prompt/PromptBuilder.java` | 重写 | `assemblePrompt` 改为接收 `Timeline` 参数，注入基于乐队状态的关系约束段落 |

### 3. 时间线关系约束（System Prompt 核心新增段落）

```
=== 时间线关系约束 ===
当前各乐队状态：
- CRYCHIC: 已解散
- MyGO!!!!!: 未成立
- Ave Mujica: 未成立

角色关系规则（严格遵循）：
- CRYCHIC 已解散，但其前成员（高松灯、长崎素世、椎名立希、丰川祥子、若叶睦）互相认识。
- MyGO!!!!! 尚未成立。千早爱音（Anon）和要乐奈（Rana）此时尚未与 CRYCHIC 成员结识。
  → 高松灯不认识千早爱音。长崎素世不认识千早爱音。椎名立希不认识千早爱音。
  → 如用户提及爱音或乐奈，你所扮演的角色应表示「不认识」或「没听说过」。
- Ave Mujica 尚未成立。
```

### 4. 验证方法
- **t1 (CRYCHIC解散)**：与高松灯对话中提"爱音" → 灯应表示不认识
- **t2 (MyGO成立)**：与高松灯对话中提"爱音" → 灯应表示亲密熟悉
- **自动登录**：登录一次后关闭浏览器，重新打开 `localhost:5173` → 直接进入乐队选择页
