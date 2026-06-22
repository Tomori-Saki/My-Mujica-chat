package com.bangchat;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * BanGchat 后端启动入口。
 * 基于 Spring Boot 3.2.x，自动配置 MyBatis + SQLite + Spring Security。
 */
@SpringBootApplication
public class BangchatApplication {

    /**
     * 应用主入口，启动 Spring Boot 容器。
     *
     * @param args 命令行参数，传递给 SpringApplication
     */
    public static void main(String[] args) {
        SpringApplication.run(BangchatApplication.class, args);
    }
}
