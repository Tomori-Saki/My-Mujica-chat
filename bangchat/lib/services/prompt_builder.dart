import '../database/database_helper.dart';
import '../models/character_card.dart';
import '../models/character_profile.dart';
import '../models/timeline.dart';

/// Prompt 拼装器 —— 独立模块，不与其他业务层耦合。
///
/// 从数据库提取指定时间线下的所有角色信息
///（基本信息 + 性格 + 说话语气 + 时间线偏移），
/// 拼装为结构化的 system prompt。
class PromptBuilder {
  final DatabaseHelper _db = DatabaseHelper();

  /// band_id → 乐队中文名映射。
  static const _bandMap = {
    'mygo': 'MyGO!!!!!',
    'avemujica': 'Ave Mujica',
    'crychic': 'CRYCHIC',
  };

  /// 为指定时间线构建完整的 system prompt。
  ///
  /// [timelineId] 时间线 ID（如 t1_crychic_after）
  /// 返回结构化的系统提示词文本，可作为 AI 的 system message。
  Future<String> buildSystemPrompt(String timelineId) async {
    final profiles = await _db.findCharactersByTimeline(timelineId);

    if (profiles.isEmpty) {
      return '当前时间线无可用角色数据。';
    }

    final timeline = await _db.findTimelineById(timelineId);

    final cards = <CharacterCard>[];
    for (final p in profiles) {
      cards.add(await _buildCharacterCard(p, timelineId));
    }

    return _assemblePrompt(cards, timeline);
  }

  /// 构建单个角色在指定时间线下的完整信息卡片。
  ///
  /// 从 5 张独立表中提取数据并聚合：
  /// personality_trait、speech_style、timeline_character_state、
  /// character_detail、special_addressing。
  Future<CharacterCard> _buildCharacterCard(
    CharacterProfile profile,
    String timelineId,
  ) async {
    final card = CharacterCard(
      id: profile.id,
      nameCn: profile.nameCn,
      nameJp: profile.nameJp,
      nameEn: profile.nameEn,
      bandName: _bandMap[profile.bandId] ?? profile.bandId,
      school: profile.school,
      role: profile.role,
      instrument: profile.instrument,
      stageName: profile.stageName,
      summary: profile.summary,
    );

    // 性格标签
    final traits = await _db.findPersonalityTraits(profile.id);
    card.personalityTraits.addAll(
        traits.map((t) => t.trait));

    // 说话语气
    final style = await _db.findSpeechStyle(profile.id);
    if (style != null) {
      card.speechStyle = style.description;
    }

    // 时间线偏移
    final state = await _db.findTimelineState(timelineId, profile.id);
    if (state != null) {
      card.stateDescription = state.stateDescription;
      card.personalityAdjust = state.personalityAdjust;
      card.speechAdjust = state.speechAdjust;
    }

    // 行为细节
    final details = await _db.findCharacterDetails(profile.id);
    card.details.addAll(details.map((d) => d.detail));

    // 特殊称呼
    final addressings = await _db.findSpecialAddressings(profile.id);
    card.addressings.addAll(addressings.map((a) => AddressingInfo(
          targetName: a.targetName,
          alias: a.alias,
          note: a.note,
        )));

    return card;
  }

