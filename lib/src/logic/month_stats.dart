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
