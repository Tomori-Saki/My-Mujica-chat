package com.bangchat.module.prompt;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Component;

import com.bangchat.data.entity.CharacterDetail;
import com.bangchat.data.entity.CharacterProfile;
import com.bangchat.data.entity.PersonalityTrait;
import com.bangchat.data.entity.SpecialAddressing;
import com.bangchat.data.entity.SpeechStyle;
import com.bangchat.data.entity.Timeline;
import com.bangchat.data.entity.TimelineCharacterState;
import com.bangchat.data.mapper.PromptDataMapper;
import com.bangchat.module.prompt.dto.CharacterCard;

/**
 * Prompt 拼装器 —— 独立模块，不与其他业务层耦合。
 *
 * 职责单一：从数据库提取指定时间线下的所有角色信息
 * （基本信息 + 性格 + 说话语气 + 时间线偏移），拼装为结构化的 system prompt。
 *
 * 依赖：仅依赖 PromptDataMapper（数据访问）和 entity/DTO 类，
 *       不依赖任何 Controller、Service 或其他模块。
 */
@Component
public class PromptBuilder {

    private final PromptDataMapper mapper;

    // band_id -> 乐队中文名
    private static final Map<String, String> BAND_MAP = new HashMap<>();
    static {
        BAND_MAP.put("mygo", "MyGO!!!!!");
        BAND_MAP.put("avemujica", "Ave Mujica");
        BAND_MAP.put("crychic", "CRYCHIC");
    }

    /**
     * 构造 PromptBuilder，注入 Prompt 模块专用的数据访问接口。
     *
     * @param mapper PromptDataMapper，MyBatis 数据访问接口
     */
    public PromptBuilder(PromptDataMapper mapper) {
        this.mapper = mapper;
    }

    /**
     * 为指定时间线构建完整的 system prompt。
     * 从数据库提取该时间线下所有角色的信息并查询时间线乐队状态，
     * 拼装为包含角色关系约束的结构化 AI system message。
     *
     * @param timelineId 时间线 ID（如 t1_crychic_after）
     * @return 结构化的系统提示词，可直接作为 AI 的 system message；
     *         若该时间线无角色数据则返回提示文本
     * @throws org.apache.ibatis.exceptions.PersistenceException 数据库查询异常时抛出
     */
    public String buildSystemPrompt(String timelineId) {
        List<CharacterProfile> profiles = mapper.findCharactersByTimeline(timelineId);

        if (profiles.isEmpty()) {
            return "当前时间线无可用角色数据。";
        }

        Timeline timeline = mapper.findTimelineById(timelineId);

        List<CharacterCard> cards = profiles.stream()
                .map(p -> buildCharacterCard(p, timelineId))
                .collect(Collectors.toList());

        return assemblePrompt(cards, timeline);
    }

    /**
     * 构建单个角色在指定时间线下的完整信息卡片。
     * 从 5 张独立表中提取数据并聚合：
     * personality_trait、speech_style、timeline_character_state、
     * character_detail、special_addressing。
     *
     * @param profile    角色基础信息（来自 character_profile 表）
     * @param timelineId 时间线 ID，用于查询该时间线下的性格/语气偏移
     * @return 包含完整信息的 CharacterCard，不会返回 null
     */
    private CharacterCard buildCharacterCard(CharacterProfile profile, String timelineId) {
        CharacterCard card = new CharacterCard();

        // ---- 基础信息 ----
        card.setId(profile.getId());
        card.setNameCn(profile.getNameCn());
        card.setNameJp(profile.getNameJp());
        card.setNameEn(profile.getNameEn());
        card.setBandName(BAND_MAP.getOrDefault(profile.getBandId(), profile.getBandId()));
        card.setSchool(profile.getSchool());
        card.setRole(profile.getRole());
        card.setInstrument(profile.getInstrument());
        card.setStageName(profile.getStageName());
        card.setSummary(profile.getSummary());

        // ---- 性格标签（独立表） ----
        List<PersonalityTrait> traits = mapper.findPersonalityTraits(profile.getId());
        card.setPersonalityTraits(traits.stream()
                .map(PersonalityTrait::getTrait)
                .collect(Collectors.toList()));

        // ---- 说话语气（独立表） ----
        SpeechStyle style = mapper.findSpeechStyle(profile.getId());
        if (style != null) {
            card.setSpeechStyle(style.getDescription());
        }

        // ---- 时间线偏移（核心：不同时间线性格/语气不同） ----
        TimelineCharacterState state = mapper.findTimelineState(timelineId, profile.getId());
        if (state != null) {
            card.setStateDescription(state.getStateDescription());
            card.setPersonalityAdjust(state.getPersonalityAdjust());
            card.setSpeechAdjust(state.getSpeechAdjust());
        }

        // ---- 行为细节 ----
        List<CharacterDetail> details = mapper.findCharacterDetails(profile.getId());
        card.setDetails(details.stream()
                .map(CharacterDetail::getDetail)
                .collect(Collectors.toList()));

        // ---- 特殊称呼 ----
        List<SpecialAddressing> addressings = mapper.findSpecialAddressings(profile.getId());
        card.setAddressings(addressings.stream()
                .map(a -> new CharacterCard.AddressingInfo(
                        a.getTargetName(), a.getAlias(), a.getNote()))
                .collect(Collectors.toList()));

        return card;
    }

