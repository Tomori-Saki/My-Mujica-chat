package com.bangchat.data.entity;

import lombok.Data;

/**
 * 角色说话语气实体，映射 speech_style 表。
 * 每个角色最多一条记录，描述其基础说话风格和语气特征。
 */
@Data
public class SpeechStyle {
    private Long id;
    private String characterId;
    private String description;
}
