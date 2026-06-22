package com.bangchat.data.entity;

import lombok.Data;

/**
 * 时间线-角色状态关联表 —— 确保不同时间线角色性格/语气物理隔离。
 */
@Data
public class TimelineCharacterState {
    private Long id;
    private String timelineId;
    private String characterId;
    private String stateDescription;
    private String personalityAdjust;
    private String speechAdjust;
}
