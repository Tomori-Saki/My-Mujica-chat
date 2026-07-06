import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'database/data_loader.dart';
import 'database/database_helper.dart';

/// BanGchat 应用入口。
///
/// Windows 平台使用 sqflite_common_ffi 作为数据库工厂，
/// Android 平台使用默认 sqflite 工厂。
/// 首次启动时自动从 bundled JSON 文件初始化数据库。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows 桌面平台：初始化 FFI 数据库工厂
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 初始化数据库并导入 JSON 数据
  final db = await DatabaseHelper().database;
  final loader = DataLoader(db);
  await loader.initIfNeeded();

  runApp(BangchatApp());
}
