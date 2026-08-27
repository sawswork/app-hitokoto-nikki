import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/export_range.dart';
import '../share/text_sharer.dart';
import '../state/app_state.dart';

/// 全日記をテキストとして書き出す(バックアップ)画面。
///
/// 端末内で選択・コピーできるほか、共有シートで他アプリ(メモ・メール等)へ
/// 送れる。共有シートは端末機能に渡すだけで、アプリ自身は通信しない。
/// 対象期間(全期間 / 今年 / 今月)を選んで絞り込める。
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key, this.sharer = const SharePlusSharer()});

  /// 共有処理。テストではフェイクに差し替えるため注入可能にしている。
  final TextSharer sharer;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  ExportRange _range = ExportRange.all;

  /// 空のときの案内文。全期間なら「そもそも無い」、絞り込み時は「この期間に無い」。
  String get _emptyMessage =>
      _range == ExportRange.all ? 'まだ日記がありません' : 'この期間の日記はありません';

  Future<void> _copy(BuildContext context, AppState state) async {
    final text = await state.exportAsText(range: _range);
    if (!context.mounted) return;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_emptyMessage)),
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
    final text = await state.exportAsText(range: _range);
    if (!context.mounted) return;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_emptyMessage)),
      );
      return;
    }
    await widget.sharer.share(text, subject: 'ひとこと日記のバックアップ');
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
      body: Column(
        children: [
          _RangeSelector(
            value: _range,
            onChanged: (r) => setState(() => _range = r),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<String>(
              // 期間を変えるたびに読み直せるよう key に range を含める。
              key: ValueKey(_range),
              future: state.exportAsText(range: _range),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final text = snapshot.data!;
                if (text.trim().isEmpty) {
                  return Center(child: Text(_emptyMessage));
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: SelectableText(text),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 対象期間を選ぶ帯。横スクロールなしで収まる3択のチップ。
class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.value, required this.onChanged});

  final ExportRange value;
  final ValueChanged<ExportRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (final range in ExportRange.values) ...[
            ChoiceChip(
              label: Text(range.label),
              selected: value == range,
              onSelected: (_) => onChanged(range),
            ),
            if (range != ExportRange.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
