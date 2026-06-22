package com.bangchat.init;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.List;
import java.util.Map;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * 数据库初始化器 —— 在 Spring Boot 启动后，读取项目根目录的 4 个 JSON 文件
 * 写入 SQLite 数据库。仅在数据库为空时执行，已填充则跳过。
 *
 * 完全基于 Java/Jackson/JDBC，不需要 Python 或任何外部运行时。
 */
@Component
public class DatabaseInitializer implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DatabaseInitializer.class);

    private final DataSource dataSource;
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * 构造初始化器，注入 SQLite 数据源。
     *
     * @param dataSource Spring Boot 自动配置的 SQLite DataSource
     */
    public DatabaseInitializer(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    /**
     * 应用启动后自动执行。检查 character_profile 表是否已有数据：
     * 若已初始化则跳过，否则依次导入 world.json → character.json →
     * timeline.json → example.json。
     *
     * @param args 命令行参数（未使用）
     * @throws Exception JSON 解析或数据库写入失败时抛出
     */
    @Override
    public void run(String... args) throws Exception {
        // 检查是否已包含数据
        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {

            ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM character_profile");
            if (rs.next() && rs.getInt(1) > 0) {
                log.info("数据库已初始化，跳过数据导入。");
                return;
            }
        }

        log.info("开始从 classpath:data/ 导入 JSON 数据到数据库...");

        importWorld("data/world.json");
        importCharacters("data/character.json");
        importTimelines("data/timeline.json");
        importDialogues("data/example.json");

        log.info("数据库初始化完成。");
    }

    /**
     * 导入 world.json：写入 school、location、band 三张表。
     *
     * @param classPath classpath 下 JSON 文件路径（如 data/world.json）
     * @throws Exception JSON 解析或数据库写入失败时抛出
     */
    private void importWorld(String classPath) throws Exception {
        InputStream in = new ClassPathResource(classPath).getInputStream();
        Map<?, ?> data = objectMapper.readValue(in, Map.class);
        in.close();
        try (Connection conn = dataSource.getConnection()) {
            // schools
            List<Map<String, String>> schools = (List<Map<String, String>>) data.get("schools");
            if (schools != null) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO school (name, notes) VALUES (?, ?)")) {
                    for (Map<String, String> s : schools) {
                        ps.setString(1, s.get("name"));
                        ps.setString(2, s.getOrDefault("notes", ""));
                        ps.executeUpdate();
                    }
                }
            }
            // locations
            List<Map<String, String>> locs = (List<Map<String, String>>) data.get("key_locations");
            if (locs != null) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO location (name, type, notes) VALUES (?, ?, ?)")) {
                    for (Map<String, String> l : locs) {
                        ps.setString(1, l.get("name"));
                        ps.setString(2, l.getOrDefault("type", ""));
                        ps.setString(3, l.getOrDefault("notes", ""));
                        ps.executeUpdate();
                    }
                }
            }
            // bands from world.json
            List<Map<String, String>> bands = (List<Map<String, String>>) data.get("bands");
            if (bands != null) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT OR IGNORE INTO band (id, name, name_cn, status, notes) VALUES (?, ?, ?, ?, ?)")) {
                    for (Map<String, String> b : bands) {
                        ps.setString(1, b.get("id"));
                        ps.setString(2, b.get("name"));
                        ps.setString(3, b.get("name"));
                        ps.setString(4, b.getOrDefault("status", ""));
                        ps.setString(5, b.getOrDefault("notes", ""));
                        ps.executeUpdate();
                    }
                }
            }
        }
    }

    /**
     * 导入 character.json：写入 band、character_profile、personality_trait、
     * speech_style、character_detail、special_addressing、character_tag、
     * character_taboo、character_memory_hook 共 9 张表。
     *
     * @param classPath classpath 下 JSON 文件路径（如 data/character.json）
     * @throws Exception JSON 解析或数据库写入失败时抛出
     */
    private void importCharacters(String classPath) throws Exception {
        InputStream in = new ClassPathResource(classPath).getInputStream();
        Map<?, ?> data = objectMapper.readValue(in, Map.class);
        in.close();

        try (Connection conn = dataSource.getConnection()) {
            // bands
            List<Map<String, String>> bands = (List<Map<String, String>>) data.get("bands");
            if (bands != null) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT OR IGNORE INTO band (id, name, name_cn) VALUES (?, ?, ?)")) {
                    for (Map<String, String> b : bands) {
                        ps.setString(1, b.get("id"));
                        ps.setString(2, b.get("name"));
                        ps.setString(3, b.get("name"));
                        ps.executeUpdate();
                    }
                }
            }
            // CRYCHIC
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT OR IGNORE INTO band (id, name, name_cn, status) VALUES (?, ?, ?, ?)")) {
                ps.setString(1, "crychic");
                ps.setString(2, "CRYCHIC");
                ps.setString(3, "CRYCHIC");
                ps.setString(4, "disbanded");
                ps.executeUpdate();
            }

            List<Map<String, Object>> chars = (List<Map<String, Object>>) data.get("characters");
            if (chars == null) return;

            Map<String, String> bandMap = Map.of(
                    "MyGO!!!!!", "mygo",
                    "Ave Mujica", "avemujica",
                    "CRYCHIC", "crychic");

            for (Map<String, Object> ch : chars) {
                String id = (String) ch.get("id");
                String bandId = bandMap.getOrDefault(ch.get("band"), "");

                // character_profile
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO character_profile (id, name_cn, name_jp, name_en, band_id, school, role, instrument, stage_name, summary) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")) {
                    ps.setString(1, id);
                    ps.setString(2, (String) ch.get("name_cn"));
                    ps.setString(3, (String) ch.get("name_jp"));
                    ps.setString(4, (String) ch.get("name_en"));
                    ps.setString(5, bandId);
                    ps.setString(6, (String) ch.getOrDefault("school", ""));
                    ps.setString(7, (String) ch.getOrDefault("role", ""));
                    ps.setString(8, (String) ch.getOrDefault("instrument", ""));
                    ps.setString(9, (String) ch.get("stage_name"));
                    ps.setString(10, (String) ch.getOrDefault("summary", ""));
                    ps.executeUpdate();
                }

                // personality traits
                List<String> traits = (List<String>) ch.get("personality");
                if (traits != null) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO personality_trait (character_id, trait, sort_order) VALUES (?, ?, ?)")) {
                        int order = 0;
                        for (String trait : traits) {
                            ps.setString(1, id);
                            ps.setString(2, trait);
                            ps.setInt(3, order++);
                            ps.executeUpdate();
                        }
                    }
                }

                // speech style
                String speechStyle = (String) ch.get("speech_style");
                if (speechStyle != null && !speechStyle.isEmpty()) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO speech_style (character_id, description) VALUES (?, ?)")) {
                        ps.setString(1, id);
                        ps.setString(2, speechStyle);
                        ps.executeUpdate();
                    }
                }

                // details
                List<String> details = (List<String>) ch.get("details");
                if (details != null) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO character_detail (character_id, detail, sort_order) VALUES (?, ?, ?)")) {
                        int order = 0;
                        for (String d : details) {
                            ps.setString(1, id);
                            ps.setString(2, d);
                            ps.setInt(3, order++);
                            ps.executeUpdate();
                        }
                    }
                }

                // special addressing
                List<Map<String, String>> addrs = (List<Map<String, String>>) ch.get("special_addressing");
                if (addrs != null) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO special_addressing (character_id, target_name, alias, note) VALUES (?, ?, ?, ?)")) {
                        for (Map<String, String> a : addrs) {
                            ps.setString(1, id);
                            ps.setString(2, a.get("target"));
                            ps.setString(3, a.get("alias"));
                            ps.setString(4, a.getOrDefault("note", ""));
                            ps.executeUpdate();
                        }
                    }
                }

                // tags
                List<String> tags = (List<String>) ch.get("tags");
                if (tags != null) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO character_tag (character_id, tag) VALUES (?, ?)")) {
                        for (String tag : tags) {
                            ps.setString(1, id);
                            ps.setString(2, tag);
                            ps.executeUpdate();
                        }
                    }
                }

                // taboos
                List<String> taboos = (List<String>) ch.get("taboos");
                if (taboos != null) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO character_taboo (character_id, taboo) VALUES (?, ?)")) {
                        for (String taboo : taboos) {
                            ps.setString(1, id);
                            ps.setString(2, taboo);
                            ps.executeUpdate();
                        }
                    }
                }

                // memory hooks
                List<String> hooks = (List<String>) ch.get("memory_hooks");
                if (hooks != null) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO character_memory_hook (character_id, hook) VALUES (?, ?)")) {
                        for (String hook : hooks) {
                            ps.setString(1, id);
                            ps.setString(2, hook);
                            ps.executeUpdate();
                        }
                    }
                }
            }
        }
    }

    /**
     * 导入 timeline.json：写入 timeline 和 timeline_character_state 两张表。
     * 每条时间线节点包含 10 个角色的独立状态记录，确保不同时间线角色数据物理隔离。
     *
     * @param classPath classpath 下 JSON 文件路径（如 data/timeline.json）
     * @throws Exception JSON 解析或数据库写入失败时抛出
     */
    private void importTimelines(String classPath) throws Exception {
        InputStream in = new ClassPathResource(classPath).getInputStream();
        Map<?, ?> data = objectMapper.readValue(in, Map.class);
        in.close();
        List<Map<String, Object>> nodes = (List<Map<String, Object>>) data.get("nodes");
        if (nodes == null) return;

        try (Connection conn = dataSource.getConnection()) {
            try (PreparedStatement psTimeline = conn.prepareStatement(
                    "INSERT INTO timeline (id, title, summary, crychic_status, mygo_status, avemujica_status) VALUES (?, ?, ?, ?, ?, ?)");
                 PreparedStatement psState = conn.prepareStatement(
                         "INSERT INTO timeline_character_state (timeline_id, character_id, state_description) VALUES (?, ?, ?)")) {

                for (Map<String, Object> node : nodes) {
                    String tlId = (String) node.get("id");
                    Map<String, String> bs = (Map<String, String>) node.get("band_status");

                    psTimeline.setString(1, tlId);
                    psTimeline.setString(2, (String) node.get("title"));
                    psTimeline.setString(3, (String) node.get("summary"));
                    psTimeline.setString(4, bs != null ? bs.getOrDefault("crychic", "") : "");
                    psTimeline.setString(5, bs != null ? bs.getOrDefault("mygo", "") : "");
                    psTimeline.setString(6, bs != null ? bs.getOrDefault("avemujica", "") : "");
                    psTimeline.executeUpdate();

                    Map<String, String> states = (Map<String, String>) node.get("character_states");
                    if (states != null) {
                        for (Map.Entry<String, String> e : states.entrySet()) {
                            psState.setString(1, tlId);
                            psState.setString(2, e.getKey());
                            psState.setString(3, e.getValue());
                            psState.executeUpdate();
                        }
                    }
                }
            }
        }
    }

    /**
     * 导入 example.json：写入 dialogue 表。
     * 每条台词包含来源剧集、场景描述、动作描写和目标角色引用。
     *
     * @param classPath classpath 下 JSON 文件路径（如 data/example.json）
     * @throws Exception JSON 解析或数据库写入失败时抛出
     */
    private void importDialogues(String classPath) throws Exception {
        InputStream in = new ClassPathResource(classPath).getInputStream();
        Map<?, ?> data = objectMapper.readValue(in, Map.class);
        in.close();
        Map<String, List<Map<String, Object>>> dialogues =
                (Map<String, List<Map<String, Object>>>) data.get("dialogues");
        if (dialogues == null) return;

        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "INSERT INTO dialogue (character_id, text, source, context, action, target_id, target_name) VALUES (?, ?, ?, ?, ?, ?, ?)")) {

            for (Map.Entry<String, List<Map<String, Object>>> e : dialogues.entrySet()) {
                String charId = e.getKey();
                for (Map<String, Object> d : e.getValue()) {
                    ps.setString(1, charId);
                    ps.setString(2, (String) d.get("text"));
                    ps.setString(3, (String) d.getOrDefault("source", ""));
                    ps.setString(4, (String) d.getOrDefault("context", ""));
                    ps.setString(5, (String) d.getOrDefault("action", ""));
                    ps.setString(6, (String) d.get("target"));
                    ps.setString(7, (String) d.get("target_name"));
                    ps.executeUpdate();
                }
            }
        }
    }
}
