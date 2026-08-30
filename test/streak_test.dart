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

  group('streakMilestoneLabel', () {
    test('節目ちょうどの日はお祝いを添える', () {
      expect(streakMilestoneLabel(3), '三日つづきました');
      expect(streakMilestoneLabel(7), '1週間つづきました');
      expect(streakMilestoneLabel(30), '1か月つづきました');
      expect(streakMilestoneLabel(100), '100日つづきました');
      expect(streakMilestoneLabel(365), '1年つづきました');
    });

    test('節目でない日は非表示(空文字)', () {
      expect(streakMilestoneLabel(2), '');
      expect(streakMilestoneLabel(6), '');
      expect(streakMilestoneLabel(8), '');
      expect(streakMilestoneLabel(31), '');
    });

    test('0日以下も非表示(空文字)', () {
      expect(streakMilestoneLabel(0), '');
      expect(streakMilestoneLabel(-1), '');
    });
  });

  group('longestStreakDays', () {
    DateTime d(int y, int m, int day) => DateTime(y, m, day);

    test('日記が無いと 0', () {
      expect(longestStreakDays(const []), 0);
    });

    test('全期間で最も長い連続を返す', () {
      final dates = [
        // 4日連続の固まり(最長)
        d(2026, 1, 1), d(2026, 1, 2), d(2026, 1, 3), d(2026, 1, 4),
        // 離れた2日連続
        d(2026, 3, 10), d(2026, 3, 11),
        // 単発
        d(2026, 5, 1),
      ];
      expect(longestStreakDays(dates), 4);
    });

    test('順不同でも正しく数える', () {
      final dates = [d(2026, 2, 3), d(2026, 2, 1), d(2026, 2, 2)];
      expect(longestStreakDays(dates), 3);
    });

    test('時刻違い・重複は1日として扱う', () {
      final dates = [
        DateTime(2026, 2, 1, 8),
        DateTime(2026, 2, 1, 23),
        DateTime(2026, 2, 2, 0, 30),
      ];
      expect(longestStreakDays(dates), 2);
    });

    test('月をまたぐ連続も途切れず数える', () {
      final dates = [d(2026, 1, 30), d(2026, 1, 31), d(2026, 2, 1)];
      expect(longestStreakDays(dates), 3);
    });

    test('1件だけなら 1', () {
      expect(longestStreakDays([d(2026, 4, 4)]), 1);
    });
  });

  group('longestStreakLabel', () {
    test('2日以上の実績で再開をそっと促す', () {
      expect(longestStreakLabel(2), 'これまでの最長は2日。またここから。');
      expect(longestStreakLabel(30), 'これまでの最長は30日。またここから。');
    });

    test('0日・1日は非表示(空文字)', () {
      expect(longestStreakLabel(0), '');
      expect(longestStreakLabel(1), '');
      expect(longestStreakLabel(-3), '');
    });
  });
}
