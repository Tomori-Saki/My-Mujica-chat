import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

/// LLM API 调用服务。
///
/// 直接调用 OpenAI 兼容的 /v1/chat/completions API，
/// 通过 HTTP POST + SSE 流式读取 AI 回复。
class LlmService {
  final Dio _dio;

  /// 构造 LLM 服务，可注入自定义 Dio 实例（用于测试）。
  LlmService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 120),
            ));

  /// 流式调用 LLM API，返回 token 流。
  ///
  /// [apiUrl] API 基础地址（如 https://api.openai.com/v1）
  /// [apiKey] API 密钥
  /// [modelName] 模型名称（如 gpt-4o-mini）
  /// [systemPrompt] 系统提示词
  /// [userContent] 用户消息内容
  ///
  /// 返回 [Stream<String>]，每个事件为一个 token。
  /// 流结束时发送空字符串表示完成。
  /// 流错误时发送以 "ERROR:" 开头的字符串。
  Stream<String> streamChat({
    required String apiUrl,
    required String apiKey,
    required String modelName,
    required String systemPrompt,
    required String userContent,
  }) async* {
    final url = '${apiUrl.replaceAll(RegExp(r'/+$'), '')}/v1/chat/completions';

    final requestBody = {
      'model': modelName.isNotEmpty ? modelName : 'gpt-4o-mini',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userContent},
      ],
      'stream': true,
    };

    try {
      final response = await _dio.post<ResponseBody>(
        url,
        data: json.encode(requestBody),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data!.stream;
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        final lines = text.split('\n');

        for (final line in lines) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data.isEmpty || data == '[DONE]') continue;

          try {
            final jsonData = json.decode(data) as Map<String, dynamic>;
            final choices = jsonData['choices'] as List<dynamic>?;
            if (choices == null || choices.isEmpty) continue;
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            if (delta == null) continue;
            final token = delta['content'];
            if (token == null) continue;
            yield token.toString();
          } catch (_) {
            // 跳过无法解析的 chunk
          }
        }
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      String errorBody = e.message ?? '未知错误';
      if (e.response?.data != null) {
        try {
          errorBody = e.response!.data.toString();
        } catch (_) {}
      }
      yield 'ERROR:AI API 返回 $statusCode: $errorBody';
    } catch (e) {
      yield 'ERROR:AI 调用失败: $e';
    }
  }
}
