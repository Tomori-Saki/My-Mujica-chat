package com.bangchat.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

/**
 * 通用应用配置。
 * 提供 RestTemplate Bean，用于调用外部 LLM API。
 */
@Configuration
public class AppConfig {

    /**
     * 创建带超时配置的 RestTemplate，用于调用 OpenAI 兼容 API。
     *
     * @return RestTemplate 实例（连接超时 30s，读取超时 120s 以适应流式响应）
     */
    @Bean
    public RestTemplate restTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(30_000);
        factory.setReadTimeout(120_000);
        return new RestTemplate(factory);
    }
}
