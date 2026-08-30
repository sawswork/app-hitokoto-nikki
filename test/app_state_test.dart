import 'package:flutter_test/flutter_test.dart';
import 'package:hitokoto_nikki/src/logic/free_limit.dart';
import 'package:hitokoto_nikki/src/models/diary_entry.dart';
import 'package:hitokoto_nikki/src/purchase/purchase_store.dart';
import 'package:hitokoto_nikki/src/repository/diary_repository.dart';
import 'package:hitokoto_nikki/src/state/app_state.dart';

AppState buildState({
  Iterable<DiaryEntry>? initial,
  bool premium = false,
}) {
  return AppState(
    repository: InMemoryDiaryRepository(initial),
    purchase: FakePurchaseStore(isPremium: premium),
  );
}

DiaryEntry entry(DateTime date, String text) =>
    DiaryEntry(date: date, text: text, updatedAt: date);

void main() {
  group('AppState', () {
    test('load 後に件数・エントリを参照できる', () async {
      final state = buildState(initial: [entry(DateTime(2026, 8, 25), 'やあ')]);
      await state.load();
      expect(state.isLoaded, isTrue);
      expect(state.entryCount, 1);
      expect(state.hasEntry(DateTime(2026, 8, 25)), isTrue);
      expect(state.entryOf(DateTime(2026, 8, 25))?.text, 'やあ');
    });

    test('save で新規保存すると色づく(hasEntry)', () async {
      final state = buildState();
      await state.load();
      final ok = await state.save(DateTime(2026, 8, 25), '一日一行');
      expect(ok, isTrue);
      expect(state.hasEntry(DateTime(2026, 8, 25)), isTrue);
      expect(state.entryCount, 1);
    });

    test('空文字の save は削除扱い', () async {
      final state = buildState(initial: [entry(DateTime(2026, 8, 25), '消す')]);
      await state.load();
      await state.save(DateTime(2026, 8, 25), '   ');
      expect(state.hasEntry(DateTime(2026, 8, 25)), isFalse);
      expect(state.entryCount, 0);
    });

    test('無料枠が満杯だと新規 save は拒否される(false)', () async {
      final initial = List.generate(
        freeEntryLimit,
        (i) => entry(DateTime(2026, 1, 1).add(Duration(days: i)), '$i'),
      );
      final state = buildState(initial: initial);
      await state.load();
      expect(state.entryCount, freeEntryLimit);

      final ok = await state.save(DateTime(2027, 1, 1), 'あふれる分');
      expect(ok, isFalse);
      expect(state.hasEntry(DateTime(2027, 1, 1)), isFalse);
    });

    test('満杯でも既存日の編集は許可される', () async {
      final initial = List.generate(
        freeEntryLimit,
        (i) => entry(DateTime(2026, 1, 1).add(Duration(days: i)), '$i'),
      );
      final state = buildState(initial: initial);
      await state.load();
      final existing = DateTime(2026, 1, 1);
      final ok = await state.save(existing, '書き直し');
      expect(ok, isTrue);
      expect(state.entryOf(existing)?.text, '書き直し');
    });

    test('プレミアムなら上限を超えて保存できる', () async {
      final initial = List.generate(
        freeEntryLimit,
        (i) => entry(DateTime(2026, 1, 1).add(Duration(days: i)), '$i'),
      );
      final state = buildState(initial: initial, premium: true);
      await state.load();
      final ok = await state.save(DateTime(2027, 1, 1), '無制限');
      expect(ok, isTrue);
      expect(state.entryCount, freeEntryLimit + 1);
    });

    test('buyPremium で isPremium が true になり通知される', () async {
      final state = buildState();
      await state.load();
      var notified = 0;
      state.addListener(() => notified++);
      await state.buyPremium();
      expect(state.isPremium, isTrue);
      expect(notified, greaterThan(0));
    });

    test('currentStreak は基準日から連続して書いた日数を返す', () async {
      final today = DateTime(2026, 8, 29);
      final state = buildState(initial: [
        entry(today, 'きょう'),
        entry(today.subtract(const Duration(days: 1)), 'きのう'),
        entry(today.subtract(const Duration(days: 2)), 'おととい'),
        // ここで一日抜けているので、連続はここで止まる。
        entry(today.subtract(const Duration(days: 4)), 'とび日'),
      ]);
      await state.load();
      expect(state.currentStreak(today), 3);
    });

    test('longestStreak は全期間で最も長い連続日数を返す', () async {
      final state = buildState(initial: [
        // 3日連続(最長)
        entry(DateTime(2026, 1, 1), 'a'),
        entry(DateTime(2026, 1, 2), 'b'),
        entry(DateTime(2026, 1, 3), 'c'),
        // 離れた2日連続
        entry(DateTime(2026, 3, 10), 'd'),
        entry(DateTime(2026, 3, 11), 'e'),
      ]);
      await state.load();
      expect(state.longestStreak(), 3);
    });

    test('remainingFree は残り件数、プレミアムは null', () async {
      final state = buildState(initial: [entry(DateTime(2026, 8, 25), 'a')]);
      await state.load();
      expect(state.remainingFree, freeEntryLimit - 1);
      await state.buyPremium();
      expect(state.remainingFree, isNull);
    });
  });
}
