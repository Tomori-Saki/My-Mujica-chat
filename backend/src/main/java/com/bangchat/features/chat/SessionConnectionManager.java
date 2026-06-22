package com.bangchat.features.chat;

import java.io.IOException;
import java.util.Collections;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

/**
 * WebSocket 会话连接管理器。
 * 使用 ConcurrentHashMap 按 sessionId 管理活跃的 WebSocketSession 集合，
 * 支持按 sessionId 广播消息、添加/移除连接。
 */
@Component
public class SessionConnectionManager {

    private static final Logger log = LoggerFactory.getLogger(SessionConnectionManager.class);

    /** sessionId -> 该会话下的所有 WebSocket 连接集合 */
    private final ConcurrentHashMap<String, Set<WebSocketSession>> sessionMap = new ConcurrentHashMap<>();

    /**
     * 将 WebSocket 连接加入指定 sessionId 的集合。
     *
     * @param sessionId 业务会话 ID（从 URL 路径提取）
     * @param wsSession WebSocket 会话对象
     */
    public void addSession(String sessionId, WebSocketSession wsSession) {
        sessionMap.computeIfAbsent(sessionId, k -> ConcurrentHashMap.newKeySet()).add(wsSession);
        log.info("WebSocket 连接加入: sessionId={}, wsSessionId={}, 当前会话连接数={}",
                sessionId, wsSession.getId(), getConnectionCount(sessionId));
    }

    /**
     * 从指定 sessionId 的集合中移除 WebSocket 连接。
     *
     * @param sessionId 业务会话 ID
     * @param wsSession WebSocket 会话对象
     */
    public void removeSession(String sessionId, WebSocketSession wsSession) {
        Set<WebSocketSession> sessions = sessionMap.get(sessionId);
        if (sessions != null) {
            sessions.remove(wsSession);
            if (sessions.isEmpty()) {
                sessionMap.remove(sessionId);
            }
            log.info("WebSocket 连接移除: sessionId={}, wsSessionId={}, 当前会话连接数={}",
                    sessionId, wsSession.getId(), getConnectionCount(sessionId));
        }
    }

    /**
     * 向指定 sessionId 下的所有活跃连接广播消息。
     *
     * @param sessionId 业务会话 ID
     * @param message   要广播的文本消息
     */
    public void broadcastToSession(String sessionId, TextMessage message) {
        Set<WebSocketSession> sessions = sessionMap.getOrDefault(sessionId, Collections.emptySet());
        for (WebSocketSession session : sessions) {
            if (session.isOpen()) {
                try {
                    synchronized (session) {
                        session.sendMessage(message);
                    }
                } catch (IOException e) {
                    log.error("广播消息失败: sessionId={}, wsSessionId={}, error={}",
                            sessionId, session.getId(), e.getMessage());
                }
            }
        }
    }

    /**
     * 向单个 WebSocket 连接发送消息。
     *
     * @param session WebSocket 会话对象
     * @param message 要发送的文本消息
     */
    public void sendToOne(WebSocketSession session, TextMessage message) {
        if (session.isOpen()) {
            try {
                synchronized (session) {
                    session.sendMessage(message);
                }
            } catch (IOException e) {
                log.error("单播消息失败: wsSessionId={}, error={}", session.getId(), e.getMessage());
            }
        }
    }

    /**
     * 获取指定 sessionId 下的活跃连接数。
     *
     * @param sessionId 业务会话 ID
     * @return 活跃连接数，无连接时返回 0
     */
    public int getConnectionCount(String sessionId) {
        Set<WebSocketSession> sessions = sessionMap.get(sessionId);
        return sessions != null ? sessions.size() : 0;
    }
}
