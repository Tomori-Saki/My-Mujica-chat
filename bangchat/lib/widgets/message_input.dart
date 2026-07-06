import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 消息输入区域组件。
///
/// 包含多行文本输入框和发送按钮。
/// Enter 发送，Shift+Enter 换行。
class MessageInput extends StatefulWidget {
  /// 发送消息回调。
  final ValueChanged<String> onSend;

  /// 是否禁用输入（如流式响应进行中）。
  final bool disabled;

  const MessageInput({
    super.key,
    required this.onSend,
    this.disabled = false,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.disabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  /// 处理按键：Enter 发送，Shift+Enter 换行。
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        // Shift+Enter: 插入换行
        final text = _controller.text;
        final selection = _controller.selection;
        final newText = text.substring(0, selection.start) +
            '\n' +
            text.substring(selection.end);
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.start + 1,
          ),
        );
        return KeyEventResult.handled;
      } else {
        // Enter: 发送
        _handleSend();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xF2100F0B),
        border: Border(
          top: BorderSide(color: const Color(0x2DD9C276)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter):
                    _handleSend,
              },
              child: Focus(
                onKeyEvent: _handleKeyEvent,
                child: TextField(
                  controller: _controller,
                  enabled: !widget.disabled,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(
                    color: Color(0xFFEFE7D4),
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: '输入消息，Enter 发送，Shift+Enter 换行',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: widget.disabled ? null : _handleSend,
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }
}
