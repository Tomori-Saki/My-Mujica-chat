package com.bangchat.data.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.bangchat.data.entity.CharacterDetail;
import com.bangchat.data.entity.CharacterProfile;
import com.bangchat.data.entity.PersonalityTrait;
import com.bangchat.data.entity.SpecialAddressing;
import com.bangchat.data.entity.SpeechStyle;
import com.bangchat.data.entity.Timeline;
import com.bangchat.data.entity.TimelineCharacterState;

/**
 * Prompt 模块专用 Mapper。
 * 只提供 prompt 拼装所需的数据查询，不暴露其他业务操作。
 */
@Mapper
public interface PromptDataMapper {

    /**
     * 查询指定时间线下所有角色的基础信息。
     * 通过 JOIN timeline_character_state 过滤，只返回该时间线中存在状态记录的角色。
     *
     * @param timelineId 时间线 ID（如 t1_crychic_after）
     * @return 该时间线下所有角色的基础信息列表，无结果时返回空列表
     */
    List<CharacterProfile> findCharactersByTimeline(@Param("timelineId") String timelineId);

    /**
     * 查询某角色在某时间线下的状态，包含性格偏移和语气偏移。
     *
     * @param timelineId  时间线 ID
     * @param characterId 角色 ID（如 tomori）
     * @return 时间线角色状态记录，不存在时返回 null
     */
    TimelineCharacterState findTimelineState(@Param("timelineId") String timelineId,
                                              @Param("characterId") String characterId);

    /**
     * 查询某角色的全部性格标签，按 sort_order 升序排列。
     *
     * @param characterId 角色 ID
     * @return 性格标签列表，按排序字段升序
     */
    List<PersonalityTrait> findPersonalityTraits(@Param("characterId") String characterId);

    /**
     * 查询某角色的说话语气描述。每个角色最多一条记录。
     *
     * @param characterId 角色 ID
     * @return 说话语气记录，不存在时返回 null
     */
    SpeechStyle findSpeechStyle(@Param("characterId") String characterId);

    /**
     * 查询某角色的行为细节，按 sort_order 升序排列。
     *
     * @param characterId 角色 ID
     * @return 行为细节列表，按排序字段升序
     */
    List<CharacterDetail> findCharacterDetails(@Param("characterId") String characterId);

    /**
     * 查询某角色对其他角色的专属称呼方式。
     *
     * @param characterId 角色 ID
     * @return 特殊称呼列表，包含目标对象、称呼别名和使用备注
     */
    List<SpecialAddressing> findSpecialAddressings(@Param("characterId") String characterId);

    /**
     * 查询时间线信息，包含各乐队的状态。
     *
     * @param timelineId 时间线 ID
     * @return 时间线实体，不存在时返回 null
     */
    Timeline findTimelineById(@Param("timelineId") String timelineId);
}
