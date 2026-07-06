import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

/// JSON → SQLite 数据加载器。
///
/// 在应用首次启动时将 assets/data/ 下的 4 个 JSON 文件
/// 导入 SQLite 数据库，完全对应原 DatabaseInitializer.java 的逻辑。
///
/// 导入顺序：world.json → character.json → timeline.json → example.json
class DataLoader {
  final Database _db;

  /// 构造加载器，绑定目标数据库。
  DataLoader(this._db);

  /// 检查并执行数据初始化。
  /// 若 character_profile 表已有数据则跳过。
  Future<void> initIfNeeded() async {
    final result =
        await _db.rawQuery('SELECT COUNT(*) as cnt FROM character_profile');
    if ((result.first['cnt'] as int) > 0) {
      return;
    }

    await _importWorld();
    await _importCharacters();
    await _importTimelines();
    await _importDialogues();
  }

  /// 导入 world.json：写入 school、location、band 三张表。
  Future<void> _importWorld() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/world.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;

    final batch = _db.batch();

    // schools
    final schools = data['schools'] as List<dynamic>?;
    if (schools != null) {
      for (final s in schools) {
        final m = s as Map<String, dynamic>;
        batch.rawInsert(
          'INSERT INTO school (name, notes) VALUES (?, ?)',
          [m['name'], m['notes'] ?? ''],
        );
      }
    }

    // locations
    final locations = data['key_locations'] as List<dynamic>?;
    if (locations != null) {
      for (final l in locations) {
        final m = l as Map<String, dynamic>;
        batch.rawInsert(
          'INSERT INTO location (name, type, notes) VALUES (?, ?, ?)',
          [m['name'], m['type'] ?? '', m['notes'] ?? ''],
        );
      }
    }

    // bands from world.json
    final bands = data['bands'] as List<dynamic>?;
    if (bands != null) {
      for (final b in bands) {
        final m = b as Map<String, dynamic>;
        batch.rawInsert(
          'INSERT OR IGNORE INTO band (id, name, name_cn, status, notes) '
          'VALUES (?, ?, ?, ?, ?)',
          [m['id'], m['name'], m['name'], m['status'] ?? '', m['notes'] ?? ''],
        );
      }
    }

