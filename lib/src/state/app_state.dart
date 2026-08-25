import 'package:flutter/widgets.dart';

import '../logic/free_limit.dart';
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

  Future<List<DiaryEntry>> search(String query) => repository.search(query);

  Future<String> exportAsText() => repository.exportAsText();

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
