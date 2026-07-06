import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/top_bar.dart';

/// 角色选择页面 —— 按乐队筛选角色网格。
///
/// 对应原 CharacterSelectionView.vue。
/// PC 端 5 列网格，移动端单列列表。
class CharacterSelectionScreen extends StatelessWidget {
  /// 乐队 ID（来自路由参数）。
  final String bandId;

  const CharacterSelectionScreen({super.key, required this.bandId});

  static const _bandNames = {
    'crychic': 'CRYCHIC',
    'mygo': 'MyGO!!!!!',
    'avemujica': 'Ave Mujica',
  };

  static const _allCharacters = [
    _CharInfo(id: 'tomori', name: '高松灯', initials: 'TT', band: 'mygo', crychic: true),
    _CharInfo(id: 'anon', name: '千早爱音', initials: 'AC', band: 'mygo', crychic: false),
    _CharInfo(id: 'rana', name: '要乐奈', initials: 'RK', band: 'mygo', crychic: false),
    _CharInfo(id: 'soyo', name: '长崎素世', initials: 'SN', band: 'mygo', crychic: true),
    _CharInfo(id: 'taki', name: '椎名立希', initials: 'TS', band: 'mygo', crychic: true),
    _CharInfo(id: 'sakiko', name: '丰川祥子', initials: 'ST', band: 'avemujica', crychic: true),
    _CharInfo(id: 'mutsumi', name: '若叶睦', initials: 'MW', band: 'avemujica', crychic: true),
    _CharInfo(id: 'umiri', name: '八幡海铃', initials: 'UY', band: 'avemujica', crychic: false),
    _CharInfo(id: 'uika', name: '三角初华', initials: 'UM', band: 'avemujica', crychic: false),
    _CharInfo(id: 'nyamu', name: '祐天寺喵梦', initials: 'NY', band: 'avemujica', crychic: false),
  ];

  List<_CharInfo> get characters {
    if (bandId == 'crychic') {
      return _allCharacters.where((c) => c.crychic).toList();
    }
    return _allCharacters.where((c) => c.band == bandId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bandName = _bandNames[bandId] ?? bandId;
    final chars = characters;

    return Scaffold(
      appBar: TopBar(
        centerText: bandName,
        showBack: true,
        onBack: () => context.go('/bands'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 640;
          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 5 : 1,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isWide ? 0.8 : 4.0,
            ),
            itemCount: chars.length,
            itemBuilder: (context, index) {
              final char = chars[index];
              return _CharacterCard(
                char: char,
                isWide: isWide,
                onTap: () {
                  context.go('/chat/$bandId/${char.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CharInfo {
  final String id;
  final String name;
  final String initials;
  final String band;
  final bool crychic;

  const _CharInfo({
    required this.id,
    required this.name,
    required this.initials,
    required this.band,
    required this.crychic,
  });
}

/// 角色卡片组件。
class _CharacterCard extends StatelessWidget {
  final _CharInfo char;
  final bool isWide;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.char,
    required this.isWide,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xCC14120C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x2DD9C276)),
        ),
        child: isWide
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _InitialsCircle(initials: char.initials),
                  const SizedBox(height: 12),
                  Text(
                    char.name,
                    style: const TextStyle(
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  const SizedBox(width: 16),
                  _InitialsCircle(initials: char.initials),
                  const SizedBox(width: 16),
                  Text(
                    char.name,
                    style: const TextStyle(
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 角色姓名首字母圆形容器。
class _InitialsCircle extends StatelessWidget {
  final String initials;

  const _InitialsCircle({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment.topCenter,
          colors: [
            const Color(0x26D8C076),
            const Color(0x66000000),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Color(0xFFD8C076),
          ),
        ),
      ),
    );
  }
}
