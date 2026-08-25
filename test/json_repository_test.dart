import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hitokoto_nikki/src/models/diary_entry.dart';
import 'package:hitokoto_nikki/src/repository/json_diary_repository.dart';

DiaryEntry entry(DateTime date, String text) =>
    DiaryEntry(date: date, text: text, updatedAt: date);

void main() {
  group('JsonDiaryRepository(永続化)', () {
    late Directory tmp;
    late File file;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('nikki_test');
      file = File('${tmp.path}/diary.json');
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    test('保存した内容が別インスタンス(再起動相当)で読める', () async {
      final repo1 = JsonDiaryRepository(file);
      await repo1.put(entry(DateTime(2026, 8, 25), '今日のこと'));
      await repo1.put(entry(DateTime(2026, 8, 26), '明日のこと'));

      // 同じファイルを新しいインスタンスで開く = アプリ再起動に相当。
      final repo2 = JsonDiaryRepository(file);
      expect(await repo2.count(), 2);
      expect((await repo2.get(DateTime(2026, 8, 25)))?.text, '今日のこと');
      final all = await repo2.loadAll();
      expect(all.first.date, DateTime(2026, 8, 26)); // 新しい順
    });

    test('削除が永続化される', () async {
      final repo1 = JsonDiaryRepository(file);
      await repo1.put(entry(DateTime(2026, 8, 25), '消す予定'));
      await repo1.delete(DateTime(2026, 8, 25));

      final repo2 = JsonDiaryRepository(file);
      expect(await repo2.get(DateTime(2026, 8, 25)), isNull);
    });

    test('ファイルが無ければ空として扱う', () async {
      final repo = JsonDiaryRepository(File('${tmp.path}/none.json'));
      expect(await repo.count(), 0);
      expect(await repo.loadAll(), isEmpty);
    });

    test('search と exportAsText が動く', () async {
      final repo = JsonDiaryRepository(file);
      await repo.put(entry(DateTime(2026, 8, 25), 'ラーメン'));
      await repo.put(entry(DateTime(2026, 8, 26), 'カレー'));
      expect((await repo.search('ラー')).length, 1);
      final text = await repo.exportAsText();
      expect(text.contains('ラーメン'), isTrue);
      expect(text.contains('カレー'), isTrue);
    });
  });
}