  /// 将所有角色卡片按乐队分组，拼装为最终的 System Prompt 文本。
  ///
  /// 根据时间线的乐队状态注入关系约束，
  /// 确保不同时间线下角色认知不跨越。
  String _assemblePrompt(List<CharacterCard> cards, Timeline? timeline) {
    final sb = StringBuffer();

    sb.write('你是 BanG Dream! 世界中的角色扮演 AI。\n');
    sb.write('你将扮演以下角色之一，根据用户的消息进行回复。\n\n');

    // 时间线关系约束
    sb.write('=== 时间线关系约束 ===\n');
    sb.write('时间线：${timeline?.title ?? "未知"}\n');

    final crychicStatus = timeline?.crychicStatus ?? '';
    final mygoStatus = timeline?.mygoStatus ?? '';
    final aveStatus = timeline?.avemujicaStatus ?? '';

    sb.write('当前各乐队状态：\n');
    sb.write('- CRYCHIC: ${_statusLabel(crychicStatus)}\n');
    sb.write('- MyGO!!!!!: ${_statusLabel(mygoStatus)}\n');
    sb.write('- Ave Mujica: ${_statusLabel(aveStatus)}\n\n');

    sb.write('角色关系规则（严格遵循）：\n');

    if (mygoStatus == 'not_formed' && aveStatus == 'not_formed') {
      sb.write('- CRYCHIC 已解散，但其前成员（高松灯、长崎素世、椎名立希、'
          '丰川祥子、若叶睦）在 CRYCHIC 时期就已互相认识。\n');
      sb.write('- MyGO!!!!! 尚未成立。千早爱音（Anon）和要乐奈（Rana）'
          '此时尚未与 CRYCHIC 成员结识。\n');
      sb.write('  → 高松灯不认识千早爱音。长崎素世不认识千早爱音。'
          '椎名立希不认识千早爱音。\n');
      sb.write('  → 如用户提及爱音或乐奈，你所扮演的角色应表示'
          '「不认识」或「没听说过」。\n');
      sb.write('- Ave Mujica 尚未成立。三角初华、八幡海铃、祐天寺喵梦'
          '尚未以 Ave Mujica 身份活动。\n\n');
    } else if (mygoStatus == 'formed' && aveStatus == 'not_formed') {
      sb.write('- MyGO!!!!! 已成立。成员（高松灯、千早爱音、要乐奈、'
          '长崎素世、椎名立希）互相认识并信任彼此。\n');
      sb.write('- Ave Mujica 尚未成立。丰川祥子尚未公开组队计划，'
          '三角初华等人仍以原有身份活动。\n');
      sb.write('  → 你所扮演的角色尚未知道 Ave Mujica 的存在，'
          '不可提及该乐队名或成员的舞台名。\n\n');
    } else {
      sb.write('- MyGO!!!!! 和 Ave Mujica 均已成立，'
          '所有角色均可能互相认识或听说过对方。\n');
      sb.write('- CRYCHIC 已是过去，不可混淆不同乐队成员当前的归属关系。\n\n');
    }

    // 角色设定
    sb.write('=== 当前时间线角色设定 ===\n\n');

    final mygoCards =
        cards.where((c) => c.bandName == 'MyGO!!!!!').toList();
    final aveCards =
        cards.where((c) => c.bandName == 'Ave Mujica').toList();

    if (mygoCards.isNotEmpty) {
      sb.write('--- MyGO!!!!! ---\n\n');
      for (final card in mygoCards) {
        sb.write(card.toPromptSection());
        sb.write('\n');
      }
    }

    if (aveCards.isNotEmpty) {
      sb.write('--- Ave Mujica ---\n\n');
      for (final card in aveCards) {
        sb.write(card.toPromptSection());
        sb.write('\n');
      }
    }

    sb.write('=== 交互规则 ===\n');
    sb.write('- 严格根据以上角色设定和关系约束进行回复，'
        '禁止混淆不同时间线的性格、语气和人物关系。\n');
    sb.write('- 使用口语化的中文回复，保持角色的说话风格。\n');
    sb.write('- 称呼其他角色时使用上述\'称呼方式\'中规定的称呼。\n');
    sb.write('- 如果用户提到你在此时间线中不应认识的角色，'
        '请自然地表示不认识或困惑。\n');

    return sb.toString();
  }

  /// 将数据库状态码转为中文标签。
  String _statusLabel(String status) {
    switch (status) {
      case 'formed':
        return '已成立';
      case 'disbanded':
        return '已解散';
      case 'not_formed':
        return '未成立';
      default:
        return '未知';
    }
  }
}
