import 'package:flutter_test/flutter_test.dart';
import 'package:hitokoto_nikki/src/models/diary_entry.dart';
import 'package:hitokoto_nikki/src/repository/diary_repository.dart';

DiaryEntry entry(DateTime date, String text) =>
    DiaryEntry(date: date, text: text, updatedAt: date);

void main() {
  group('InMemoryDiaryRepository', () {
    late InMemoryDiaryRepository repo;

    setUp(() => repo = InMemoryDiaryRepository());

    test('put して get で取り出せる', () async {
      final e = entry(DateTime(2026, 8, 25), 'よい一日だった');
      await repo.put(e);
      final got = await repo.get(DateTime(2026, 8, 25, 20));
      expect(got?.text, 'よい一日だった');
    });

    test('同じ日の put は上書きになる(件数は増えない)', () async {
      await repo.put(entry(DateTime(2026, 8, 25), '朝'));
      await repo.put(entry(DateTime(2026, 8, 25), '夜'));
      expect(await repo.count(), 1);
      expect((await repo.get(DateTime(2026, 8, 25)))?.text, '夜');
    });

    test('空白のみの本文を put すると削除扱い', () async {
      await repo.put(entry(DateTime(2026, 8, 25), 'あとで消す'));
      await repo.put(entry(DateTime(2026, 8, 25), '   '));
      expect(await repo.get(DateTime(2026, 8, 25)), isNull);
      expect(await repo.count(), 0);
    });

    test('delete で消える', () async {
      await repo.put(entry(DateTime(2026, 8, 25), 'メモ'));
      await repo.delete(DateTime(2026, 8, 25));
      expect(await repo.get(DateTime(2026, 8, 25)), isNull);
    });

    test('loadAll は新しい日付順(降順)', () async {
      await repo.put(entry(DateTime(2026, 8, 20), '古い'));
      await repo.put(entry(DateTime(2026, 8, 25), '新しい'));
      await repo.put(entry(DateTime(2026, 8, 22), '中間'));
      final all = await repo.loadAll();
      expect(all.map((e) => e.text), ['新しい', '中間', '古い']);
    });

    test('未来の日付にも保存できる', () async {
      final future = DateTime(2030, 1, 1);
      await repo.put(entry(future, '未来の予定'));
      expect((await repo.get(future))?.text, '未来の予定');
    });

    group('search(部分一致)', () {
      setUp(() async {
        await repo.put(entry(DateTime(2026, 8, 20), 'ラーメンを食べた'));
        await repo.put(entry(DateTime(2026, 8, 21), 'カレーを食べた'));
        await repo.put(entry(DateTime(2026, 8, 22), '散歩した'));
      });

      test('含む語で一致し、新しい順で返る', () async {
        final r = await repo.search('食べた');
        expect(r.map((e) => e.text), ['カレーを食べた', 'ラーメンを食べた']);
      });

      test('空クエリは空リスト', () async {
        expect(await repo.search(''), isEmpty);
        expect(await repo.search('   '), isEmpty);
      });

      test('一致なしは空リスト', () async {
        expect(await repo.search('寿司'), isEmpty);
      });
    });

    test('exportAsText に全エントリが含まれる', () async {
      await repo.put(entry(DateTime(2026, 8, 20), 'A'));
      await repo.put(entry(DateTime(2026, 8, 25), 'B'));
      final text = await repo.exportAsText();
      expect(text.contains('2026-08-20'), isTrue);
      expect(text.contains('A'), isTrue);
      expect(text.contains('2026-08-25'), isTrue);
      expect(text.contains('B'), isTrue);
    });

    test('初期データ付きで生成できる', () async {
      final r = InMemoryDiaryRepository([
        entry(DateTime(2026, 8, 25), '初期'),
      ]);
      expect(await r.count(), 1);
    });
  });

  group('DiaryEntry JSON', () {
    test('toJson/fromJson で往復できる', () {
      final e = entry(DateTime(2026, 8, 25, 12), 'テスト');
      final restored = DiaryEntry.fromJson(e.toJson());
      expect(restored.key, e.key);
      expect(restored.text, e.text);
    });
  });
}
