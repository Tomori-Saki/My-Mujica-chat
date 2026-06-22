package com.bangchat.module.prompt.dto;

import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Data;

/**
 * 角色在特定时间线下的完整信息聚合 DTO。
 * 由 PromptBuilder 从 DB 提取并填充，纯粹的数据载体，不包含业务逻辑。
 *
 * 包含三大块：
 * - 基础信息（姓名/学校/乐队/角色）
 * - 性格（基础标签 + 时间线偏移）
 * - 说话语气（基础描述 + 时间线偏移）
 */
@Data
public class CharacterCard {

    // ---- 基础信息 ----
    private String id;
    private String nameCn;
    private String nameJp;
    private String nameEn;
    private String bandName;
    private String school;
    private String role;
    private String instrument;
    private String stageName;
    private String summary;

    // ---- 性格 ----
    private List<String> personalityTraits;
    private String personalityAdjust;

    // ---- 说话语气 ----
    private String speechStyle;
    private String speechAdjust;

    // ---- 补充细节 ----
    private List<String> details;
    private List<AddressingInfo> addressings;

    // ---- 时间线状态 ----
    private String stateDescription;

    /**
     * 将此角色卡渲染为 prompt 中的角色描述段落。
     * 输出格式包含：角色名与身份、学校、乐队与角色、概要、
     * 当前状态、性格标签、说话语气、行为特征、称呼方式。
     *
     * @return 格式化的角色描述文本，可直接嵌入 System Prompt
     */
    public String toPromptSection() {
        StringBuilder sb = new StringBuilder();

        sb.append("【").append(nameCn);
        if (stageName != null && !stageName.isEmpty()) {
            sb.append(" / ").append(stageName);
        }
        sb.append("】（").append(nameJp).append(" / ").append(nameEn).append("）\n");

        sb.append("学校：").append(school).append("\n");
        sb.append("乐队：").append(bandName).append("  |  角色：").append(role);
        if (instrument != null && !instrument.isEmpty()) {
            sb.append("（").append(instrument).append("）");
        }
        sb.append("\n");

        if (summary != null && !summary.isEmpty()) {
            sb.append("概要：").append(summary).append("\n");
        }

        if (stateDescription != null && !stateDescription.isEmpty()) {
            sb.append("当前状态：").append(stateDescription).append("\n");
        }

        sb.append("性格：");
        if (personalityTraits != null && !personalityTraits.isEmpty()) {
            sb.append(String.join("、", personalityTraits));
        }
        if (personalityAdjust != null && !personalityAdjust.isEmpty()) {
            sb.append("（").append(personalityAdjust).append("）");
        }
        sb.append("\n");

        sb.append("说话语气：");
        if (speechStyle != null && !speechStyle.isEmpty()) {
            sb.append(speechStyle);
        }
        if (speechAdjust != null && !speechAdjust.isEmpty()) {
            if (speechStyle != null && !speechStyle.isEmpty()) sb.append("；");
            sb.append(speechAdjust);
        }
        sb.append("\n");

        if (details != null && !details.isEmpty()) {
            sb.append("行为特征：\n");
            for (String d : details) {
                sb.append("  - ").append(d).append("\n");
            }
        }

        if (addressings != null && !addressings.isEmpty()) {
            sb.append("称呼方式：\n");
            for (AddressingInfo a : addressings) {
                sb.append("  - 称呼").append(a.getTargetName())
                  .append("为「").append(a.getAlias()).append("」");
                if (a.getNote() != null && !a.getNote().isEmpty()) {
                    sb.append("（").append(a.getNote()).append("）");
                }
                sb.append("\n");
            }
        }

        return sb.toString();
    }

    @Data
    @AllArgsConstructor
    public static class AddressingInfo {
        private String targetName;
        private String alias;
        private String note;
    }
}
