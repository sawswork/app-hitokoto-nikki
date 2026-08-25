import 'package:flutter_test/flutter_test.dart';
import 'package:hitokoto_nikki/src/logic/free_limit.dart';
import 'package:hitokoto_nikki/src/purchase/purchase_store.dart';

void main() {
  group('canAddNewEntry', () {
    test('無料: 上限未満なら追加できる', () {
      expect(canAddNewEntry(0, isPremium: false), isTrue);
      expect(canAddNewEntry(freeEntryLimit - 1, isPremium: false), isTrue);
    });

    test('無料: 上限ちょうどは追加できない', () {
      expect(canAddNewEntry(freeEntryLimit, isPremium: false), isFalse);
    });

    test('無料: 上限超過も追加できない', () {
      expect(canAddNewEntry(freeEntryLimit + 5, isPremium: false), isFalse);
    });

    test('プレミアム: 何件でも追加できる', () {
      expect(canAddNewEntry(freeEntryLimit, isPremium: true), isTrue);
      expect(canAddNewEntry(1000, isPremium: true), isTrue);
    });
  });

  group('remainingFreeEntries', () {
    test('無料: 残り件数を返す', () {
      expect(remainingFreeEntries(0, isPremium: false), freeEntryLimit);
      expect(remainingFreeEntries(28, isPremium: false), 2);
    });

    test('無料: 超過しても 0 未満にならない', () {
      expect(remainingFreeEntries(freeEntryLimit + 3, isPremium: false), 0);
    });

    test('プレミアム: null(無制限)', () {
      expect(remainingFreeEntries(10, isPremium: true), isNull);
    });
  });

  group('FakePurchaseStore', () {
    test('初期は無料、buy でプレミアムになる', () async {
      final store = FakePurchaseStore();
      expect(store.isPremium, isFalse);
      await store.buy();
      expect(store.isPremium, isTrue);
    });

    test('notifyListeners が呼ばれる', () async {
      final store = FakePurchaseStore();
      var notified = 0;
      store.addListener(() => notified++);
      await store.buy();
      expect(notified, greaterThan(0));
    });
  });
}
