import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hitokoto_nikki/src/widgets/highlighted_text.dart';

void main() {
  const base = TextStyle(fontSize: 14);
  const hi = TextStyle(fontWeight: FontWeight.w700);

  List<String> texts(List<TextSpan> spans) =>
      spans.map((s) => s.text ?? '').toList();

  group('highlightSpans', () {
    test('空クエリなら本文全体を1スパンで返す', () {
      final spans = highlightSpans('桜が咲いた', '  ',
          baseStyle: base, highlightStyle: hi);
      expect(spans, hasLength(1));
      expect(spans.single.text, '桜が咲いた');
      expect(spans.single.style, base);
    });

    test('一致部分だけが強調スタイルになる', () {
      final spans =
          highlightSpans('桜が咲いた', '咲', baseStyle: base, highlightStyle: hi);
      expect(texts(spans), ['桜が', '咲', 'いた']);
      expect(spans[1].style, hi);
      expect(spans[0].style, base);
      expect(spans[2].style, base);
    });

    test('複数の一致をすべて強調する', () {
      final spans = highlightSpans('あかあかとあか', 'あか',
          baseStyle: base, highlightStyle: hi);
      // あか / と / あか  → 先頭・末尾が強調、中間3文字目以降を分割
      final joined = texts(spans).join();
      expect(joined, 'あかあかとあか');
      final highlighted =
          spans.where((s) => s.style == hi).map((s) => s.text).toList();
      expect(highlighted, ['あか', 'あか', 'あか']);
    });

    test('大文字小文字を区別せず、強調部分は原文の表記を保つ', () {
      final spans =
          highlightSpans('Hello WORLD', 'world', baseStyle: base, highlightStyle: hi);
      expect(texts(spans), ['Hello ', 'WORLD']);
      expect(spans[1].style, hi);
    });

    test('一致が無ければ本文全体を1スパンで返す', () {
      final spans =
          highlightSpans('桜が咲いた', '雪', baseStyle: base, highlightStyle: hi);
      expect(spans, hasLength(1));
      expect(spans.single.text, '桜が咲いた');
    });
  });
}