    /**
     * 将所有角色卡片按乐队分组，拼装为最终的 System Prompt 文本。
     * 根据时间线的乐队状态注入关系约束，确保不同时间线下角色认知不跨越。
     *
     * @param cards    该时间线下所有角色的完整信息卡片
     * @param timeline 时间线实体（含乐队状态）
     * @return 完整的 System Prompt 文本，包含角色设定、关系约束和交互规则
     */
    private String assemblePrompt(List<CharacterCard> cards, Timeline timeline) {
        StringBuilder sb = new StringBuilder();

        sb.append("你是 BanG Dream! 世界中的角色扮演 AI。\n");
        sb.append("你将扮演以下角色之一，根据用户的消息进行回复。\n\n");

        // ===== 时间线关系约束（核心：防止跨时间线认知混淆） =====
        sb.append("=== 时间线关系约束 ===\n");
        sb.append("时间线：").append(timeline != null ? timeline.getTitle() : "未知").append("\n");

        String crychicStatus = timeline != null ? timeline.getCrychicStatus() : "";
        String mygoStatus = timeline != null ? timeline.getMygoStatus() : "";
        String aveStatus = timeline != null ? timeline.getAvemujicaStatus() : "";

        sb.append("当前各乐队状态：\n");
        sb.append("- CRYCHIC: ").append(statusLabel(crychicStatus)).append("\n");
        sb.append("- MyGO!!!!!: ").append(statusLabel(mygoStatus)).append("\n");
        sb.append("- Ave Mujica: ").append(statusLabel(aveStatus)).append("\n\n");

        sb.append("角色关系规则（严格遵循）：\n");

        if ("not_formed".equals(mygoStatus) && "not_formed".equals(aveStatus)) {
            // t1: 只有 CRYCHIC 成员互相认识
            sb.append("- CRYCHIC 已解散，但其前成员（高松灯、长崎素世、椎名立希、丰川祥子、若叶睦）在 CRYCHIC 时期就已互相认识。\n");
            sb.append("- MyGO!!!!! 尚未成立。千早爱音（Anon）和要乐奈（Rana）此时尚未与 CRYCHIC 成员结识。\n");
            sb.append("  → 高松灯不认识千早爱音。长崎素世不认识千早爱音。椎名立希不认识千早爱音。\n");
            sb.append("  → 如用户提及爱音或乐奈，你所扮演的角色应表示「不认识」或「没听说过」。\n");
            sb.append("- Ave Mujica 尚未成立。三角初华、八幡海铃、祐天寺喵梦尚未以 Ave Mujica 身份活动。\n\n");
        } else if ("formed".equals(mygoStatus) && "not_formed".equals(aveStatus)) {
            // t2: MyGO 成员互相认识，Ave Mujica 未成立
            sb.append("- MyGO!!!!! 已成立。成员（高松灯、千早爱音、要乐奈、长崎素世、椎名立希）互相认识并信任彼此。\n");
            sb.append("- Ave Mujica 尚未成立。丰川祥子尚未公开组队计划，三角初华等人仍以原有身份活动。\n");
            sb.append("  → 你所扮演的角色尚未知道 Ave Mujica 的存在，不可提及该乐队名或成员的舞台名。\n\n");
        } else {
            // t3: 两个乐队都已成立
            sb.append("- MyGO!!!!! 和 Ave Mujica 均已成立，所有角色均可能互相认识或听说过对方。\n");
            sb.append("- CRYCHIC 已是过去，不可混淆不同乐队成员当前的归属关系。\n\n");
        }

        // ===== 角色设定 =====
        sb.append("=== 当前时间线角色设定 ===\n\n");

        List<CharacterCard> mygoCards = cards.stream()
                .filter(c -> "MyGO!!!!!".equals(c.getBandName()))
                .collect(Collectors.toList());
        List<CharacterCard> aveCards = cards.stream()
                .filter(c -> "Ave Mujica".equals(c.getBandName()))
                .collect(Collectors.toList());

        if (!mygoCards.isEmpty()) {
            sb.append("--- MyGO!!!!! ---\n\n");
            for (CharacterCard card : mygoCards) {
                sb.append(card.toPromptSection()).append("\n");
            }
        }

        if (!aveCards.isEmpty()) {
            sb.append("--- Ave Mujica ---\n\n");
            for (CharacterCard card : aveCards) {
                sb.append(card.toPromptSection()).append("\n");
            }
        }

        sb.append("=== 交互规则 ===\n");
        sb.append("- 严格根据以上角色设定和关系约束进行回复，禁止混淆不同时间线的性格、语气和人物关系。\n");
        sb.append("- 使用口语化的中文回复，保持角色的说话风格。\n");
        sb.append("- 称呼其他角色时使用上述'称呼方式'中规定的称呼。\n");
        sb.append("- 如果用户提到你在此时间线中不应认识的角色，请自然地表示不认识或困惑。\n");

        return sb.toString();
    }

    /**
     * 将数据库状态码转为中文标签。
     *
     * @param status 状态码（formed / disbanded / not_formed）
     * @return 中文标签
     */
    private String statusLabel(String status) {
        return switch (status) {
            case "formed" -> "已成立";
            case "disbanded" -> "已解散";
            case "not_formed" -> "未成立";
            default -> "未知";
        };
    }
}
