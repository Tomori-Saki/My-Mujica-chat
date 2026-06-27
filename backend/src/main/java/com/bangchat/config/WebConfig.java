package com.bangchat.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 显式指定静态资源映射
        registry.addResourceHandler("/**")
                .addResourceLocations("classpath:/static/");
    }
    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        // 强制把根路径 / 直接映射到静态 index.html
        registry.addViewController("/").setViewName("forward:/index.html");

        // 拦截其他单页路由
        registry.addViewController("/{path:[^\\.]*}").setViewName("forward:/index.html");
    }
}
