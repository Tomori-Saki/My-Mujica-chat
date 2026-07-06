/// 角色说话语气实体，映射 speech_style 表。
class SpeechStyle {
  final int? id;
  final String characterId;
  final String description;

  const SpeechStyle({
    this.id,
    required this.characterId,
    required this.description,
  });

  factory SpeechStyle.fromMap(Map<String, dynamic> map) {
    return SpeechStyle(
      id: map['id'] as int?,
      characterId: (map['character_id'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
    );
  }
}
