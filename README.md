# BanGchat — AI 角色扮演聊天

与《BanG Dream! It's MyGO!!!!!》和《BanG Dream! Ave Mujica》中的角色进行 AI 驱动的角色扮演对话。选择故事时间线节点和角色，AI 会基于角色设定、世界观和时间线状态，以该角色的身份与你实时对话。

## 技术栈

| 层 | 技术 |
|---|------|
| 后端 | Java 17, Spring Boot 3.2.5, MyBatis 3.0.3, Spring WebSocket |
| 前端 | Vue 3 (Composition API), Vite, Tailwind CSS |
| 数据库 | SQLite (`bangchat.db`) |
| 认证 | Spring Security + JWT（API Key 模式） |
| AI 交互 | OpenAI 兼容 `/v1/chat/completions`，SSE 流式转发 |

## 项目结构

```
MyGo_chat/
├── backend/                              ← Spring Boot 后端
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/bangchat/
│       │   ├── BangchatApplication.java  ← 启动入口
│       │   ├── config/
│       │   │   ├── DataSourceConfig.java ← 数据源 + 事务管理器
│       │   │   └── WebSocketConfig.java  ← WebSocket 路由注册 /ws/chat/{sessionId}
│       │   ├── data/
│       │   │   ├── entity/               ← MyBatis 实体（@Data）
│       │   │   │   ├── CharacterProfile.java      ← character_profile 表
│       │   │   │   ├── PersonalityTrait.java      ← personality_trait 表
│       │   │   │   ├── SpeechStyle.java           ← speech_style 表
│       │   │   │   ├── TimelineCharacterState.java← timeline_character_state 表 ★核心隔离
│       │   │   │   ├── CharacterDetail.java       ← character_detail 表
│       │   │   │   └── SpecialAddressing.java     ← special_addressing 表
│       │   │   └── mapper/
│       │   │       └── PromptDataMapper.java      ← Prompt 模块专用 Mapper
│       │   ├── features/
│       │   │   └── chat/                 ← 聊天功能模块
│       │   │       ├── ChatWebSocketHandler.java   ← WebSocket 消息处理 + 回环测试
│       │   │       ├── SessionConnectionManager.java← ConcurrentHashMap 会话管理
│       │   │       └── dto/
│       │   │           └── ChatMessage.java        ← 消息 DTO（JSON 序列化）
│       │   ├── init/
│       │   │   └── DatabaseInitializer.java← CommandLineRunner：JSON → SQLite
│       │   └── module/
│       │       └── prompt/               ← 独立 Prompt 模块
│       │           ├── PromptBuilder.java ← 从 DB 提取角色数据拼装 System Prompt
│       │           └── dto/
│       │               └── CharacterCard.java ← 角色信息聚合 DTO + 渲染
│       └── resources/
│           ├── application.yml
│           ├── schema.sql                ← 14 张表 DDL（含 api_credential 预留）
│           └── mapper/
│               └── PromptDataMapper.xml  ← MyBatis SQL 映射
├── frontend/                             ← Vue 3 前端（待初始化）
├── character.json                        ← 10 位角色定义
├── timeline.json                         ← 3 个故事时间线节点
├── world.json                            ← 世界观设定
├── example.json                          ← 动画台词示例
└── refs/
    └── worklog.md                        ← 工作日志
```

## 数据库核心设计

```
character_profile ──┐
  ├─ personality_trait[] (1:N)  性格标签按条目独立存储
  ├─ speech_style      (1:1)   说话语气独立存储
  ├─ character_detail[] (1:N)  行为细节
  ├─ special_addressing[](1:N) 角色间专属称呼 ★
  └─ character_tag[]    (1:N)  角色标签
         │
timeline ─┼──> timeline_character_state (N:M)  ★ 时间线隔离关键
         │     ├─ state_description   当前状态
         │     ├─ personality_adjust  性格偏移
         │     └─ speech_adjust       语气偏移
```

- **角色间称呼**：`special_addressing` 表记录每个角色对其他人的专属昵称、叫法和语气备注。如爱音称呼灯为「Tomorin」（语气柔软）、称呼素世为「Soyorin」（专属，拖长音）。
- **时间线隔离**：`timeline_character_state` 通过 `(timeline_id, character_id)` 复合唯一约束 + 双外键，确保同一角色在不同时间线拥有独立的性格/语气状态。

## 角色一览

### MyGO!!!!!
| 角色 | 担当 | 乐器 | 学校 |
|------|------|------|------|
| 高松灯 (Tomori) | 主唱 | 人声 | 羽丘女子学园 |
| 千早爱音 (Anon) | 节奏吉他 | 吉他 | 羽丘女子学园 |
| 要乐奈 (Rāna) | 主音吉他 | 吉他 | 花咲川女子学园 |
| 长崎素世 (Soyo) | 贝斯 | 贝斯 | 月之森女子学园 |
| 椎名立希 (Taki) | 鼓手 | 鼓 | 花咲川女子学园 |

### Ave Mujica
| 角色 | 舞台名 | 担当 | 学校 |
|------|--------|------|------|
| 丰川祥子 (Sakiko) | Oblivionis | 键盘/领队 | 羽丘女子学园 |
| 若叶睦 (Mutsumi) | Mortis | 吉他 | 月之森女子学园 |
| 八幡海铃 (Umiri) | Timoris | 贝斯 | 花咲川女子学园 |
| 三角初华 (Uika) | Doloris | 主唱/吉他 | 花咲川女子学园 |
| 祐天寺喵梦 (Nyamu) | Amoris | 鼓手 | — |

## 时间线

| 节点 ID | 说明 |
|---------|------|
| `t1_crychic_after` | CRYCHIC 刚解散，MyGO 未成立，角色处于最脆弱状态 |
| `t2_mygo_formed` | MyGO 成立并解决矛盾，Ave Mujica 尚未出现 |
| `t3_both_formed` | 双团并存，Ave Mujica 以假面舞台身份出道 |

## 快速开始

```bash
cd backend
mvn spring-boot:run
```

启动后：
- 数据库自动创建并导入 JSON 数据
- WebSocket 端点：`ws://localhost:8080/ws/chat/{sessionId}`
- REST API：`http://localhost:8080/api/...`
