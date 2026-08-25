import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';

/// 全日記をテキストとして書き出す(バックアップ)画面。
///
/// オフライン方針のため、まずは端末内で選択・コピーできる形にする。
/// 共有シート連携は今後の拡張。
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('テキスト書き出し'),
        actions: [
          IconButton(
            tooltip: 'コピー',
            icon: const Icon(Icons.copy_all),
            onPressed: () async {
              final text = await state.exportAsText();
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('コピーしました')),
                );
              }
            },
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
