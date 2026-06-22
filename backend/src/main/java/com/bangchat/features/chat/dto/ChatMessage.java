package com.bangchat.features.chat.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.Data;

/**
 * WebSocket 消息 DTO。
 * 前端与后端之间通过 JSON 序列化/反序列化传递消息，
 * 包含消息类型、发送者、内容、时间戳，以及可选的 LLM 凭证。
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class ChatMessage {

    private static final ObjectMapper objectMapper = new ObjectMapper();

    /** 消息类型：message（用户消息）、event（系统事件）、reply（角色回复）、stream（流式片段） */
    private String type;

    /** 发送者标识（用户昵称或角色名） */
    private String sender;

    /** 消息正文内容 */
    private String content;

    /** 消息时间戳（ISO-8601 格式） */
    private String timestamp;

    // ---- LLM 凭证（前端首次消息携带，后续复用） ----
    private String modelUrl;
    private String apiKey;
    private String modelName;

    // ---- 角色上下文（前端每条消息携带） ----
    private String bandId;
    private String characterId;

    /**
     * 将当前对象序列化为 JSON 字符串。
     *
     * @return JSON 字符串
     * @throws RuntimeException 序列化失败时抛出
     */
    public String toJson() {
        try {
            return objectMapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("ChatMessage 序列化失败", e);
        }
    }

    /**
     * 从 JSON 字符串反序列化为 ChatMessage 对象。
     *
     * @param json JSON 字符串
     * @return ChatMessage 实例
     * @throws RuntimeException 反序列化失败时抛出
     */
    public static ChatMessage fromJson(String json) {
        try {
            return objectMapper.readValue(json, ChatMessage.class);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("ChatMessage 反序列化失败", e);
        }
    }

    /**
     * 快速构造一条消息。
     *
     * @param type    消息类型
     * @param sender  发送者
     * @param content 内容
     * @return 构造好的 ChatMessage
     */
    public static ChatMessage of(String type, String sender, String content) {
        ChatMessage msg = new ChatMessage();
        msg.setType(type);
        msg.setSender(sender);
        msg.setContent(content);
        msg.setTimestamp(java.time.LocalDateTime.now().toString());
        return msg;
    }
}
