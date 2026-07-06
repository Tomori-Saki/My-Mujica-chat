/// 角色特殊称呼实体，映射 special_addressing 表。
class SpecialAddressing {
  final int? id;
  final String characterId;
  final String targetName;
  final String alias;
  final String note;

  const SpecialAddressing({
    this.id,
    required this.characterId,
    required this.targetName,
    required this.alias,
    this.note = '',
  });

  factory SpecialAddressing.fromMap(Map<String, dynamic> map) {
    return SpecialAddressing(
      id: map['id'] as int?,
      characterId: (map['character_id'] as String?) ?? '',
      targetName: (map['target_name'] as String?) ?? '',
      alias: (map['alias'] as String?) ?? '',
      note: (map['note'] as String?) ?? '',
    );
  }
}
