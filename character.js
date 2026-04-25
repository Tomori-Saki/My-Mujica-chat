/* global window */
(function attachBangCharacterEngine(globalObj) {
  // 记忆池最大条数，避免提示词无限增长导致成本和稳定性问题。
  const MEMORY_MAX = 16;

  function toArray(value) {
    return Array.isArray(value) ? value : [];
  }

  function compact(lines) {
    return lines.filter(Boolean).map((line) => String(line).trim()).filter(Boolean);
  }

  function uniqueStable(list) {
    // 去重且保持原有顺序，保证提示词可读性和稳定性。
    const out = [];
    const seen = new Set();
    list.forEach((item) => {
      const key = item.toLowerCase();
      if (seen.has(key)) return;
      seen.add(key);
      out.push(item);
    });
    return out;
  }

  function normalizeCharacterProfile(rawCharacter) {
    // 将 character.json 的扩展字段标准化，避免缺字段时报错。
    const character = rawCharacter || {};
    const specialAddressing = toArray(character.special_addressing).map((item) => ({
      target: String(item.target || '').trim(),
      alias: String(item.alias || '').trim(),
      note: String(item.note || '').trim()
    })).filter((item) => item.target && item.alias);

    return {
      summary: String(character.summary || ''),
      personality: compact(toArray(character.personality)),
      tags: compact(toArray(character.tags)),
      details: compact(toArray(character.details)),
      speechStyle: String(character.speech_style || '').trim(),
      taboos: compact(toArray(character.taboos)),
      memoryHooks: compact(toArray(character.memory_hooks)),
      specialAddressing
    };
  }

  function buildCharacterPromptParts(input) {
    // 组装系统提示词：世界观 + 时间线状态 + 人设细节 + 记忆。
    const character = input.character || {};
    const timeline = input.timeline || {};
    const world = input.world || {};
    const timelineNote = String(input.timelineNote || '').trim();
    const memory = uniqueStable(compact(toArray(input.memory)));
    const regenAttempt = Number(input.regenAttempt || 0);
    const profile = normalizeCharacterProfile(character);

    const lines = [
      `你正在扮演《BanG Dream! It's MyGO!!!!! / Ave Mujica》中的角色「${character.name_cn || ''}」。`,
      `时间节点：${timeline.title || ''}`,
      `世界观：${world.setting || ''}`,
      `角色设定：${profile.summary}`,
      `当前状态：${timelineNote}`
    ];

    if (profile.personality.length) {
      lines.push(`性格关键词：${profile.personality.join('、')}`);
    }
    if (profile.tags.length) {
      lines.push(`角色标签：${profile.tags.join('、')}`);
    }
    if (profile.speechStyle) {
      lines.push(`说话风格：${profile.speechStyle}`);
    }
    if (profile.details.length) {
      lines.push(`行为细节：${profile.details.join('；')}`);
    }
    if (profile.specialAddressing.length) {
      const naming = profile.specialAddressing
        .map((item) => `${item.target} -> ${item.alias}${item.note ? `（${item.note}）` : ''}`)
        .join('；');
      lines.push(`特定称呼：${naming}`);
    }
    if (profile.taboos.length) {
      lines.push(`避免点：${profile.taboos.join('；')}`);
    }
    if (profile.memoryHooks.length) {
      lines.push(`长期记忆线索：${profile.memoryHooks.join('；')}`);
    }
    if (memory.length) {
      lines.push(`你记得与用户相关的信息：${memory.join('；')}`);
    }
    if (regenAttempt > 0) {
      // 重生成场景：明确要求模型换角度，减少“同文复读”。
      lines.push(`这是第 ${regenAttempt + 1} 次生成同一轮回复，请在不违背设定的前提下换一个表达角度和句式，避免复读。`);
    }

    lines.push('要求：用简体中文回答，保持角色口吻，不跳出角色，不剧透超出该时间节点的剧情。');
    return lines.join('\n');
  }

  function selectGenerationConfig(input) {
    // 根据重生成次数动态提高采样随机性，提升“重新生成”差异。
    const regenAttempt = Number(input.regenAttempt || 0);
    const nonce = Math.random();
    const baseTemp = 0.82;
    const temp = Math.min(1.12, baseTemp + regenAttempt * 0.12 + nonce * 0.06);
    return {
      temperature: Number(temp.toFixed(2)),
      top_p: 0.95,
      presence_penalty: regenAttempt > 0 ? 0.55 : 0.3,
      frequency_penalty: regenAttempt > 0 ? 0.35 : 0.2,
      user: input.userTag || 'bangchat-user'
    };
  }

  function extractMemoriesFromUserText(text) {
    // 轻量记忆抽取：从用户输入中提取“身份/偏好/称呼”等信息。
    const content = String(text || '').trim();
    if (!content) return [];
    const out = [];

    const patterns = [
      /我叫([^\s，。！？,.!?\n]{1,20})/,
      /我是([^\s，。！？,.!?\n]{1,20})/,
      /请叫我([^\s，。！？,.!?\n]{1,20})/,
      /我喜欢([^，。！？,.!?\n]{1,28})/,
      /我不喜欢([^，。！？,.!?\n]{1,28})/,
      /我讨厌([^，。！？,.!?\n]{1,28})/,
      /我来自([^，。！？,.!?\n]{1,28})/
    ];

    patterns.forEach((rule) => {
      const m = content.match(rule);
      if (!m) return;
      const whole = m[0].trim();
      if (whole.length >= 2 && whole.length <= 40) out.push(whole);
    });

    if (/记住/.test(content) && content.length <= 60) {
      out.push(content);
    }
    return uniqueStable(compact(out));
  }

  function updateMemoryBank(memoryBank, userText) {
    // 合并旧记忆与新记忆，去重后截断到上限。
    const base = uniqueStable(compact(toArray(memoryBank)));
    const incoming = extractMemoriesFromUserText(userText);
    const merged = uniqueStable([...base, ...incoming]);
    if (merged.length <= MEMORY_MAX) return merged;
    return merged.slice(merged.length - MEMORY_MAX);
  }

  globalObj.BangCharacterEngine = {
    // 暴露给 index.html 使用的核心能力。
    buildCharacterPromptParts,
    selectGenerationConfig,
    updateMemoryBank
  };
})(window);
