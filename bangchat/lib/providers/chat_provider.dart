import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../database/database_helper.dart';
import '../services/llm_service.dart';
import '../services/prompt_builder.dart';

/// 聊天状态管理 —— 管理消息列表、流式对话、重新生成与回退。
///
/// 负责消息的发送、AI 流式 token 的接收与聚合、
/// 重新生成和回退操作，以及聊天历史的持久化。
class ChatProvider extends ChangeNotifier {
  final LlmService _llmService = LlmService();
  final PromptBuilder _promptBuilder = PromptBuilder();
  final DatabaseHelper _db = DatabaseHelper();

  /// 消息列表：每条含 type/sender/content/timestamp。
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// 当前是否正在进行 AI 流式响应。
  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  String _bandId = '';
  String _characterId = '';
  String _modelUrl = '';
  String _apiKey = '';
  String _modelName = '';

  String _charName = '';
  String _timelineId = '';

  StreamSubscription<String>? _streamSubscription;

  /// bandId → timelineId 映射。
  static const _bandToTimeline = {
    'crychic': 't1_crychic_after',
    'mygo': 't2_mygo_formed',
    'avemujica': 't3_both_formed',
  };

  /// characterId → 中文名映射。
  static const _charNames = {
    'tomori': '高松灯', 'anon': '千早爱音', 'rana': '要乐奈',
    'soyo': '长崎素世', 'taki': '椎名立希', 'sakiko': '丰川祥子',
    'mutsumi': '若叶睦', 'umiri': '八幡海铃', 'uika': '三角初华',
    'nyamu': '祐天寺喵梦',
  };

  /// 初始化聊天上下文。
  ///
  /// [bandId] 乐队 ID
  /// [characterId] 角色 ID
  /// [modelUrl] API 地址
  /// [apiKey] API 密钥
  /// [modelName] 模型名称
  Future<void> initChat({
    required String bandId,
    required String characterId,
    required String modelUrl,
    required String apiKey,
    required String modelName,
  }) async {
    _bandId = bandId;
    _characterId = characterId;
    _modelUrl = modelUrl;
    _apiKey = apiKey;
    _modelName = modelName;
    _charName = _charNames[characterId] ?? characterId;
    _timelineId = _bandToTimeline[bandId] ?? 't2_mygo_formed';

    // 加载历史消息
    _messages.clear();
    final history = await _db.findChatHistory(_timelineId);
    _messages.addAll(history);
    notifyListeners();
  }

  /// 发送用户消息并获取 AI 流式回复。
  ///
  /// [content] 用户输入的文本内容
  Future<void> sendMessage(String content) async {
    if (content.isEmpty || _isStreaming) return;

    // 添加用户消息
    final userMsg = ChatMessage(
      type: 'user',
      sender: '你',
      content: content,
      timestamp: DateTime.now().toIso8601String(),
    );
    _messages.add(userMsg);
    notifyListeners();

    // 持久化用户消息
    await _db.insertChatMessage(
      timelineId: _timelineId,
      characterId: null,
      role: 'user',
      content: content,
    );

    _isStreaming = true;
    notifyListeners();

    // 构建 system prompt
    final systemPrompt = await _promptBuilder.buildSystemPrompt(_timelineId);
    final fullPrompt = '$systemPrompt\n\n'
        '【当前角色】你正在扮演「$_charName」。'
        '请严格以上述设定中该角色的性格、说话语气、行为方式、称呼规则进行回复。'
        '使用口语化中文，保持角色口吻，不跳出角色。'
        '称呼其他角色时使用上述\'称呼方式\'中规定的称呼。';

    // 流式调用 LLM
    final stream = _llmService.streamChat(
      apiUrl: _modelUrl,
      apiKey: _apiKey,
      modelName: _modelName,
      systemPrompt: fullPrompt,
      userContent: content,
    );

    final fullContent = StringBuffer();
    int? streamMsgIndex;

    _streamSubscription = stream.listen(
      (token) {
        if (token.startsWith('ERROR:')) {
          _messages.add(ChatMessage(
            type: 'event',
            sender: '系统',
            content: token.substring(6),
            timestamp: DateTime.now().toIso8601String(),
          ));
          _isStreaming = false;
          notifyListeners();
          return;
        }

        fullContent.write(token);

        if (streamMsgIndex == null) {
          // 创建新的 stream 消息
          _messages.add(ChatMessage(
            type: 'stream',
            sender: _charName,
            content: token,
            timestamp: DateTime.now().toIso8601String(),
          ));
          streamMsgIndex = _messages.length - 1;
        } else {
          // 追加到现有 stream 消息
          final existing = _messages[streamMsgIndex!];
          _messages[streamMsgIndex!] = ChatMessage(
            type: 'stream',
            sender: existing.sender,
            content: existing.content + token,
            timestamp: existing.timestamp,
          );
        }
        notifyListeners();
      },
      onDone: () async {
        _isStreaming = false;

        // 移除所有 stream 消息，替换为一条 reply 消息
        _messages.removeWhere((m) => m.type == 'stream');
        final finalContent = fullContent.toString();
        if (finalContent.isNotEmpty) {
          _messages.add(ChatMessage(
            type: 'reply',
            sender: _charName,
            content: finalContent,
            timestamp: DateTime.now().toIso8601String(),
          ));

          // 持久化 AI 回复
          await _db.insertChatMessage(
            timelineId: _timelineId,
            characterId: _characterId,
            role: 'assistant',
            content: finalContent,
          );
        }

        _streamSubscription = null;
        notifyListeners();
      },
      onError: (error) {
        _isStreaming = false;
        _messages.add(ChatMessage(
          type: 'event',
          sender: '系统',
          content: '连接错误: $error',
          timestamp: DateTime.now().toIso8601String(),
        ));
        _streamSubscription = null;
        notifyListeners();
      },
    );
  }

  /// 重新生成：删除最后一条 reply 及其 stream，重发最后一条 user 消息。
  void regenerate() {
    // 移除最后一条 reply 及所有 stream
    while (_messages.isNotEmpty) {
      final last = _messages.last;
      if (last.type == 'reply' || last.type == 'stream') {
        _messages.removeLast();
      } else {
        break;
      }
    }

    // 找到最后一条 user 消息重发
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].type == 'user') {
        final content = _messages[i].content;
        // 异步触发发送，不阻塞 UI
        Future.microtask(() => sendMessage(content));
        break;
      }
    }
    notifyListeners();
  }

  /// 回退：删除最后一对 user+reply（及所有 stream）。
  void rollback() {
    // 移除所有 stream + reply
    while (_messages.isNotEmpty) {
      final last = _messages.last;
      if (last.type == 'reply' || last.type == 'stream') {
        _messages.removeLast();
      } else {
        break;
      }
    }
    // 移除最后一条 user
    if (_messages.isNotEmpty && _messages.last.type == 'user') {
      _messages.removeLast();
    }
    notifyListeners();
  }

  /// 获取当前角色中文名。
  String get charName => _charName;

  /// 获取当前时间线 ID。
  String get timelineId => _timelineId;

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
