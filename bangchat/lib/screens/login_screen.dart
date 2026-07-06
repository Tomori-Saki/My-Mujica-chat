import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// 登录页面 —— 输入 LLM API 凭证。
///
/// 对应原 LoginView.vue。用户输入 API 地址、密钥和模型名称后
/// 配置完成后跳转到乐队选择页。
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _urlController = TextEditingController(text: 'https://api.openai.com/v1');
  final _keyController = TextEditingController();
  final _modelController = TextEditingController(text: 'gpt-4o-mini');
  bool _loading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    // 尝试恢复已保存的凭证，成功则直接跳转
    Future.microtask(() async {
      final auth = context.read<AuthProvider>();
      final restored = await auth.restore();
      if (restored && mounted) {
        _urlController.text = auth.modelUrl;
        _modelController.text = auth.modelName;
        context.go('/bands');
      }
    });
  }

  Future<void> _handleLogin() async {
    setState(() => _errorMsg = null);

    final url = _urlController.text.trim();
    final key = _keyController.text.trim();
    final model = _modelController.text.trim();

    if (url.isEmpty) {
      setState(() => _errorMsg = '请输入模型 API 地址');
      return;
    }
    if (key.isEmpty) {
      setState(() => _errorMsg = '请输入 API Key');
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.login(url: url, name: model, key: key);
      if (mounted) {
        context.go('/bands');
      }
    } catch (e) {
      setState(() => _errorMsg = '保存凭证失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 420,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xF212100C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x2DD9C276)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '连接 AI',
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),

              // API 地址
              _buildLabel('模型 API 地址'),
              const SizedBox(height: 6),
              TextField(
                controller: _urlController,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'https://api.openai.com/v1',
                ),
              ),
              const SizedBox(height: 16),

              // API Key
              _buildLabel('API Key'),
              const SizedBox(height: 6),
              TextField(
                controller: _keyController,
                obscureText: true,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'sk-...',
                ),
              ),
              const SizedBox(height: 16),

              // 模型名称
              _buildLabel('模型名称'),
              const SizedBox(height: 6),
              TextField(
                controller: _modelController,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'gpt-4o-mini',
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'API Key 使用系统安全存储加密保存，仅保存在本设备中。',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 4),

              // 错误提示
              if (_errorMsg != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x1FC46B6B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFC46B6B),
                    ),
                  ),
                ),

              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _loading ? '连接中...' : '登录',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFFA59B86),
      ),
    );
  }
}
