import 'package:flutter_test/flutter_test.dart';
import 'package:hitokoto_nikki/src/logic/month_stats.dart';

void main() {
  group('entriesInMonth', () {
    test('日記が無いと 0', () {
      expect(entriesInMonth(const [], 2026, 8), 0);
    });

    test('その月の日だけ数える(前後の月は除く)', () {
      final dates = [
        DateTime(2026, 7, 31), // 前月
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 15),
        DateTime(2026, 8, 30),
        DateTime(2026, 9, 1), // 翌月
      ];
      expect(entriesInMonth(dates, 2026, 8), 3);
    });

    test('同じ日の重複は1日と数える(時刻は無視)', () {
      final dates = [
        DateTime(2026, 8, 10, 8, 0),
        DateTime(2026, 8, 10, 23, 59),
        DateTime(2026, 8, 11, 12, 0),
      ];
      expect(entriesInMonth(dates, 2026, 8), 2);
    });

    test('同じ月番号でも年が違えば数えない', () {
      final dates = [DateTime(2025, 8, 5), DateTime(2026, 8, 5)];
      expect(entriesInMonth(dates, 2026, 8), 1);
    });
  });

  group('monthSummaryLabel', () {
    test('0日は空文字(非表示)', () {
      expect(monthSummaryLabel(0), '');
      expect(monthSummaryLabel(-1), '');
    });

    test('1日以上は「この月は◯日書きました」', () {
      expect(monthSummaryLabel(1), 'この月は1日書きました');
      expect(monthSummaryLabel(12), 'この月は12日書きました');
    });
  });
}
