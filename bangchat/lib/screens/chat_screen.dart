import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/top_bar.dart';

/// 聊天页面 —— 核心交互界面。
///
/// 对应原 ChatView.vue。包含消息列表、流式 token 显示、
/// 消息输入和操作按钮（重新生成/回退）。
class ChatScreen extends StatefulWidget {
  /// 乐队 ID（来自路由参数）。
  final String bandId;

  /// 角色 ID（来自路由参数）。
  final String characterId;

  const ChatScreen({
    super.key,
    required this.bandId,
    required this.characterId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();

  static const _bandNames = {
    'crychic': 'CRYCHIC',
    'mygo': 'MyGO!!!!!',
    'avemujica': 'Ave Mujica',
  };

  static const _charNames = {
    'tomori': '高松灯', 'anon': '千早爱音', 'rana': '要乐奈',
    'soyo': '长崎素世', 'taki': '椎名立希', 'sakiko': '丰川祥子',
    'mutsumi': '若叶睦', 'umiri': '八幡海铃', 'uika': '三角初华',
    'nyamu': '祐天寺喵梦',
  };

  @override
  void initState() {
    super.initState();
    // 初始化聊天上下文
    Future.microtask(() async {
      final auth = context.read<AuthProvider>();
      final chat = context.read<ChatProvider>();
      await chat.initChat(
        bandId: widget.bandId,
        characterId: widget.characterId,
        modelUrl: auth.modelUrl,
        apiKey: auth.apiKey,
        modelName: auth.modelName,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bandName = _bandNames[widget.bandId] ?? widget.bandId;
    final charName = _charNames[widget.characterId] ?? widget.characterId;
    final centerTitle = '$bandName - $charName';
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: TopBar(
        centerText: centerTitle,
        showBack: true,
        modelName: auth.modelName,
        onBack: () => context.go('/bands/${widget.bandId}/characters'),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          // 每次消息变化时滚动到底部
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

          return Column(
            children: [
              // 消息列表
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x0DD8C076),
                        Color(0x1AD8C076),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: chat.messages.isEmpty
                      ? const Center(
                          child: Text(
                            '开始对话吧',
                            style: TextStyle(
                              color: Color(0xFFA59B86),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: chat.messages.length,
                          itemBuilder: (context, index) {
                            final msg = chat.messages[index];
                            final isLast =
                                index == chat.messages.length - 1;
                            return ChatBubble(
                              message: msg,
                              isLast: isLast,
                              onRegenerate: isLast
                                  ? () => chat.regenerate()
                                  : null,
                              onRollback: isLast
                                  ? () => chat.rollback()
                                  : null,
                            );
                          },
                        ),
                ),
              ),
              // 消息输入
              MessageInput(
                onSend: (text) => chat.sendMessage(text),
                disabled: chat.isStreaming,
              ),
            ],
          );
        },
      ),
    );
  }
}
