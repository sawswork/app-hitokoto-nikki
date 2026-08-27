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
}
