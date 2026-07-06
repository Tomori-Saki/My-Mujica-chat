import 'package:flutter/material.dart';

import '../models/chat_message.dart';

/// 聊天消息气泡组件。
///
/// 根据消息类型（user/stream/reply/event）显示不同样式的气泡。
/// reply 类型消息显示重新生成和回退操作按钮。
class ChatBubble extends StatelessWidget {
  /// 消息数据。
  final ChatMessage message;

  /// 是否为列表中最后一条消息（仅 reply 类型显示操作按钮）。
  final bool isLast;

  /// 重新生成回调。
  final VoidCallback? onRegenerate;

  /// 回退回调。
  final VoidCallback? onRollback;

  const ChatBubble({
    super.key,
    required this.message,
    this.isLast = false,
    this.onRegenerate,
    this.onRollback,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUser
                    ? const Color(0x4DD9C276)
                    : const Color(0x0DFFFFFF),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.sender,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFA59B86),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFEFE7D4),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // reply 类型消息的操作按钮
          if (message.type == 'reply' && isLast)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionButton(
                    icon: Icons.refresh,
                    tooltip: '重新生成',
                    onTap: onRegenerate,
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.undo,
                    tooltip: '回退到此',
                    onTap: onRollback,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 消息操作小按钮。
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xD912120E),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0x33D9C276),
            ),
          ),
          child: Icon(
            icon,
            size: 10,
            color: const Color(0xFFA59B86),
          ),
        ),
      ),
    );
  }
}
