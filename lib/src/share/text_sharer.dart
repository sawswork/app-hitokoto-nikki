import 'package:share_plus/share_plus.dart';

/// テキストを OS の共有シートへ渡すための抽象。
///
/// 共有シートはメール・メモなど「端末の機能」へテキストを渡すだけで、
/// このアプリ自身はネットワーク通信を行わない(=オフライン方針は維持)。
/// テストではネイティブ呼び出しを避けるため、フェイクに差し替える。
abstract class TextSharer {
  Future<void> share(String text, {String? subject});
}

/// share_plus を使った本実装。実機/シミュレータで共有シートを開く。
class SharePlusSharer implements TextSharer {
  const SharePlusSharer();

  @override
  Future<void> share(String text, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(text: text, subject: subject),
    );
  }
}
