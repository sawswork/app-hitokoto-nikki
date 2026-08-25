import '../models/diary_entry.dart';
import '../utils/date_key.dart';

/// 日記の保存・取得を抽象化する。UI はこのインターフェースにのみ依存し、
/// 実体(メモリ / JSON ファイル / 将来の sqlite など)は差し替え可能にする。
abstract class DiaryRepository {
  /// 全エントリを新しい日付順(降順)で返す。
  Future<List<DiaryEntry>> loadAll();

  /// 指定日のエントリ。無ければ null。
  Future<DiaryEntry?> get(DateTime date);

  /// 保存(既存日は上書き)。本文が空文字/空白のみなら削除と同義。
  Future<void> put(DiaryEntry entry);

  /// 指定日を削除。
  Future<void> delete(DateTime date);

  /// エントリ総数。無料枠の判定に使う。
  Future<int> count();

  /// 全日記を1つのテキストにまとめて返す(書き出し・バックアップ用)。
  Future<String> exportAsText();

  /// [query] を含むエントリを新しい日付順で返す(部分文字列一致)。
  /// 空クエリなら空リストを返す。
  Future<List<DiaryEntry>> search(String query);
}

/// 与えられたエントリ集合を新しい日付順(降順)に並べ替えて返す共通処理。
List<DiaryEntry> sortByDateDesc(Iterable<DiaryEntry> entries) {
  final list = entries.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return list;
}

/// テスト・初期実装用のインメモリ実装。永続化はしない。
class InMemoryDiaryRepository implements DiaryRepository {
  final Map<String, DiaryEntry> _store = {};

  InMemoryDiaryRepository([Iterable<DiaryEntry>? initial]) {
    if (initial != null) {
      for (final e in initial) {
        _store[e.key] = e;
      }
    }
  }

  bool _isBlank(String text) => text.trim().isEmpty;

  @override
  Future<List<DiaryEntry>> loadAll() async => sortByDateDesc(_store.values);

  @override
  Future<DiaryEntry?> get(DateTime date) async => _store[dateKey(date)];

  @override
  Future<void> put(DiaryEntry entry) async {
    if (_isBlank(entry.text)) {
      _store.remove(entry.key);
    } else {
      _store[entry.key] = entry;
    }
  }

  @override
  Future<void> delete(DateTime date) async {
    _store.remove(dateKey(date));
  }

  @override
  Future<int> count() async => _store.length;

  @override
  Future<String> exportAsText() async {
    final entries = sortByDateDesc(_store.values);
    return entries.map((e) => '${e.key}\n${e.text}').join('\n\n');
  }

  @override
  Future<List<DiaryEntry>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final matched =
        _store.values.where((e) => e.text.contains(q));
    return sortByDateDesc(matched);
  }
}
