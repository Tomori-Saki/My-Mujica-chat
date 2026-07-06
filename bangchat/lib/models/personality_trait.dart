/// 角色性格标签实体，映射 personality_trait 表。
class PersonalityTrait {
  final int? id;
  final String characterId;
  final String trait;
  final int sortOrder;

  const PersonalityTrait({
    this.id,
    required this.characterId,
    required this.trait,
    this.sortOrder = 0,
  });

  factory PersonalityTrait.fromMap(Map<String, dynamic> map) {
    return PersonalityTrait(
      id: map['id'] as int?,
      characterId: (map['character_id'] as String?) ?? '',
      trait: (map['trait'] as String?) ?? '',
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }
}
