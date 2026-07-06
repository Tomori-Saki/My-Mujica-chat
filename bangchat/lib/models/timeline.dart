/// 时间线实体，映射 timeline 表。
class Timeline {
  final String id;
  final String title;
  final String summary;
  final String crychicStatus;
  final String mygoStatus;
  final String avemujicaStatus;

  const Timeline({
    required this.id,
    required this.title,
    required this.summary,
    this.crychicStatus = '',
    this.mygoStatus = '',
    this.avemujicaStatus = '',
  });

  factory Timeline.fromMap(Map<String, dynamic> map) {
    return Timeline(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      summary: (map['summary'] as String?) ?? '',
      crychicStatus: (map['crychic_status'] as String?) ?? '',
      mygoStatus: (map['mygo_status'] as String?) ?? '',
      avemujicaStatus: (map['avemujica_status'] as String?) ?? '',
    );
  }
}
