/// 日付の扱いを一箇所に集約するユーティリティ。
///
/// このアプリは「1日1エントリ」を前提とするため、時刻を落として
/// ローカルの年月日だけを鍵(キー)として使う。UTC 変換で日付が
/// ずれないよう、常にローカルの year/month/day から鍵を作る。
library;

/// [date] の時刻を落とし、その日の 0:00(ローカル)を返す。
DateTime dayStart(DateTime date) => DateTime(date.year, date.month, date.day);

/// `yyyy-MM-dd` 形式の日付キー文字列を返す。
///
/// エントリの一意キーであり、保存・検索・比較の基準になる。
String dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// `yyyy-MM-dd` 形式の文字列から [DateTime](その日の 0:00)を復元する。
DateTime parseDateKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) {
    throw FormatException('不正な日付キーです: $key');
  }
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final d = int.parse(parts[2]);
  return DateTime(y, m, d);
}

/// 2つの日付が同じ「日」かどうか(時刻は無視)。
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
