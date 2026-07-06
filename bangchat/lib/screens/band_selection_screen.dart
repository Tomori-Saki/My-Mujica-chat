import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/top_bar.dart';

/// 乐队选择页面 —— 3 个乐队面板，斜线分割。
///
/// 对应原 BandSelectionView.vue。左右并排显示
/// CRYCHIC、MyGO!!!!!、Ave Mujica 三个乐队，含过渡动画效果。
class BandSelectionScreen extends StatefulWidget {
  const BandSelectionScreen({super.key});

  @override
  State<BandSelectionScreen> createState() => _BandSelectionScreenState();
}

class _BandSelectionScreenState extends State<BandSelectionScreen> {
  String? _hovered;

  static const _bands = [
    _BandInfo(
      id: 'crychic',
      name: 'CRYCHIC',
      gradient: LinearGradient(
        colors: [Color(0x8C5A468C), Color(0xB3281E46)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _BandInfo(
      id: 'mygo',
      name: 'MyGO!!!!!',
      gradient: LinearGradient(
        colors: [Color(0x80466ED2), Color(0xB31E3264)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _BandInfo(
      id: 'avemujica',
      name: 'Ave Mujica',
      gradient: LinearGradient(
        colors: [Color(0x80D2505A), Color(0xB3641428)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  void _selectBand(_BandInfo band) {
    context.go('/bands/${band.id}/characters');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TopBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 640;
                return isWide
                    ? _buildHorizontalLayout()
                    : _buildVerticalLayout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      children: [
        for (var i = 0; i < _bands.length; i++)
          Expanded(
            child: _BandPanel(
              band: _bands[i],
              index: i,
              totalBands: _bands.length,
              isHorizontal: true,
              isHovered: _hovered == _bands[i].id,
              onHover: (hovered) {
                setState(() => _hovered = hovered ? _bands[i].id : null);
              },
              onTap: () => _selectBand(_bands[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      children: [
        for (var i = 0; i < _bands.length; i++)
          Expanded(
            child: _BandPanel(
              band: _bands[i],
              index: i,
              totalBands: _bands.length,
              isHorizontal: false,
              isHovered: _hovered == _bands[i].id,
              onHover: (hovered) {
                setState(() => _hovered = hovered ? _bands[i].id : null);
              },
              onTap: () => _selectBand(_bands[i]),
            ),
          ),
      ],
    );
  }
}

class _BandInfo {
  final String id;
  final String name;
  final LinearGradient gradient;

  const _BandInfo({
    required this.id,
    required this.name,
    required this.gradient,
  });
}

/// 单个乐队面板，支持斜线裁剪效果。
class _BandPanel extends StatelessWidget {
  final _BandInfo band;
  final int index;
  final int totalBands;
  final bool isHorizontal;
  final bool isHovered;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  const _BandPanel({
    required this.band,
    required this.index,
    required this.totalBands,
    required this.isHorizontal,
    required this.isHovered,
    required this.onHover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          transform: isHovered
              ? (Matrix4.identity()..scale(1.03))
              : Matrix4.identity(),
          child: ClipPath(
            clipper: _DiagonalClipper(
              index: index,
              total: totalBands,
              isHorizontal: isHorizontal,
            ),
            child: Container(
              decoration: BoxDecoration(gradient: band.gradient),
              child: Stack(
                children: [
                  // 背景大字
                  Center(
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: isHovered
                          ? const Offset(0, -0.05)
                          : Offset.zero,
                      child: Text(
                        band.name,
                        style: TextStyle(
                          fontSize: isHorizontal ? 48 : 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                    ),
                  ),
                  // 底部标签
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isHovered ? 1.0 : 0.0,
                      child: Text(
                        band.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          letterSpacing: 4,
                          color: Color(0xFFD8C076),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 斜线裁剪路径。
///
/// PC 布局（水平排列）：垂直斜线从左→右
/// 移动端布局（垂直排列）：水平斜线从上→下
class _DiagonalClipper extends CustomClipper<Path> {
  final int index;
  final int total;
  final bool isHorizontal;

  const _DiagonalClipper({
    required this.index,
    required this.total,
    required this.isHorizontal,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    if (isHorizontal) {
      // PC：垂直斜线分割
      if (index == 0) {
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width * 0.85, size.height);
        path.lineTo(0, size.height);
      } else if (index == total - 1) {
        path.moveTo(size.width * 0.15, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
      } else {
        path.moveTo(size.width * 0.15, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width * 0.85, size.height);
        path.lineTo(0, size.height);
      }
    } else {
      // 移动端：水平斜线分割
      if (index == 0) {
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height * 0.85);
        path.lineTo(0, size.height);
      } else if (index == total - 1) {
        path.moveTo(0, size.height * 0.15);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
      } else {
        path.moveTo(0, size.height * 0.15);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height * 0.85);
        path.lineTo(0, size.height);
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _DiagonalClipper oldClipper) => false;
}
