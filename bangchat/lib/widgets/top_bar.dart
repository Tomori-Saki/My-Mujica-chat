import 'package:flutter/material.dart';

/// 顶部导航栏组件。
///
/// 对应原 TopBar.vue。包含左侧区域（返回按钮 + 品牌名）、
/// 中间标题和右侧模型名称。
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  /// 中央标题文本。
  final String centerText;

  /// 是否显示返回按钮。
  final bool showBack;

  /// 模型名称（右侧显示）。
  final String modelName;

  /// 点击返回时回调。
  final VoidCallback? onBack;

  const TopBar({
    super.key,
    this.centerText = '',
    this.showBack = false,
    this.modelName = '',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // 左侧：返回按钮 + 品牌
          SizedBox(
            width: 140,
            child: Row(
              children: [
                if (showBack)
                  TextButton(
                    onPressed: onBack,
                    style: TextButton.styleFrom(
                      foregroundColor: AppThemeLight.text,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '← 返回',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(width: 4),
                const Text(
                  'BanGChat',
                  style: TextStyle(
                    fontSize: 18,
                    letterSpacing: 2,
                    fontFamily: 'Cormorant Garamond',
                  ),
                ),
              ],
            ),
          ),
          // 中间：页面标题
          Expanded(
            child: Text(
              centerText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                letterSpacing: 1,
                color: AppThemeLight.gold,
              ),
            ),
          ),
          // 右侧：模型名称
          SizedBox(
            width: 140,
            child: Text(
              modelName.isNotEmpty ? modelName : '未连接',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: AppThemeLight.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// 主题色引用（独立以避免循环导入）。
class AppThemeLight {
  AppThemeLight._();
  static const gold = Color(0xFFD8C076);
  static const text = Color(0xFFEFE7D4);
  static const muted = Color(0xFFA59B86);
}
