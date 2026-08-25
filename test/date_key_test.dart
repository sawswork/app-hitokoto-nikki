import 'package:flutter_test/flutter_test.dart';
import 'package:hitokoto_nikki/src/utils/date_key.dart';

void main() {
  group('dateKey', () {
    test('yyyy-MM-dd 形式でゼロ埋めされる', () {
      expect(dateKey(DateTime(2026, 1, 5)), '2026-01-05');
      expect(dateKey(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('時刻が違っても同じ日なら同じキー', () {
      expect(
        dateKey(DateTime(2026, 8, 25, 0, 0)),
        dateKey(DateTime(2026, 8, 25, 23, 59, 59)),
      );
    });

    test('うるう年 2/29 を扱える', () {
      expect(dateKey(DateTime(2024, 2, 29)), '2024-02-29');
    });
  });

  group('dayStart', () {
    test('時刻を 0:00 に落とす', () {
      final d = dayStart(DateTime(2026, 8, 25, 14, 30, 15));
      expect(d, DateTime(2026, 8, 25));
    });
  });

  group('parseDateKey', () {
    test('往復しても一致する', () {
      final d = DateTime(2026, 3, 7);
      expect(parseDateKey(dateKey(d)), d);
    });

    test('不正な形式は例外', () {
      expect(() => parseDateKey('2026/03/07'), throwsFormatException);
      expect(() => parseDateKey('2026-03'), throwsFormatException);
    });
  });

  group('isSameDay', () {
    test('同じ日は true(時刻無視)', () {
      expect(
        isSameDay(DateTime(2026, 8, 25, 1), DateTime(2026, 8, 25, 22)),
        isTrue,
      );
    });

    test('別の日は false', () {
      expect(isSameDay(DateTime(2026, 8, 25), DateTime(2026, 8, 26)), isFalse);
    });
  });
}
