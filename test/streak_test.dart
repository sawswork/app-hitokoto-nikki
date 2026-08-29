import 'package:flutter_test/flutter_test.dart';
import 'package:hitokoto_nikki/src/logic/streak.dart';

void main() {
  group('currentStreakDays', () {
    final today = DateTime(2026, 8, 29);

    DateTime daysAgo(int n) => today.subtract(Duration(days: n));

    test('日記が無いと 0', () {
      expect(currentStreakDays(const [], today), 0);
    });

    test('今日から連続していれば日数を数える', () {
      final dates = [daysAgo(0), daysAgo(1), daysAgo(2)];
      expect(currentStreakDays(dates, today), 3);
    });

    test('今日はまだでも昨日までの連続は途切れない', () {
      final dates = [daysAgo(1), daysAgo(2)];
      expect(currentStreakDays(dates, today), 2);
    });

    test('途中で抜けたらそこで止まる', () {
      // 今日・昨日はあるが、一昨日が抜けている。
      final dates = [daysAgo(0), daysAgo(1), daysAgo(3), daysAgo(4)];
      expect(currentStreakDays(dates, today), 2);
    });

    test('今日も昨日も無ければ 0(連続は切れている)', () {
      final dates = [daysAgo(2), daysAgo(3)];
      expect(currentStreakDays(dates, today), 0);
    });

    test('時刻が違っても同じ日として扱う', () {
      final dates = [
        DateTime(2026, 8, 29, 23, 59),
        DateTime(2026, 8, 28, 0, 1),
      ];
      expect(currentStreakDays(dates, today), 2);
    });

    test('同じ日の重複は二重に数えない', () {
      final dates = [daysAgo(0), daysAgo(0), daysAgo(1)];
      expect(currentStreakDays(dates, today), 2);
    });
  });

  group('streakLabel', () {
    test('2日以上でそっと励ます', () {
      expect(streakLabel(2), '2日つづけて書いています');
      expect(streakLabel(10), '10日つづけて書いています');
    });

    test('0日・1日は非表示(空文字)', () {
      expect(streakLabel(0), '');
      expect(streakLabel(1), '');
    });
  });
}
