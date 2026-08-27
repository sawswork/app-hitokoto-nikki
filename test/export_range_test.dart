import 'package:flutter_test/flutter_test.dart';

import 'package:hitokoto_nikki/src/logic/export_range.dart';
import 'package:hitokoto_nikki/src/models/diary_entry.dart';

DiaryEntry _entry(DateTime date, String text) =>
    DiaryEntry(date: date, text: text, updatedAt: date);

void main() {
  final entries = [
    _entry(DateTime(2024, 12, 31), '大晦日'),
    _entry(DateTime(2025, 1, 15), '正月あけ'),
    _entry(DateTime(2025, 6, 10), '梅雨入り'),
    _entry(DateTime(2025, 6, 20), '夏至前'),
  ];
  final now = DateTime(2025, 6, 25, 9, 30);

  group('filterEntriesByRange', () {
    test('全期間はすべて残す', () {
      final result = filterEntriesByRange(entries, ExportRange.all, now);
      expect(result.length, entries.length);
    });

    test('今年は基準日と同じ年だけ', () {
      final result = filterEntriesByRange(entries, ExportRange.thisYear, now);
      expect(result.map((e) => e.key), everyElement(startsWith('2025-')));
      expect(result.length, 3);
    });

    test('今月は基準日と同じ年月だけ', () {
      final result = filterEntriesByRange(entries, ExportRange.thisMonth, now);
      expect(result.map((e) => e.key), everyElement(startsWith('2025-06-')));
      expect(result.length, 2);
    });

    test('該当が無ければ空', () {
      final other = DateTime(2030, 3, 1);
      expect(filterEntriesByRange(entries, ExportRange.thisYear, other), isEmpty);
      expect(
        filterEntriesByRange(entries, ExportRange.thisMonth, other),
        isEmpty,
      );
    });
  });

  group('formatEntriesAsText', () {
    test('新しい順で日付キーと本文が空行区切りで並ぶ', () {
      final text = formatEntriesAsText(entries);
      final blocks = text.split('\n\n');
      expect(blocks.length, entries.length);
      // 先頭は最新日(2025-06-20)。
      expect(blocks.first, '2025-06-20\n夏至前');
      // 末尾は最古日(2024-12-31)。
      expect(blocks.last, '2024-12-31\n大晦日');
    });

    test('空なら空文字', () {
      expect(formatEntriesAsText(const []), '');
    });
  });

  group('ExportRangeLabel', () {
    test('日本語ラベルが付く', () {
      expect(ExportRange.all.label, '全期間');
      expect(ExportRange.thisMonth.label, '今月');
      expect(ExportRange.thisYear.label, '今年');
    });
  });
}
