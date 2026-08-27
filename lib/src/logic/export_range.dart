import '../models/diary_entry.dart';
import '../repository/diary_repository.dart';

/// 書き出しの対象期間。UI の選択肢とロジックを一致させるために enum で持つ。
enum ExportRange {
  /// これまでの全部。
  all,

  /// 基準日と同じ年・月のエントリだけ。
  thisMonth,

  /// 基準日と同じ年のエントリだけ。
  thisYear,
}

extension ExportRangeLabel on ExportRange {
  /// 画面に出す短いラベル(やさしい日本語)。
  String get label => switch (this) {
        ExportRange.all => '全期間',
        ExportRange.thisMonth => '今月',
        ExportRange.thisYear => '今年',
      };
}

/// [entries] のうち [range] に含まれるものだけを返す。
///
/// [now] を「今」の基準日にする(テストで固定できるよう引数にしている)。
/// 判定は日付のローカル年月日だけを見る(時刻は無視)。
List<DiaryEntry> filterEntriesByRange(
  Iterable<DiaryEntry> entries,
  ExportRange range,
  DateTime now,
) {
  bool inRange(DiaryEntry e) => switch (range) {
        ExportRange.all => true,
        ExportRange.thisMonth =>
          e.date.year == now.year && e.date.month == now.month,
        ExportRange.thisYear => e.date.year == now.year,
      };
  return entries.where(inRange).toList();
}

/// エントリ群を書き出しテキストへ整形する(新しい日付順)。
///
/// 1エントリを「日付キー + 改行 + 本文」で表し、エントリ間は空行で区切る。
/// リポジトリの exportAsText と同じ体裁にそろえている。
String formatEntriesAsText(Iterable<DiaryEntry> entries) {
  final list = sortByDateDesc(entries);
  return list.map((e) => '${e.key}\n${e.text}').join('\n\n');
}

/// 書き出しテキストの先頭に付ける見出し1行。
///
/// アプリ名・対象期間・件数を「ひとこと日記(全期間・12件)」の形で表す。
/// バックアップ先(メモ・メール等)で中身が一目で分かるようにするため。
String exportHeaderLine(ExportRange range, int count) =>
    'ひとこと日記(${range.label}・$count件)';

/// エントリ群を見出し付きの書き出しテキストへ組み立てる。
///
/// 先頭に [exportHeaderLine]、空行を挟んで [formatEntriesAsText] の本文を置く。
/// 空のときは空文字を返す(呼び出し側の「日記がありません」表示を保つため)。
String buildExportText(Iterable<DiaryEntry> entries, ExportRange range) {
  final list = sortByDateDesc(entries);
  if (list.isEmpty) return '';
  return '${exportHeaderLine(range, list.length)}\n\n${formatEntriesAsText(list)}';
}
