/// 时间线-角色状态关联实体，映射 timeline_character_state 表。
class TimelineCharacterState {
  final int? id;
  final String timelineId;
  final String characterId;
  final String stateDescription;
  final String personalityAdjust;
  final String speechAdjust;

  const TimelineCharacterState({
    this.id,
    required this.timelineId,
    required this.characterId,
    required this.stateDescription,
    this.personalityAdjust = '',
    this.speechAdjust = '',
  });

  factory TimelineCharacterState.fromMap(Map<String, dynamic> map) {
    return TimelineCharacterState(
      id: map['id'] as int?,
      timelineId: (map['timeline_id'] as String?) ?? '',
      characterId: (map['character_id'] as String?) ?? '',
      stateDescription: (map['state_description'] as String?) ?? '',
      personalityAdjust: (map['personality_adjust'] as String?) ?? '',
      speechAdjust: (map['speech_adjust'] as String?) ?? '',
    );
  }
}