    await batch.commit(noResult: true);
  }

  /// 导入 character.json：写入 band、character_profile、personality_trait、
  /// speech_style、character_detail、special_addressing、character_tag、
  /// character_taboo、character_memory_hook 共 9 张表。
  Future<void> _importCharacters() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/character.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;

    final batch = _db.batch();

    // bands from character.json
    final bands = data['bands'] as List<dynamic>?;
    if (bands != null) {
      for (final b in bands) {
        final m = b as Map<String, dynamic>;
        batch.rawInsert(
          'INSERT OR IGNORE INTO band (id, name, name_cn) VALUES (?, ?, ?)',
          [m['id'], m['name'], m['name']],
        );
      }
    }

    // CRYCHIC band
    batch.rawInsert(
      'INSERT OR IGNORE INTO band (id, name, name_cn, status) '
      'VALUES (?, ?, ?, ?)',
      ['crychic', 'CRYCHIC', 'CRYCHIC', 'disbanded'],
    );

    final characters = data['characters'] as List<dynamic>?;
    if (characters == null) {
      await batch.commit(noResult: true);
      return;
    }

    const bandMap = {
      'MyGO!!!!!': 'mygo',
      'Ave Mujica': 'avemujica',
      'CRYCHIC': 'crychic',
    };

    for (final ch in characters) {
      final m = ch as Map<String, dynamic>;
      final id = m['id'] as String;
      final bandId = bandMap[m['band']] ?? '';

      // character_profile
      batch.rawInsert(
        'INSERT INTO character_profile '
        '(id, name_cn, name_jp, name_en, band_id, school, role, instrument, '
        'stage_name, summary) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          id,
          m['name_cn'],
          m['name_jp'],
          m['name_en'],
          bandId,
          m['school'] ?? '',
          m['role'] ?? '',
          m['instrument'] ?? '',
          m['stage_name'],
          m['summary'] ?? '',
        ],
      );

      // personality traits
      final traits = m['personality'] as List<dynamic>?;
      if (traits != null) {
        for (var i = 0; i < traits.length; i++) {
          batch.rawInsert(
            'INSERT INTO personality_trait (character_id, trait, sort_order) '
            'VALUES (?, ?, ?)',
            [id, traits[i], i],
          );
        }
      }

      // speech style
      final speechStyle = m['speech_style'] as String?;
      if (speechStyle != null && speechStyle.isNotEmpty) {
        batch.rawInsert(
          'INSERT INTO speech_style (character_id, description) VALUES (?, ?)',
          [id, speechStyle],
        );
      }

      // details
      final details = m['details'] as List<dynamic>?;
      if (details != null) {
        for (var i = 0; i < details.length; i++) {
          batch.rawInsert(
            'INSERT INTO character_detail (character_id, detail, sort_order) '
            'VALUES (?, ?, ?)',
            [id, details[i], i],
          );
        }
      }

      // special addressing
      final addrs = m['special_addressing'] as List<dynamic>?;
      if (addrs != null) {
        for (final a in addrs) {
          final am = a as Map<String, dynamic>;
          batch.rawInsert(
            'INSERT INTO special_addressing '
            '(character_id, target_name, alias, note) VALUES (?, ?, ?, ?)',
            [id, am['target'], am['alias'], am['note'] ?? ''],
          );
        }
      }

      // tags
      final tags = m['tags'] as List<dynamic>?;
      if (tags != null) {
        for (final tag in tags) {
          batch.rawInsert(
            'INSERT INTO character_tag (character_id, tag) VALUES (?, ?)',
            [id, tag],
          );
        }
      }

      // taboos
      final taboos = m['taboos'] as List<dynamic>?;
      if (taboos != null) {
        for (final taboo in taboos) {
          batch.rawInsert(
            'INSERT INTO character_taboo (character_id, taboo) VALUES (?, ?)',
            [id, taboo],
          );
        }
      }

      // memory hooks
      final hooks = m['memory_hooks'] as List<dynamic>?;
      if (hooks != null) {
        for (final hook in hooks) {
          batch.rawInsert(
            'INSERT INTO character_memory_hook (character_id, hook) '
            'VALUES (?, ?)',
            [id, hook],
          );
        }
      }
    }

    await batch.commit(noResult: true);
  }

  /// 导入 timeline.json：写入 timeline 和 timeline_character_state 两张表。
  Future<void> _importTimelines() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/timeline.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final nodes = data['nodes'] as List<dynamic>?;
    if (nodes == null) return;

    final batch = _db.batch();

    for (final node in nodes) {
      final n = node as Map<String, dynamic>;
      final tlId = n['id'] as String;
      final bandStatus = n['band_status'] as Map<String, dynamic>?;

      batch.rawInsert(
        'INSERT INTO timeline (id, title, summary, crychic_status, '
        'mygo_status, avemujica_status) VALUES (?, ?, ?, ?, ?, ?)',
        [
          tlId,
          n['title'],
          n['summary'],
          bandStatus?['crychic'] ?? '',
          bandStatus?['mygo'] ?? '',
          bandStatus?['avemujica'] ?? '',
        ],
      );

      final states = n['character_states'] as Map<String, dynamic>?;
      if (states != null) {
        for (final entry in states.entries) {
          batch.rawInsert(
            'INSERT INTO timeline_character_state '
            '(timeline_id, character_id, state_description) '
            'VALUES (?, ?, ?)',
            [tlId, entry.key, entry.value],
          );
        }
      }
    }

    await batch.commit(noResult: true);
  }

  /// 导入 example.json：写入 dialogue 表。
  Future<void> _importDialogues() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/example.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final dialogues =
        data['dialogues'] as Map<String, dynamic>?;
    if (dialogues == null) return;

    final batch = _db.batch();

    for (final entry in dialogues.entries) {
      final charId = entry.key;
      final lines = entry.value as List<dynamic>;
      for (final d in lines) {
        final dm = d as Map<String, dynamic>;
        batch.rawInsert(
          'INSERT INTO dialogue '
          '(character_id, text, source, context, action, target_id, target_name) '
          'VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            charId,
            dm['text'],
            dm['source'] ?? '',
            dm['context'] ?? '',
            dm['action'] ?? '',
            dm['target'],
            dm['target_name'],
          ],
        );
      }
    }

    await batch.commit(noResult: true);
  }
}
