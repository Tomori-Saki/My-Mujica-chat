package com.bangchat.data.entity;

import lombok.Data;

/**
 * 角色性格标签实体，映射 personality_trait 表。
 * 每个角色可有多条性格标签，按 sort_order 排序展示。
 */
@Data
public class PersonalityTrait {
    private Long id;
    private String characterId;
    private String trait;
    private Integer sortOrder;
}
