import 'dart:convert';
import 'dart:io';

import '../models/diary_entry.dart';
import '../utils/date_key.dart';
import 'diary_repository.dart';

/// 端末内のアプリ専用ディレクトリに JSON ファイルとして日記を永続化する実装。
///
/// オフライン完結。ネットワーク通信は行わない。読み書きの起点となる
/// [file] を差し替え可能にしてテストできるようにする。
class JsonDiaryRepository implements DiaryRepository {
  final File file;

  /// メモリ上のキャッシュ(`dateKey` -> エントリ)。初回に読み込む。
  Map<String, DiaryEntry>? _cache;

  JsonDiaryRepository(this.file);

  bool _isBlank(String text) => text.trim().isEmpty;

  Future<Map<String, DiaryEntry>> _ensureLoaded() async {
    final cache = _cache;
    if (cache != null) return cache;
    final loaded = <String, DiaryEntry>{};
    if (await file.exists()) {
      final raw = await file.readAsString();
      if (raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        final list = (decoded is Map && decoded['entries'] is List)
            ? decoded['entries'] as List
            : (decoded is List ? decoded : const []);
        for (final item in list) {
          final e = DiaryEntry.fromJson(Map<String, dynamic>.from(item as Map));
          loaded[e.key] = e;
        }
      }
    }
    _cache = loaded;
    return loaded;
  }

  Future<void> _flush() async {
    final cache = _cache ?? {};
    final entries = sortByDateDesc(cache.values).map((e) => e.toJson()).toList();
    final payload = jsonEncode({'version': 1, 'entries': entries});
    await file.parent.create(recursive: true);
    await file.writeAsString(payload, flush: true);
  }

  @override
  Future<List<DiaryEntry>> loadAll() async =>
      sortByDateDesc((await _ensureLoaded()).values);

  @override
  Future<DiaryEntry?> get(DateTime date) async =>
      (await _ensureLoaded())[dateKey(date)];

  @override
  Future<void> put(DiaryEntry entry) async {
    final cache = await _ensureLoaded();
    if (_isBlank(entry.text)) {
      cache.remove(entry.key);
    } else {
      cache[entry.key] = entry;
    }
    await _flush();
  }

  @override
  Future<void> delete(DateTime date) async {
    final cache = await _ensureLoaded();
    cache.remove(dateKey(date));
    await _flush();
  }

  @override
  Future<int> count() async => (await _ensureLoaded()).length;

  @override
  Future<String> exportAsText() async {
    final entries = sortByDateDesc((await _ensureLoaded()).values);
    return entries.map((e) => '${e.key}\n${e.text}').join('\n\n');
  }

  @override
  Future<List<DiaryEntry>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final cache = await _ensureLoaded();
    return sortByDateDesc(cache.values.where((e) => e.text.contains(q)));
  }
}
