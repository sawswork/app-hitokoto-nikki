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

/// 連続記録の節目(そっとお祝いを添える日数)と、その一言。
///
/// ちょうどこの日数に届いた日だけ表示する短い労い。仰々しくならないよう
/// 数を絞り、素直な言葉にとどめる。
const Map<int, String> _milestones = {
  3: '三日つづきました',
  7: '1週間つづきました',
  14: '2週間つづきました',
  30: '1か月つづきました',
  50: '50日つづきました',
  100: '100日つづきました',
  200: '200日つづきました',
  365: '1年つづきました',
};

/// 連続日数がちょうど節目のとき、そっと添えるお祝いの一言を返す。
///
/// 節目ちょうどの日だけ返し、それ以外(節目でない日・0日以下)は空文字
/// =非表示。毎日出し続けず「届いた日」に一度だけそっと出す。
String streakMilestoneLabel(int days) => _milestones[days] ?? '';

/// これまでで一番長く続いた日数(最長連続記録)を数える純粋関数。
///
/// [entryDates] は日記のある日(時刻は無視、重複可)。全期間を通して、
/// 途切れずに続いた最も長い連続の日数を返す。1件も無ければ 0。
/// 「今の連続」と違い基準日は不要で、過去のどこであっても構わない。
int longestStreakDays(Iterable<DateTime> entryDates) {
  final keys = entryDates.map(dateKey).toSet();
  if (keys.isEmpty) return 0;

  var longest = 0;
  for (final key in keys) {
    final day = parseDateKey(key);
    // 各連続の先頭(前日が無い日)からだけ数え、二度手間を避ける。
    if (keys.contains(dateKey(day.subtract(const Duration(days: 1))))) {
      continue;
    }
    var count = 0;
    var cursor = day;
    while (keys.contains(dateKey(cursor))) {
      count++;
      cursor = cursor.add(const Duration(days: 1));
    }
    if (count > longest) longest = count;
  }
  return longest;
}

/// 連続が途切れているとき、これまでの最長記録をそっと示す一言を返す。
///
/// 連続が2日以上あった実績([days] >= 2)のときだけ返し、それ未満なら
/// 空文字=非表示。今の連続が続いている間は別の見出しを出すので、
/// この文言は「途切れた日」に再開をそっと促すためだけに使う。
String longestStreakLabel(int days) {
  if (days < 2) return '';
  return 'これまでの最長は$days日。またここから。';
}
