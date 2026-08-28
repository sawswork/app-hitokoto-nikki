/// 検索結果の件数見出しの文言を組み立てる純粋関数。
///
/// 画面から切り出してテストしやすくしている。日本語では単複の区別がないため、
/// 件数をそのまま添えるだけでよい(0件はここでは扱わず、呼び出し側で
/// 「見つかりませんでした」を出す)。
String searchResultCountLabel(int count) => '$count件見つかりました';

/// 検索結果が0件のときの見出し文言を組み立てる純粋関数。
///
/// 探した語を添えて「何に一致しなかったか」を分かりやすくする。
/// 語が空(前後の空白のみ含む)のときは語を添えずに一般的な文言を返す。
String searchEmptyLabel(String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return '見つかりませんでした';
  return '「$trimmed」に一致する日記はありません';
}
