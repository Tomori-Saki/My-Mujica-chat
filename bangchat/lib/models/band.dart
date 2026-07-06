/// 乐队数据类，映射 band 表。
class Band {
  final String id;
  final String name;
  final String nameCn;
  final String status;
  final String notes;
  final List<String> members;

  const Band({
    required this.id,
    required this.name,
    required this.nameCn,
    this.status = '',
    this.notes = '',
    this.members = const [],
  });

  factory Band.fromMap(Map<String, dynamic> map) {
    return Band(
      id: map['id'] as String,
      name: map['name'] as String,
      nameCn: (map['name_cn'] as String?) ?? '',
      status: (map['status'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_cn': nameCn,
      'status': status,
      'notes': notes,
    };
  }
}
