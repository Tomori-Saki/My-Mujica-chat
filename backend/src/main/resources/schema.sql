-- ============================================================
-- BanGchat 数据库 Schema (SQLite)
-- 设计原则：角色性格/speech_style 独立成列，通过
-- timeline_character_state 外键关联 timeline 与 character，
-- 确保不同时间线角色性格不混淆。
-- ============================================================

-- ============================================================
-- 1. 世界设定相关表 (from world.json)
-- ============================================================

CREATE TABLE IF NOT EXISTS school (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS location (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    type TEXT,
    notes TEXT
);

-- ============================================================
-- 2. 乐队表 (from character.json + world.json)
-- ============================================================

CREATE TABLE IF NOT EXISTS band (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    name_cn TEXT,
    status TEXT,          -- active / disbanded / not_formed
    notes TEXT
);

-- ============================================================
-- 3. 角色基础信息表 (from character.json)
-- ============================================================

CREATE TABLE IF NOT EXISTS character_profile (
    id TEXT PRIMARY KEY,          -- 英文ID: tomori, anon, etc.
    name_cn TEXT NOT NULL,
    name_jp TEXT NOT NULL,
    name_en TEXT NOT NULL,
    band_id TEXT NOT NULL REFERENCES band(id),
    school TEXT,
    role TEXT,                    -- 乐队角色: 主唱, 吉他, etc.
    instrument TEXT,
    stage_name TEXT,              -- 舞台名 (Ave Mujica成员)
    summary TEXT                  -- 角色概要
);

-- ============================================================
-- 4. 角色性格表 (独立拆分 —— 核心设计)
--    每个角色可有多个性格标签，按条目独立存储
-- ============================================================

CREATE TABLE IF NOT EXISTS personality_trait (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    character_id TEXT NOT NULL REFERENCES character_profile(id),
    trait TEXT NOT NULL,          -- 单个性格描述
    sort_order INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_pt_char ON personality_trait(character_id);

-- ============================================================
-- 5. 说话语气表 (独立拆分 —— 核心设计)
--    每个角色一条记录，详细描述其说话风格
-- ============================================================

CREATE TABLE IF NOT EXISTS speech_style (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    character_id TEXT NOT NULL UNIQUE REFERENCES character_profile(id),
    description TEXT NOT NULL     -- 语气/说话风格完整描述
);

-- ============================================================
-- 6. 角色行为细节表 (from character.json details[])
-- ============================================================

CREATE TABLE IF NOT EXISTS character_detail (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    character_id TEXT NOT NULL REFERENCES character_profile(id),
    detail TEXT NOT NULL,
    sort_order INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_cd_char ON character_detail(character_id);

-- ============================================================
-- 7. 特殊称呼表 (from character.json special_addressing[])
-- ============================================================

CREATE TABLE IF NOT EXISTS special_addressing (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    character_id TEXT NOT NULL REFERENCES character_profile(id),
    target_name TEXT NOT NULL,    -- 称呼对象中文名
    alias TEXT NOT NULL,          -- 使用的昵称/称呼
    note TEXT                     -- 使用说明
);
CREATE INDEX IF NOT EXISTS idx_sa_char ON special_addressing(character_id);

-- ============================================================
-- 8. 角色标签表 (from character.json tags[])
-- ============================================================

CREATE TABLE IF NOT EXISTS character_tag (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    character_id TEXT NOT NULL REFERENCES character_profile(id),
    tag TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_ct_char ON character_tag(character_id);

-- ============================================================
-- 9. 角色禁忌表 (from character.json taboos[])
-- ============================================================

CREATE TABLE IF NOT EXISTS character_taboo (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    character_id TEXT NOT NULL REFERENCES character_profile(id),
    taboo TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_ctab_char ON character_taboo(character_id);

-- ============================================================
-- 10. 记忆钩子表 (from character.json memory_hooks[])
-- ============================================================

CREATE TABLE IF NOT EXISTS character_memory_hook (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    character_id TEXT NOT NULL REFERENCES character_profile(id),
    hook TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_cmh_char ON character_memory_hook(character_id);

-- ============================================================
-- 11. 时间线表 (from timeline.json)
-- ============================================================

CREATE TABLE IF NOT EXISTS timeline (
    id TEXT PRIMARY KEY,          -- t1_crychic_after, etc.
    title TEXT NOT NULL,
    summary TEXT NOT NULL,
    crychic_status TEXT,          -- disbanded / formed / not_formed
    mygo_status TEXT,
    avemujica_status TEXT
);

-- ============================================================
-- 12. 时间线-角色状态表 (核心关联表 —— 保证不同时间线性格不混淆)
--     FOREIGN KEY (timeline_id) + (character_id)
--     每条记录描述该角色在某特定时间线下的状态、性格偏移、语气偏移
-- ============================================================

CREATE TABLE IF NOT EXISTS timeline_character_state (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timeline_id TEXT NOT NULL REFERENCES timeline(id),
    character_id TEXT NOT NULL REFERENCES character_profile(id),
    state_description TEXT NOT NULL,   -- 该时间线下角色整体状态
    personality_adjust TEXT,           -- 性格在本时间线的偏移/变化
    speech_adjust TEXT,                -- 说话语气在本时间线的变化
    UNIQUE(timeline_id, character_id)
);
CREATE INDEX IF NOT EXISTS idx_tcs_tl ON timeline_character_state(timeline_id);
CREATE INDEX IF NOT EXISTS idx_tcs_char ON timeline_character_state(character_id);

-- ============================================================
-- 13. 台词示例表 (from example.json)
-- ============================================================

CREATE TABLE IF NOT EXISTS dialogue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    character_id TEXT NOT NULL REFERENCES character_profile(id),
    text TEXT NOT NULL,
    source TEXT,                      -- 来源剧集
    context TEXT,                     -- 场景/环境描述
    action TEXT,                      -- 动作描写
    target_id TEXT REFERENCES character_profile(id),
    target_name TEXT
);
CREATE INDEX IF NOT EXISTS idx_d_char ON dialogue(character_id);

-- ============================================================
-- 14. 聊天消息表 (预留，符合 CLAUDE.md 格式要求)
--     所有消息必须包含 timeline_id，查询强制 WHERE timeline_id = ?
-- ============================================================

CREATE TABLE IF NOT EXISTS chat_message (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timeline_id TEXT NOT NULL REFERENCES timeline(id),
    character_id TEXT REFERENCES character_profile(id),
    role TEXT NOT NULL,               -- user / assistant / system
    content TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_cm_timeline ON chat_message(timeline_id);
CREATE INDEX IF NOT EXISTS idx_cm_char ON chat_message(character_id);
CREATE INDEX IF NOT EXISTS idx_cm_created ON chat_message(created_at);
