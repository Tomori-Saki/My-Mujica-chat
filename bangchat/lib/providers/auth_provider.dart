import 'package:flutter/foundation.dart';

import '../services/credential_service.dart';

/// 认证状态管理 —— 管理 LLM API 凭证的增删查改。
///
/// 负责凭证的登录、从安全存储恢复、登出清除，
/// 以及已登录状态的维护。
class AuthProvider extends ChangeNotifier {
  final CredentialService _credentialService = CredentialService();

  String _modelUrl = '';
  String _modelName = '';
  String _apiKey = '';
  bool _isLoggedIn = false;

  /// 当前模型 API 地址。
  String get modelUrl => _modelUrl;

  /// 当前模型名称。
  String get modelName => _modelName;

  /// API 密钥（仅内存中，不持久化到日志）。
  String get apiKey => _apiKey;

  /// 是否已设置凭证。
  bool get isLoggedIn => _isLoggedIn;

  /// 登录：保存凭证到安全存储，标记已登录。
  ///
  /// [url] LLM API 基础地址
  /// [name] 模型名称（可为空）
  /// [key] API 密钥
  Future<void> login({
    required String url,
    required String name,
    required String key,
  }) async {
    _modelUrl = url;
    _modelName = name;
    _apiKey = key;
    _isLoggedIn = true;
    notifyListeners();

    await _credentialService.saveCredentials(
      url: url,
      apiKey: key,
      modelName: name,
    );
  }

  /// 从安全存储恢复凭证（应用启动时调用）。
  ///
  /// 返回 true 表示恢复成功，false 表示无已存储凭证。
  Future<bool> restore() async {
    final creds = await _credentialService.loadCredentials();
    if (creds != null && creds['url'] != null && creds['apiKey'] != null) {
      _modelUrl = creds['url']!;
      _modelName = creds['modelName'] ?? '';
      _apiKey = creds['apiKey']!;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 登出：清除内存中的凭证和安全存储中的持久化数据。
  Future<void> logout() async {
    _modelUrl = '';
    _modelName = '';
    _apiKey = '';
    _isLoggedIn = false;
    notifyListeners();

    await _credentialService.clearCredentials();
  }
}
