package com.bangchat.features.chat;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import com.bangchat.features.chat.dto.ChatMessage;
import com.bangchat.module.prompt.PromptBuilder;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * 聊天 WebSocket 处理器。
 * 负责 WebSocket 连接的生命周期管理（建立、消息、关闭、异常）。
 *
 * 消息处理流程：
 * 1. 前端发来消息（含 content + bandId/characterId + 凭证）
 * 2. 后端缓存凭证与角色上下文
 * 3. 通过 PromptBuilder 从数据库拼装角色 System Prompt
 * 4. 调用上游 LLM API（OpenAI 兼容 /v1/chat/completions），流式推送回复
 */
@Component
public class ChatWebSocketHandler extends TextWebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(ChatWebSocketHandler.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();

    private final SessionConnectionManager connectionManager;
    private final PromptBuilder promptBuilder;

    /** sessionId → 凭证 + 角色上下文缓存 */
    private final Map<String, SessionContext> sessionContexts = new ConcurrentHashMap<>();

    /** bandId → timelineId 映射 */
    private static final Map<String, String> BAND_TO_TIMELINE = Map.of(
            "crychic", "t1_crychic_after",
            "mygo", "t2_mygo_formed",
            "avemujica", "t3_both_formed"
    );

    /** characterId → 中文名 */
    private static final Map<String, String> CHAR_NAMES = new HashMap<>();
    static {
        CHAR_NAMES.put("tomori", "高松灯"); CHAR_NAMES.put("anon", "千早爱音");
        CHAR_NAMES.put("rana", "要乐奈");   CHAR_NAMES.put("soyo", "长崎素世");
        CHAR_NAMES.put("taki", "椎名立希"); CHAR_NAMES.put("sakiko", "丰川祥子");
        CHAR_NAMES.put("mutsumi", "若叶睦"); CHAR_NAMES.put("umiri", "八幡海铃");
        CHAR_NAMES.put("uika", "三角初华"); CHAR_NAMES.put("nyamu", "祐天寺喵梦");
    }

    public ChatWebSocketHandler(SessionConnectionManager connectionManager,
                                PromptBuilder promptBuilder) {
        this.connectionManager = connectionManager;
        this.promptBuilder = promptBuilder;
    }

    /**
     * 连接建立后触发。仅注册连接到管理器，不发送系统消息。
     *
     * @param session 新建的 WebSocket 会话
     */
    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        String sessionId = getSessionId(session);
        connectionManager.addSession(sessionId, session);
        log.info("WebSocket 连接建立: sessionId={}", sessionId);
    }

    /**
     * 连接关闭后触发。清理连接与对应上下文。
     *
     * @param session 关闭的 WebSocket 会话
     * @param status  关闭状态码与原因
     */
    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        String sessionId = getSessionId(session);
        connectionManager.removeSession(sessionId, session);
        if (connectionManager.getConnectionCount(sessionId) == 0) {
            sessionContexts.remove(sessionId);
        }
    }

    /**
     * 接收前端发来的文本消息。
     *
     * 1. 解析 JSON（content + bandId/characterId + 可选凭证）
     * 2. 缓存凭证和角色上下文（首次携带后复用）
     * 3. 通过 PromptBuilder 从数据库构建角色 System Prompt
     * 4. 异步调用 LLM API，流式推送回复
     *
     * @param session 发送消息的 WebSocket 会话
     * @param message 前端发来的 TextMessage（JSON 格式）
     */
    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        String sessionId = getSessionId(session);
        String payload = message.getPayload();
        log.debug("收到消息: sessionId={}", sessionId);

        ChatMessage incoming;
        try {
            incoming = ChatMessage.fromJson(payload);
        } catch (RuntimeException e) {
            log.warn("消息解析失败: {}", e.getMessage());
            sendToOne(session, ChatMessage.of("event", "system", "消息格式错误"));
            return;
        }

        String userContent = incoming.getContent();
        if (userContent == null || userContent.isBlank()) return;

        // 获取或创建 SessionContext
        SessionContext ctx = sessionContexts.computeIfAbsent(sessionId, k -> new SessionContext());

        // 缓存凭证
        if (incoming.getModelUrl() != null && !incoming.getModelUrl().isBlank()
                && incoming.getApiKey() != null && !incoming.getApiKey().isBlank()) {
            ctx.modelUrl = incoming.getModelUrl();
            ctx.apiKey = incoming.getApiKey();
            ctx.modelName = incoming.getModelName();
        }

        // 缓存角色上下文
        if (incoming.getBandId() != null && !incoming.getBandId().isBlank()) {
            ctx.bandId = incoming.getBandId();
        }
        if (incoming.getCharacterId() != null && !incoming.getCharacterId().isBlank()) {
            ctx.characterId = incoming.getCharacterId();
        }

        if (ctx.modelUrl == null || ctx.apiKey == null) {
            sendToOne(session, ChatMessage.of("event", "system", "未配置 API 凭证"));
            return;
        }
        if (ctx.characterId == null) {
            sendToOne(session, ChatMessage.of("event", "system", "未选择角色"));
            return;
        }

        // 构建 System Prompt（从数据库提取该时间线下所有角色设定）
        String timelineId = BAND_TO_TIMELINE.getOrDefault(ctx.bandId, "t2_mygo_formed");
        String systemPrompt;
        try {
            systemPrompt = promptBuilder.buildSystemPrompt(timelineId);
        } catch (Exception e) {
            log.error("构建 System Prompt 失败: {}", e.getMessage());
            sendToOne(session, ChatMessage.of("event", "system",
                    "数据库查询失败，请确认已启动并初始化数据"));
            return;
        }

        // 追加当前角色指定指令
        String charName = CHAR_NAMES.getOrDefault(ctx.characterId, ctx.characterId);
        systemPrompt += "\n\n【当前角色】你正在扮演「" + charName + "」。"
                + "请严格以上述设定中该角色的性格、说话语气、行为方式、称呼规则进行回复。"
                + "使用口语化中文，保持角色口吻，不跳出角色。"
                + "称呼其他角色时使用上述'称呼方式'中规定的称呼。";

        final String finalPrompt = systemPrompt;
        final String finalCharName = charName;

        // 异步调用 AI —— 不阻塞 WebSocket 读线程
        Thread aiThread = new Thread(() ->
                callAiAndStream(sessionId, ctx, finalPrompt, finalCharName, userContent),
                "ai-call-" + sessionId);
        aiThread.setDaemon(true);
        aiThread.start();
    }

    /**
     * 传输异常处理。
     */
    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        log.error("WebSocket 传输异常: sessionId={}, error={}",
                getSessionId(session), exception.getMessage());
        connectionManager.removeSession(getSessionId(session), session);
    }

    // ==================== 私有方法 ====================

    private String getSessionId(WebSocketSession session) {
        Object attr = session.getAttributes().get("sessionId");
        return attr != null ? attr.toString() : "unknown";
    }

    /**
     * 调用上游 LLM API（OpenAI 兼容格式），流式推送回复。
     *
     * @param sessionId    业务会话 ID
     * @param ctx          凭证上下文
     * @param systemPrompt 从数据库构建的角色 System Prompt
     * @param charName     当前角色中文名
     * @param userContent  用户消息内容
     */
    @SuppressWarnings("unchecked")
    private void callAiAndStream(String sessionId, SessionContext ctx,
                                  String systemPrompt, String charName, String userContent) {
        try {
            String apiUrl = ctx.modelUrl.replaceAll("/+$", "") + "/v1/chat/completions";

            Map<String, Object> requestBody = Map.of(
                    "model", ctx.modelName != null && !ctx.modelName.isBlank()
                            ? ctx.modelName : "gpt-4o-mini",
                    "messages", List.of(
                            Map.of("role", "system", "content", systemPrompt),
                            Map.of("role", "user", "content", userContent)
                    ),
                    "stream", true
            );

            byte[] bodyBytes = objectMapper.writeValueAsBytes(requestBody);

            HttpURLConnection conn = (HttpURLConnection) new URI(apiUrl).toURL().openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("Authorization", "Bearer " + ctx.apiKey);
            conn.setDoOutput(true);
            conn.setConnectTimeout(30_000);
            conn.setReadTimeout(120_000);
            conn.getOutputStream().write(bodyBytes);

            int status = conn.getResponseCode();
            if (status != 200) {
                String errBody = new String(conn.getErrorStream().readAllBytes(), StandardCharsets.UTF_8);
                broadcast(sessionId, ChatMessage.of("event", "system",
                        "AI API 返回 " + status + ": " + errBody));
                return;
            }

            // 流式读取 SSE
            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8));
            String line;
            StringBuilder fullContent = new StringBuilder();

            // 发送 stream-start
            broadcast(sessionId, ChatMessage.of("stream", charName, ""));

            while ((line = reader.readLine()) != null) {
                if (!line.startsWith("data: ")) continue;
                String data = line.substring(6).trim();
                if (data.isEmpty() || "[DONE]".equals(data)) continue;

                try {
                    Map<String, Object> chunk = objectMapper.readValue(data, Map.class);
                    List<Map<String, Object>> choices = (List<Map<String, Object>>) chunk.get("choices");
                    if (choices == null || choices.isEmpty()) continue;
                    Map<String, Object> delta = (Map<String, Object>) choices.get(0).get("delta");
                    if (delta == null) continue;
                    Object tokenObj = delta.get("content");
                    if (tokenObj == null) continue;
                    String token = tokenObj.toString();
                    fullContent.append(token);

                    broadcast(sessionId, ChatMessage.of("stream", charName, token));
                } catch (Exception ignored) { /* skip */ }
            }
            reader.close();
            conn.disconnect();

            String finalContent = fullContent.toString();
            if (!finalContent.isBlank()) {
                broadcast(sessionId, ChatMessage.of("reply", charName, finalContent));
            }

        } catch (Exception e) {
            log.error("AI 调用失败: {}", e.getMessage());
            broadcast(sessionId, ChatMessage.of("event", "system",
                    "AI 调用失败: " + e.getMessage()));
        }
    }

    private void broadcast(String sessionId, ChatMessage msg) {
        connectionManager.broadcastToSession(sessionId, new TextMessage(msg.toJson()));
    }

    private void sendToOne(WebSocketSession session, ChatMessage msg) {
        connectionManager.sendToOne(session, new TextMessage(msg.toJson()));
    }

    // ==================== 内部类 ====================

    /** 每个 WebSocket 会话的上下文（凭证 + 角色信息） */
    private static class SessionContext {
        String modelUrl;
        String apiKey;
        String modelName;
        String bandId;
        String characterId;
    }
}
