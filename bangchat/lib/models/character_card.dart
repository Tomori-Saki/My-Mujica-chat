/// 角色在特定时间线下的完整信息聚合 DTO。
///
/// 由 PromptBuilder 从 DB 提取并填充，纯粹的数据载体。
/// 字段为可变，方便 PromptBuilder 逐步填充各子表数据。
class CharacterCard {
  final String id;
  final String nameCn;
  final String nameJp;
  final String nameEn;
  final String bandName;
  String school;
  String role;
  String instrument;
  String stageName;
  String summary;
  List<String> personalityTraits;
  String personalityAdjust;
  String speechStyle;
  String speechAdjust;
  List<String> details;
  List<AddressingInfo> addressings;
  String stateDescription;

  CharacterCard({
    required this.id,
    required this.nameCn,
    required this.nameJp,
    required this.nameEn,
    required this.bandName,
    this.school = '',
    this.role = '',
    this.instrument = '',
    this.stageName = '',
    this.summary = '',
    List<String>? personalityTraits,
    this.personalityAdjust = '',
    this.speechStyle = '',
    this.speechAdjust = '',
    List<String>? details,
    List<AddressingInfo>? addressings,
    this.stateDescription = '',
  })  : personalityTraits = personalityTraits ?? [],
        details = details ?? [],
        addressings = addressings ?? [];

  /// 将角色卡渲染为 prompt 中的角色描述段落。
  String toPromptSection() {
    final sb = StringBuffer();

    sb.write('【$nameCn');
    if (stageName.isNotEmpty) {
      sb.write(' / $stageName');
    }
    sb.write('】（$nameJp / $nameEn）\n');

    sb.write('学校：$school\n');
    sb.write('乐队：$bandName  |  角色：$role');
    if (instrument.isNotEmpty) {
      sb.write('（$instrument）');
    }
    sb.write('\n');

    if (summary.isNotEmpty) {
      sb.write('概要：$summary\n');
    }

    if (stateDescription.isNotEmpty) {
      sb.write('当前状态：$stateDescription\n');
    }

    sb.write('性格：');
    if (personalityTraits.isNotEmpty) {
      sb.write(personalityTraits.join('、'));
    }
    if (personalityAdjust.isNotEmpty) {
      sb.write('（$personalityAdjust）');
    }
    sb.write('\n');

    sb.write('说话语气：');
    if (speechStyle.isNotEmpty) {
      sb.write(speechStyle);
    }
    if (speechAdjust.isNotEmpty) {
      if (speechStyle.isNotEmpty) sb.write('；');
      sb.write(speechAdjust);
    }
    sb.write('\n');

    if (details.isNotEmpty) {
      sb.write('行为特征：\n');
      for (final d in details) {
        sb.write('  - $d\n');
      }
    }

    if (addressings.isNotEmpty) {
      sb.write('称呼方式：\n');
      for (final a in addressings) {
        sb.write('  - 称呼${a.targetName}为「${a.alias}」');
        if (a.note.isNotEmpty) {
          sb.write('（${a.note}）');
        }
        sb.write('\n');
      }
    }

    return sb.toString();
  }
}

/// 角色称呼信息。
class AddressingInfo {
  final String targetName;
  final String alias;
  final String note;

  const AddressingInfo({
    required this.targetName,
    required this.alias,
    this.note = '',
  });
}
