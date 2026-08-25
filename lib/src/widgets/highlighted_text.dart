import 'package:flutter/material.dart';

/// [text] のうち [query] に一致する部分を [highlightStyle] で強調するスパン列を作る。
///
/// 検索結果で「どこが一致したか」を見せるための純粋関数。ネットワークや端末機能に
/// 依存しないため、そのままユニットテストできる。大文字小文字は区別しない。
/// [query] が空、または一致が無い場合は本文全体を1スパンで返す。
List<TextSpan> highlightSpans(
  String text,
  String query, {
  TextStyle? baseStyle,
  required TextStyle highlightStyle,
}) {
  final q = query.trim();
  if (q.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  final lowerText = text.toLowerCase();
  final lowerQuery = q.toLowerCase();

  final spans = <TextSpan>[];
  var start = 0;
  while (start < text.length) {
    final hit = lowerText.indexOf(lowerQuery, start);
    if (hit < 0) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
      break;
    }
    if (hit > start) {
      spans.add(TextSpan(text: text.substring(start, hit), style: baseStyle));
    }
    final end = hit + lowerQuery.length;
    // 強調部分は元の本文(大文字小文字そのまま)を使う。
    spans.add(TextSpan(text: text.substring(hit, end), style: highlightStyle));
    start = end;
  }

  return spans;
}

/// 一致部分を淡い下線・太字で強調して表示するテキスト。
class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    super.key,
    required this.query,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final highlight = base.copyWith(
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.primary,
    );
    return Text.rich(
      TextSpan(
        children: highlightSpans(
          text,
          query,
          baseStyle: base,
          highlightStyle: highlight,
        ),
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
