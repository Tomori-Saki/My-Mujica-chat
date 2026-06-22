package com.bangchat.data.entity;

import lombok.Data;

/**
 * 时间线实体，映射 timeline 表。
 * 包含时间线标题、概要及各乐队在此时间线中的状态。
 */
@Data
public class Timeline {
    private String id;
    private String title;
    private String summary;
    private String crychicStatus;
    private String mygoStatus;
    private String avemujicaStatus;
}
