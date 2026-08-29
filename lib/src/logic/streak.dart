import '../utils/date_key.dart';

/// 「連続で書いている日数」を数える純粋関数。
///
/// [entryDates] は日記のある日(時刻は無視、重複可)。[today] を基準に
/// さかのぼって、途切れずに続いている日数を返す。
///
/// 今日まだ書いていなくても、昨日までの連続は途切れとみなさない
/// (書く前にホームを開いても記録が消えて見えないように)。
/// つまり数え始めは「今日に日記があれば今日、無ければ昨日」から。
int currentStreakDays(Iterable<DateTime> entryDates, DateTime today) {
  final keys = entryDates.map(dateKey).toSet();
  if (keys.isEmpty) return 0;

  final start = dayStart(today);
  // 起点: 今日に日記があれば今日、無ければ昨日から数える。
  var cursor = keys.contains(dateKey(start))
      ? start
      : start.subtract(const Duration(days: 1));

  var count = 0;
  while (keys.contains(dateKey(cursor))) {
    count++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return count;
}

/// 連続記録日数のやさしい見出し文言を組み立てる純粋関数。
///
/// 2日以上つづいたときだけ、そっと励ます一言を返す(1日や0日は
/// 「連続」と呼ぶほどではないので空文字=非表示)。
String streakLabel(int days) {
  if (days < 2) return '';
  return '$days日つづけて書いています';
}
