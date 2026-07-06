import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/login_screen.dart';
import 'screens/band_selection_screen.dart';
import 'screens/character_selection_screen.dart';
import 'screens/chat_screen.dart';
import 'theme.dart';

/// 应用根组件 —— 配置路由与全局 Provider。
class BangchatApp extends StatelessWidget {
  BangchatApp({super.key});

  final _router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final isLoginPage = state.matchedLocation == '/';

      // 未登录 → 只能访问登录页
      if (!auth.isLoggedIn && !isLoginPage) {
        return '/';
      }
      // 已登录且访问登录页 → 跳转到乐队选择
      if (auth.isLoggedIn && isLoginPage) {
        return '/bands';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/bands',
        name: 'bands',
        builder: (context, state) => const BandSelectionScreen(),
      ),
      GoRoute(
        path: '/bands/:bandId/characters',
        name: 'characters',
        builder: (context, state) {
          final bandId = state.pathParameters['bandId']!;
          return CharacterSelectionScreen(bandId: bandId);
        },
      ),
      GoRoute(
        path: '/chat/:bandId/:characterId',
        name: 'chat',
        builder: (context, state) {
          final bandId = state.pathParameters['bandId']!;
          final characterId = state.pathParameters['characterId']!;
          return ChatScreen(bandId: bandId, characterId: characterId);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp.router(
        title: 'BanGChat',
        theme: AppTheme.darkTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
