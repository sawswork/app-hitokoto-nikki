import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../share/text_sharer.dart';
import '../state/app_state.dart';

/// 全日記をテキストとして書き出す(バックアップ)画面。
///
/// 端末内で選択・コピーできるほか、共有シートで他アプリ(メモ・メール等)へ
/// 送れる。共有シートは端末機能に渡すだけで、アプリ自身は通信しない。
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key, this.sharer = const SharePlusSharer()});

  /// 共有処理。テストではフェイクに差し替えるため注入可能にしている。
  final TextSharer sharer;

  Future<void> _copy(BuildContext context, AppState state) async {
    final text = await state.exportAsText();
    if (!context.mounted) return;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('まだ日記がありません')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('コピーしました')),
    );
  }

  Future<void> _share(BuildContext context, AppState state) async {
    final text = await state.exportAsText();
    if (!context.mounted) return;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('まだ日記がありません')),
      );
      return;
    }
    await sharer.share(text, subject: 'ひとこと日記のバックアップ');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('テキスト書き出し'),
        actions: [
          IconButton(
            tooltip: '共有',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _share(context, state),
          ),
          IconButton(
            tooltip: 'コピー',
            icon: const Icon(Icons.copy_all),
            onPressed: () => _copy(context, state),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: state.exportAsText(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final text = snapshot.data!;
          if (text.trim().isEmpty) {
            return const Center(child: Text('まだ日記がありません'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SelectableText(text),
          );
        },
      ),
    );
  }
}
