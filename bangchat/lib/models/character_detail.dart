/// 角色行为细节实体，映射 character_detail 表。
class CharacterDetail {
  final int? id;
  final String characterId;
  final String detail;
  final int sortOrder;

  const CharacterDetail({
    this.id,
    required this.characterId,
    required this.detail,
    this.sortOrder = 0,
  });

  factory CharacterDetail.fromMap(Map<String, dynamic> map) {
    return CharacterDetail(
      id: map['id'] as int?,
      characterId: (map['character_id'] as String?) ?? '',
      detail: (map['detail'] as String?) ?? '',
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }
}
