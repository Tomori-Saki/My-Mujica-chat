/// 台词示例实体，映射 dialogue 表。
class Dialogue {
  final int? id;
  final String characterId;
  final String text;
  final String source;
  final String context;
  final String action;
  final String targetId;
  final String targetName;

  const Dialogue({
    this.id,
    required this.characterId,
    required this.text,
    this.source = '',
    this.context = '',
    this.action = '',
    this.targetId = '',
    this.targetName = '',
  });

  factory Dialogue.fromMap(Map<String, dynamic> map) {
    return Dialogue(
      id: map['id'] as int?,
      characterId: (map['character_id'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      source: (map['source'] as String?) ?? '',
      context: (map['context'] as String?) ?? '',
      action: (map['action'] as String?) ?? '',
      targetId: (map['target_id'] as String?) ?? '',
      targetName: (map['target_name'] as String?) ?? '',
    );
  }
}
