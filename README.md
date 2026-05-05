# BanGchat — AI 角色扮演聊天

与《BanG Dream! It's MyGO!!!!!》和《BanG Dream! Ave Mujica》中的角色进行 AI 驱动的角色扮演对话。选择故事时间线节点和角色，AI 会基于角色设定、世界观和时间线状态，以该角色的身份与你实时对话。

## 特性

- **10 位可聊角色** — MyGO!!!!! 与 Ave Mujica 两支乐队全员，每位角色都有详细性格、说话风格、称呼规则和禁忌设定
- **3 条故事时间线** — CRYCHIC 解散后 / MyGO 成立后 / 双团并存时期，角色状态随剧情变化
- **流式对话** — 基于 SSE 的实时 token 级流式输出
- **上下文感知系统提示词** — 动态拼接角色设定、世界观、时间线状态和用户记忆
- **轻量记忆系统** — 自动从对话中提取用户信息（名字、喜好、背景等），按角色独立存储
- **对话管理** — 撤回（撤销最后一轮对话）、重新生成（动态调高 temperature）、清除历史
- **本地持久化** — 所有聊天记录、记忆和设置均保存在浏览器 localStorage，无需后端
- **响应式布局** — 桌面端侧边栏 + 主区域双栏布局，移动端全屏聊天
- **动态主题色彩** — 聊天区域背景会根据所选角色的代表色自动变化

## 快速开始

这是一个零构建步骤的纯静态前端项目，无需 npm、无需打包。

```bash
# 用任意静态服务器托管
python -m http.server 8080
# 或: npx serve .
# 或: 直接在浏览器中打开 index.html
```

打开浏览器后，在设置弹窗中配置 API 端点即可开始聊天。API 需兼容 OpenAI Chat Completions 格式（`/v1/chat/completions`）。

首次访问时会自动弹出设置窗口；你也可以随时点击侧边栏的「设置」按钮修改配置。

## 项目结构

```
├── index.html          # 单页应用（HTML + CSS + JS）
├── character.js        # 角色引擎：系统提示词构建、记忆管理、生成参数
├── character.json      # 角色定义（10 位角色的性格/说话风格/禁忌等）
├── timeline.json       # 3 个故事时间线节点及角色状态
├── world.json          # 世界观设定、学校、关键地点、乐队概述
├── example.json        # 动画台词片段示例
├── ave_mujica_subs/    # Ave Mujica 动画字幕文件（简中/繁中 .ass）
└── mygo-api/           # 配套后端 API — MyGO 表情包图库
```

## 角色一览

### MyGO!!!!!
| 角色 | 声库 | 担当 | 学校 |
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

| 节点 | 说明 |
|------|------|
| CRYCHIC 刚解散 | 旧团解散后、新团未成形的空窗期，角色处于最脆弱的状态 |
| MyGO 成立 | MyGO 已组建并化解矛盾，Ave Mujica 尚未出现 |
| 双团并存 | 两队各自活动，Ave Mujica 以假面舞台身份出道 |

## 配套 API（mygo-api）

项目包含一个基于 FastAPI 的图库 API，提供 MyGO/Ave Mujica 相关表情包和剧照的检索服务。

```bash
cd mygo-api
poetry install
poetry run python3 mygo/app.py    # 默认监听 3030 端口
```

主要接口：

| 接口 | 说明 |
|------|------|
| `GET /api/v1/images` | 分页图片列表（支持多种排序） |
| `GET /api/v1/images/search?q=关键词` | 模糊搜索图片 |
| `GET /api/v1/images/random?count=N` | 随机获取图片 |
| `GET /api/v1/images/{id}` | 图片详情 |

详细文档见 [mygo-api/README.md](mygo-api/README.md) 和线上的 [Swagger Docs](https://mygoapi.miyago9267.com/docs)。

## 配置

前端无需环境变量。API 地址、密钥和模型名称通过 UI 设置弹窗配置，保存在浏览器 localStorage 中。

API 需兼容 OpenAI 的 `/v1/chat/completions` 接口格式（支持流式 SSE）。

## 技术栈

- 纯原生 HTML / CSS / JavaScript（无框架、无构建步骤）
- OpenAI 兼容 Chat Completions API + SSE 流式传输
- localStorage 本地持久化
- FastAPI + Python 3.12（后端 API）
- Poetry 依赖管理 / Docker 部署

## License

MIT License
