package com.bangchat.config;

import java.util.Map;

import org.springframework.context.annotation.Configuration;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.server.HandshakeInterceptor;

import com.bangchat.features.chat.ChatWebSocketHandler;

/**
 * WebSocket 配置。
 * 注册 ChatWebSocketHandler 并拦截 /ws/chat/{sessionId} 路由，
 * 通过 HandshakeInterceptor 提取 URI 中的 sessionId 存入 WebSocket session attributes。
 */
@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    private final ChatWebSocketHandler chatWebSocketHandler;

    public WebSocketConfig(ChatWebSocketHandler chatWebSocketHandler) {
        this.chatWebSocketHandler = chatWebSocketHandler;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(chatWebSocketHandler, "/ws/chat/{sessionId}")
                .setAllowedOrigins("*")
                .addInterceptors(new SessionIdInterceptor());
    }

    /**
     * 握手拦截器：从请求 URI 中提取 {sessionId} 路径变量，
     * 存入 WebSocketSession attributes，供 ChatWebSocketHandler 使用。
     */
    private static class SessionIdInterceptor implements HandshakeInterceptor {

        @Override
        public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                        WebSocketHandler wsHandler, Map<String, Object> attributes) {
            String path = request.getURI().getPath();
            String sessionId = extractSessionId(path);
            attributes.put("sessionId", sessionId);
            return true;
        }

        @Override
        public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                    WebSocketHandler wsHandler, Exception exception) {
            // no-op
        }

        /**
         * 从 URL 路径 "/ws/chat/{sessionId}" 中提取 sessionId。
         *
         * @param path 请求路径
         * @return sessionId 字符串，解析失败时返回 "unknown"
         */
        private String extractSessionId(String path) {
            if (path == null) return "unknown";
            int idx = path.lastIndexOf("/ws/chat/");
            if (idx >= 0) {
                return path.substring(idx + "/ws/chat/".length());
            }
            return "unknown";
        }
    }
}
