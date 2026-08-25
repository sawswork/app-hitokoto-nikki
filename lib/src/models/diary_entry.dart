import '../utils/date_key.dart';

/// 1日分の日記。1日=1エントリで、[date] の年月日が一意キーになる。
class DiaryEntry {
  /// その日(時刻は 0:00 に正規化して保持)。
  final DateTime date;

  /// 本文(1行〜複数行)。
  final String text;

  /// 最終更新時刻。
  final DateTime updatedAt;

  DiaryEntry({
    required DateTime date,
    required this.text,
    required this.updatedAt,
  }) : date = dayStart(date);

  /// この日記の一意キー(`yyyy-MM-dd`)。
  String get key => dateKey(date);

  DiaryEntry copyWith({String? text, DateTime? updatedAt}) => DiaryEntry(
        date: date,
        text: text ?? this.text,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'date': key,
        'text': text,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        date: parseDateKey(json['date'] as String),
        text: json['text'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      other is DiaryEntry &&
      other.key == key &&
      other.text == text &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(key, text, updatedAt);

  @override
  String toString() => 'DiaryEntry($key, "${text.length}文字")';
}
