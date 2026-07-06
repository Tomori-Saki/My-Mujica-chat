/// 聊天消息 UI 模型。
/// type: 'user' | 'stream' | 'reply' | 'event'
class ChatMessage {
  final String type;
  final String sender;
  final String content;
  final String timestamp;

  const ChatMessage({
    required this.type,
    required this.sender,
    required this.content,
    required this.timestamp,
  });

  /// 从 chat_message 数据库行构造。
  factory ChatMessage.fromDbMap(Map<String, dynamic> map) {
    return ChatMessage(
      type: (map['role'] as String?) == 'user' ? 'user' : 'reply',
      sender: (map['role'] as String?) == 'user'
          ? '你'
          : ((map['character_id'] as String?) ?? 'assistant'),
      content: (map['content'] as String?) ?? '',
      timestamp: (map['created_at'] as String?) ?? '',
    );
  }
}
