package com.bangchat.data.entity;

import lombok.Data;

/**
 * 角色行为细节实体，映射 character_detail 表。
 * 描述角色的行为模式和习惯，用于丰富 prompt 中的角色刻画。
 */
@Data
public class CharacterDetail {
    private Long id;
    private String characterId;
    private String detail;
    private Integer sortOrder;
}