package com.bangchat.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.PlatformTransactionManager;

import javax.sql.DataSource;

/**
 * 数据源配置。
 * 提供 JDBC 事务管理器，支持 CommandLineRunner 和 MyBatis 的事务管理。
 */
@Configuration
public class DataSourceConfig {

    /**
     * 创建 JDBC 事务管理器，为 SQLite 提供事务支持。
     *
     * @param dataSource Spring Boot 自动配置的 SQLite DataSource
     * @return PlatformTransactionManager JDBC 事务管理器实例
     */
    @Bean
    public PlatformTransactionManager transactionManager(DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }
}
