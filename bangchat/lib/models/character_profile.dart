/// 角色基础信息实体，映射 character_profile 表。
class CharacterProfile {
  final String id;
  final String nameCn;
  final String nameJp;
  final String nameEn;
  final String bandId;
  final String school;
  final String role;
  final String instrument;
  final String stageName;
  final String summary;

  const CharacterProfile({
    required this.id,
    required this.nameCn,
    required this.nameJp,
    required this.nameEn,
    required this.bandId,
    this.school = '',
    this.role = '',
    this.instrument = '',
    this.stageName = '',
    this.summary = '',
  });

  factory CharacterProfile.fromMap(Map<String, dynamic> map) {
    return CharacterProfile(
      id: map['id'] as String,
      nameCn: (map['name_cn'] as String?) ?? '',
      nameJp: (map['name_jp'] as String?) ?? '',
      nameEn: (map['name_en'] as String?) ?? '',
      bandId: (map['band_id'] as String?) ?? '',
      school: (map['school'] as String?) ?? '',
      role: (map['role'] as String?) ?? '',
      instrument: (map['instrument'] as String?) ?? '',
      stageName: (map['stage_name'] as String?) ?? '',
      summary: (map['summary'] as String?) ?? '',
    );
  }
}
