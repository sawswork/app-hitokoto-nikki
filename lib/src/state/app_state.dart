import 'package:flutter/widgets.dart';

import '../logic/export_range.dart';
import '../logic/free_limit.dart';
import '../logic/month_stats.dart';
import '../logic/streak.dart';
import '../models/diary_entry.dart';
import '../purchase/purchase_store.dart';
import '../repository/diary_repository.dart';
import '../utils/date_key.dart';

/// アプリ全体の状態。日記の読み書きと購入状態を束ね、変更を通知する。
///
/// UI はこの [AppState] を [AppScope] 経由で参照し、[ListenableBuilder] などで
/// 再描画する。過剰な状態管理ライブラリは使わない方針。
class AppState extends ChangeNotifier {
  final DiaryRepository repository;
  final PurchaseStore purchase;

  /// 日付キー -> エントリのキャッシュ。UI 描画を軽くするため保持する。
  final Map<String, DiaryEntry> _entries = {};

  bool _loaded = false;
  bool get isLoaded => _loaded;

  AppState({required this.repository, required this.purchase}) {
    purchase.addListener(notifyListeners);
  }

  @override
  void dispose() {
    purchase.removeListener(notifyListeners);
    super.dispose();
  }

  /// 起動時に全エントリを読み込む。
  Future<void> load() async {
    final all = await repository.loadAll();
    _entries
      ..clear()
      ..addEntries(all.map((e) => MapEntry(e.key, e)));
    _loaded = true;
    notifyListeners();
  }

  bool get isPremium => purchase.isPremium;

  int get entryCount => _entries.length;

  int? get remainingFree =>
      remainingFreeEntries(entryCount, isPremium: isPremium);

  /// 指定日のエントリ(無ければ null)。
  DiaryEntry? entryOf(DateTime date) => _entries[dateKey(date)];

  /// 指定日に日記があるか。カレンダーの色づけに使う。
  bool hasEntry(DateTime date) => _entries.containsKey(dateKey(date));

  /// 新規エントリ(まだ存在しない日)を作成できるか。既存日の編集は常に可。
  bool canWrite(DateTime date) {
    if (hasEntry(date)) return true;
    return canAddNewEntry(entryCount, isPremium: isPremium);
  }

  /// 日記を保存する。本文が空なら削除扱い。
  ///
  /// 新規で無料枠を超える場合は保存せず false を返す。
  Future<bool> save(DateTime date, String text) async {
    final key = dateKey(date);
    final isNew = !_entries.containsKey(key);
    final blank = text.trim().isEmpty;

    if (isNew && !blank && !canWrite(date)) {
      return false;
    }

    final entry = DiaryEntry(
      date: date,
      text: text,
      // updatedAt は端末ローカルの現在時刻。テストでは save を直接使わない。
      updatedAt: DateTime.now(),
    );
    await repository.put(entry);

    if (blank) {
      _entries.remove(key);
    } else {
      _entries[key] = entry;
    }
    notifyListeners();
    return true;
  }

  /// 全エントリを新しい順で返す(検索・書き出しの土台)。
  List<DiaryEntry> get allEntries => sortByDateDesc(_entries.values);

  /// 連続で書いている日数([now] は基準日。省略時は端末の現在時刻)。
  int currentStreak([DateTime? now]) =>
      currentStreakDays(_entries.values.map((e) => e.date), now ?? DateTime.now());

  /// これまでで一番長く続いた日数(最長連続記録)。基準日は不要。
  int longestStreak() =>
      longestStreakDays(_entries.values.map((e) => e.date));

  /// 指定した年月に書いた日数(その月のカレンダーの手応えに使う)。
  int monthEntryCount(int year, int month) =>
      entriesInMonth(_entries.values.map((e) => e.date), year, month);

  Future<List<DiaryEntry>> search(String query) => repository.search(query);

  /// 日記を1つのテキストにまとめて返す(書き出し・バックアップ用)。
  ///
  /// [range] で対象期間を絞れる(既定は全期間)。どの期間もキャッシュ
  /// (allEntries と同じ土台)から組み立て、先頭に期間・件数の見出しを付ける。
  /// [now] は「今月/今年」の基準日で、省略時は端末の現在時刻。
  Future<String> exportAsText({
    ExportRange range = ExportRange.all,
    DateTime? now,
  }) {
    final base = now ?? DateTime.now();
    final target = range == ExportRange.all
        ? _entries.values
        : filterEntriesByRange(_entries.values, range, base);
    return Future.value(buildExportText(target, range));
  }

  Future<void> buyPremium() => purchase.buy();

  Future<void> restorePurchase() => purchase.restore();
}

/// [AppState] をウィジェットツリーに供給する InheritedWidget。
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope?.notifier != null, 'AppScope が見つかりません');
    return scope!.notifier!;
  }
}
