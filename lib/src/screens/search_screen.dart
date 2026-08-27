import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/search_label.dart';
import '../models/diary_entry.dart';
import '../state/app_state.dart';
import '../widgets/highlighted_text.dart';
import 'editor_screen.dart';

/// 完全一致(部分文字列一致)で日記を探す画面。
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<DiaryEntry> _results = [];
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final results = await AppScope.of(context).search(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searched = query.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '言葉で探す',
            border: InputBorder.none,
          ),
          onChanged: _runSearch,
        ),
      ),
      body: !_searched
          ? Center(
              child: Text(
                '書いた言葉を探せます',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.disabledColor),
              ),
            )
          : _results.isEmpty
              ? Center(
                  child: Text(
                    '見つかりませんでした',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.disabledColor),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        searchResultCountLabel(_results.length),
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final e = _results[i];
                          final label = DateFormat('yyyy年 M月 d日 (E)', 'ja')
                              .format(e.date);
                          return ListTile(
                            title: HighlightedText(
                              e.text,
                              query: _controller.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(label),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => EditorScreen(date: e.date),
                                ),
                              );
                              if (mounted) _runSearch(_controller.text);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
