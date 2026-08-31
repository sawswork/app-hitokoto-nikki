import '../utils/date_key.dart';

/// 指定した年月に日記が何日ぶんあったかを数える純粋関数。
///
/// [entryDates] は日記のある日(時刻は無視、同じ日の重複は1日と数える)。
/// [year]・[month] の月に属する日だけを対象に、書いた日数を返す。
int entriesInMonth(Iterable<DateTime> entryDates, int year, int month) {
  final keys = <String>{};
  for (final date in entryDates) {
    if (date.year == year && date.month == month) {
      keys.add(dateKey(date));
    }
  }
  return keys.length;
}

/// その月に何日書いたかを、そっと添えるやさしい一言にする純粋関数。
///
/// 1日以上書いた月だけ「この月は◯日書きました」を返す。0日のときは
/// 空文字=非表示(空の月には別の案内を出すので、ここでは何も言わない)。
String monthSummaryLabel(int count) {
  if (count < 1) return '';
  return 'この月は$count日書きました';
}

/// 指定した年月の総日数(28〜31)を返す純粋関数。皆勤の判定に使う。
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// その月のすべての日に日記があった(皆勤)かを判定する純粋関数。
///
/// [count] はその月に書いた日数、[totalDays] はその月の総日数。
/// 1日も書いていない月や、日数の食い違いは皆勤とみなさない。
bool isPerfectMonth(int count, int totalDays) {
  if (count < 1 || totalDays < 1) return false;
  return count >= totalDays;
}

/// 皆勤の月にそっと添える、ねぎらいの一言(純粋関数)。
String perfectMonthLabel() => 'この月は毎日書けました';
