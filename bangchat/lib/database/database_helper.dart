import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/character_profile.dart';
import '../models/personality_trait.dart';
import '../models/speech_style.dart';
import '../models/character_detail.dart';
import '../models/special_addressing.dart';
import '../models/timeline.dart';
import '../models/timeline_character_state.dart';
import '../models/chat_message.dart';

/// 数据库帮助类 —— 管理 SQLite 数据库的打开/创建与所有查询。
///
/// 单例模式。跨平台支持依赖调用方在启动前设置正确的
/// databaseFactory（Windows 使用 sqflite_common_ffi）。
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  /// 获取数据库实例，若未打开则自动初始化。
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库：打开文件、建表。
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'bangchat.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// 建表回调 —— 执行完整的 schema（14 张表 + 1 张聊天消息表）。
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE IF NOT EXISTS school (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        notes TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS location (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        type TEXT,
        notes TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS band (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_cn TEXT,
        status TEXT,
        notes TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS character_profile (
        id TEXT PRIMARY KEY,
        name_cn TEXT NOT NULL,
        name_jp TEXT NOT NULL,
        name_en TEXT NOT NULL,
        band_id TEXT NOT NULL REFERENCES band(id),
        school TEXT,
        role TEXT,
        instrument TEXT,
        stage_name TEXT,
        summary TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS personality_trait (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id TEXT NOT NULL REFERENCES character_profile(id),
        trait TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0
      )
    ''');
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_pt_char ON personality_trait(character_id)');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS speech_style (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id TEXT NOT NULL UNIQUE REFERENCES character_profile(id),
        description TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS character_detail (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id TEXT NOT NULL REFERENCES character_profile(id),
        detail TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0
      )
    ''');
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_cd_char ON character_detail(character_id)');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS special_addressing (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id TEXT NOT NULL REFERENCES character_profile(id),
        target_name TEXT NOT NULL,
        alias TEXT NOT NULL,
        note TEXT
      )
    ''');
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_sa_char ON special_addressing(character_id)');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS character_tag (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id TEXT NOT NULL REFERENCES character_profile(id),
        tag TEXT NOT NULL
      )
    ''');
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_ct_char ON character_tag(character_id)');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS character_taboo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id TEXT NOT NULL REFERENCES character_profile(id),
        taboo TEXT NOT NULL
      )
    ''');
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_ctab_char ON character_taboo(character_id)');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS character_memory_hook (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id TEXT NOT NULL REFERENCES character_profile(id),
        hook TEXT NOT NULL
      )
    ''');
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_cmh_char ON character_memory_hook(character_id)');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS timeline (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        crychic_status TEXT,
        mygo_status TEXT,
        avemujica_status TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS timeline_character_state (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timeline_id TEXT NOT NULL REFERENCES timeline(id),
        character_id TEXT NOT NULL REFERENCES character_profile(id),
        state_description TEXT NOT NULL,
        personality_adjust TEXT,
        speech_adjust TEXT,
        UNIQUE(timeline_id, character_id)
      )
    ''');
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_tcs_tl ON timeline_character_state(timeline_id)');
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_tcs_char ON timeline_character_state(character_id)');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS dialogue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id TEXT NOT NULL REFERENCES character_profile(id),
        text TEXT NOT NULL,
        source TEXT,
        context TEXT,
        action TEXT,
        target_id TEXT REFERENCES character_profile(id),
        target_name TEXT
      )
    ''');
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_d_char ON dialogue(character_id)');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS chat_message (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timeline_id TEXT NOT NULL REFERENCES timeline(id),
        character_id TEXT REFERENCES character_profile(id),
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_cm_timeline ON chat_message(timeline_id)');
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_cm_char ON chat_message(character_id)');
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_cm_created ON chat_message(created_at)');

    await batch.commit(noResult: true);
  }

  // ==================== Prompt 模块查询 ====================

  /// 查询指定时间线下所有角色的基础信息。
  Future<List<CharacterProfile>> findCharactersByTimeline(
      String timelineId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT cp.id, cp.name_cn, cp.name_jp, cp.name_en,
             cp.band_id, cp.school, cp.role, cp.instrument,
             cp.stage_name, cp.summary
      FROM character_profile cp
      JOIN timeline_character_state tcs ON cp.id = tcs.character_id
      WHERE tcs.timeline_id = ?
    ''', [timelineId]);
    return rows.map((r) => CharacterProfile.fromMap(r)).toList();
  }

  /// 查询某角色在某时间线下的状态。
  Future<TimelineCharacterState?> findTimelineState(
      String timelineId, String characterId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT id, timeline_id, character_id,
             state_description, personality_adjust, speech_adjust
      FROM timeline_character_state
      WHERE timeline_id = ? AND character_id = ?
    ''', [timelineId, characterId]);
    if (rows.isEmpty) return null;
    return TimelineCharacterState.fromMap(rows.first);
  }

  /// 查询某角色的全部性格标签，按 sort_order 升序。
  Future<List<PersonalityTrait>> findPersonalityTraits(
      String characterId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT id, character_id, trait, sort_order
      FROM personality_trait
      WHERE character_id = ?
      ORDER BY sort_order
    ''', [characterId]);
    return rows.map((r) => PersonalityTrait.fromMap(r)).toList();
  }

  /// 查询某角色的说话语气。
  Future<SpeechStyle?> findSpeechStyle(String characterId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT id, character_id, description
      FROM speech_style
      WHERE character_id = ?
    ''', [characterId]);
    if (rows.isEmpty) return null;
    return SpeechStyle.fromMap(rows.first);
  }

  /// 查询某角色的行为细节，按 sort_order 升序。
  Future<List<CharacterDetail>> findCharacterDetails(
      String characterId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT id, character_id, detail, sort_order
      FROM character_detail
      WHERE character_id = ?
      ORDER BY sort_order
    ''', [characterId]);
    return rows.map((r) => CharacterDetail.fromMap(r)).toList();
  }

  /// 查询某角色对其他角色的专属称呼。
  Future<List<SpecialAddressing>> findSpecialAddressings(
      String characterId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT id, character_id, target_name, alias, note
      FROM special_addressing
      WHERE character_id = ?
    ''', [characterId]);
    return rows.map((r) => SpecialAddressing.fromMap(r)).toList();
  }

  /// 查询时间线信息。
  Future<Timeline?> findTimelineById(String timelineId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT id, title, summary, crychic_status, mygo_status, avemujica_status
      FROM timeline
      WHERE id = ?
    ''', [timelineId]);
    if (rows.isEmpty) return null;
    return Timeline.fromMap(rows.first);
  }

  // ==================== 聊天消息 CRUD ====================

  /// 保存一条聊天消息到数据库。
  Future<int> insertChatMessage({
    required String timelineId,
    String? characterId,
    required String role,
    required String content,
  }) async {
    final db = await database;
    return await db.insert('chat_message', {
      'timeline_id': timelineId,
      'character_id': characterId,
      'role': role,
      'content': content,
    });
  }

  /// 查询指定时间线的聊天历史。
  Future<List<ChatMessage>> findChatHistory(
    String timelineId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT id, timeline_id, character_id, role, content, created_at
      FROM chat_message
      WHERE timeline_id = ?
      ORDER BY created_at ASC
      LIMIT ? OFFSET ?
    ''', [timelineId, limit, offset]);
    return rows.map((r) => ChatMessage.fromDbMap(r)).toList();
  }

  /// 检查 character_profile 表是否已有数据（用于判断是否需导入 JSON）。
  Future<bool> hasData() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM character_profile');
    return (result.first['cnt'] as int) > 0;
  }
}
