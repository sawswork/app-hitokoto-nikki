import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';
import '../utils/date_key.dart';
import 'paywall.dart';

/// 1日分の日記を書く画面。離脱時に自動保存する。
class EditorScreen extends StatefulWidget {
  final DateTime date;
  const EditorScreen({super.key, required this.date});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late DateTime _date;
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = dayStart(widget.date);
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncControllerToDate();
  }

  void _syncControllerToDate() {
    final entry = AppScope.of(context).entryOf(_date);
    _controller.text = entry?.text ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    _saving = true;
    final state = AppScope.of(context);
    final ok = await state.save(_date, _controller.text);
    _saving = false;
    if (!ok && mounted) {
      // 無料枠を超えた新規保存。書いた内容は残したまま購入導線へ。
      await showPaywall(context);
    }
  }

  Future<void> _moveDay(int deltaDays) async {
    await _save();
    if (!mounted) return;
    setState(() {
      _date = dayStart(_date.add(Duration(days: deltaDays)));
      _syncControllerToDate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = dayStart(DateTime.now());
    final isFuture = _date.isAfter(today);
    final dateLabel = DateFormat('yyyy年 M月 d日 (E)', 'ja').format(_date);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _save();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('日記'),
          actions: [
            IconButton(
              tooltip: '前の日',
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _moveDay(-1),
            ),
            IconButton(
              tooltip: '次の日',
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _moveDay(1),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
                ),
                if (isFuture)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'これからの日',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    style: theme.textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: '今日をひとことで。',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
