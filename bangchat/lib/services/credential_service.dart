import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API 凭证安全存储服务。
///
/// 使用 flutter_secure_storage（Windows 上为 DPAPI，
/// Android 上为 EncryptedSharedPreferences）加密存储
/// LLM API 的 URL、Key 和模型名称。
class CredentialService {
  static const _storage = FlutterSecureStorage();
  static const _keyUrl = 'bangchat_model_url';
  static const _keyApiKey = 'bangchat_api_key';
  static const _keyModelName = 'bangchat_model_name';

  /// 加密保存凭证。
  ///
  /// [url] LLM API 基础地址
  /// [apiKey] API 密钥
  /// [modelName] 模型名称
  Future<void> saveCredentials({
    required String url,
    required String apiKey,
    required String modelName,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUrl, value: url),
      _storage.write(key: _keyApiKey, value: apiKey),
      _storage.write(key: _keyModelName, value: modelName),
    ]);
  }

  /// 读取并解密凭证。
  ///
  /// 返回值 Map 包含 url、apiKey、modelName 三个字段。
  /// 任一字段缺失则返回 null。
  Future<Map<String, String>?> loadCredentials() async {
    final results = await Future.wait([
      _storage.read(key: _keyUrl),
      _storage.read(key: _keyApiKey),
      _storage.read(key: _keyModelName),
    ]);

    final url = results[0];
    final apiKey = results[1];
    final modelName = results[2];

    if (url != null && apiKey != null) {
      return {
        'url': url,
        'apiKey': apiKey,
        'modelName': modelName ?? '',
      };
    }
    return null;
  }

  /// 清除所有已保存的凭证。
  Future<void> clearCredentials() async {
    await Future.wait([
      _storage.delete(key: _keyUrl),
      _storage.delete(key: _keyApiKey),
      _storage.delete(key: _keyModelName),
    ]);
  }
}
