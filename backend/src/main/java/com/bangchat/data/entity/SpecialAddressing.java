package com.bangchat.data.entity;

import lombok.Data;

/**
 * 角色特殊称呼实体，映射 special_addressing 表。
 * 记录角色对其他角色的专属昵称、叫法和使用备注。
 */
@Data
public class SpecialAddressing {
    private Long id;
    private String characterId;
    private String targetName;
    private String alias;
    private String note;
}
