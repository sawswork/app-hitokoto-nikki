import 'package:flutter_test/flutter_test.dart';
import 'package:hitokoto_nikki/src/logic/search_label.dart';

void main() {
  group('searchResultCountLabel', () {
    test('件数をそのまま添える', () {
      expect(searchResultCountLabel(1), '1件見つかりました');
      expect(searchResultCountLabel(12), '12件見つかりました');
    });

    test('0件でも文言は組み立てる(表示可否は呼び出し側の責務)', () {
      expect(searchResultCountLabel(0), '0件見つかりました');
    });
  });

  group('searchEmptyLabel', () {
    test('探した語を添える', () {
      expect(searchEmptyLabel('桜'), '「桜」に一致する日記はありません');
    });

    test('前後の空白は取り除いて語を添える', () {
      expect(searchEmptyLabel('  雨  '), '「雨」に一致する日記はありません');
    });

    test('空(空白のみ)なら一般的な文言を返す', () {
      expect(searchEmptyLabel(''), '見つかりませんでした');
      expect(searchEmptyLabel('   '), '見つかりませんでした');
    });
  });
}
