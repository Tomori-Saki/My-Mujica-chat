package com.bangchat.data.entity;

import lombok.Data;

/**
 * 角色基础信息实体，映射 character_profile 表。
 * 包含角色的姓名、学校、乐队、角色定位、乐器及概要描述。
 */
@Data
public class CharacterProfile {
    private String id;
    private String nameCn;
    private String nameJp;
    private String nameEn;
    private String bandId;
    private String school;
    private String role;
    private String instrument;
    private String stageName;
    private String summary;
}
