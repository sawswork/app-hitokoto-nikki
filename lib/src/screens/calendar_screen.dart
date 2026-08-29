import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/streak.dart';
import '../state/app_state.dart';
import '../utils/date_key.dart';
import '../widgets/month_calendar.dart';
import 'editor_screen.dart';
import 'export_screen.dart';
import 'paywall.dart';
import 'search_screen.dart';

/// ホーム。書いた日が色づくカレンダーが主役。
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() => _month = DateTime(now.year, now.month, 1));
  }

  /// 表示中の月に日記が1件でもあるか。空の月のやさしい案内に使う。
  bool _monthHasEntry(AppState state) {
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    for (var d = 1; d <= days; d++) {
      if (state.hasEntry(DateTime(_month.year, _month.month, d))) return true;
    }
    return false;
  }

  Future<void> _openDay(DateTime day) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditorScreen(date: day)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _onMenu(String value) async {
    switch (value) {
      case 'export':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ExportScreen()),
        );
      case 'premium':
        await showPaywall(context);
      case 'about':
        if (mounted) _showAbout();
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'ひとこと日記(仮)',
      applicationLegalese:
          'データはこの端末の中だけに保存されます。サーバーには送信しません。',
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('1日1行書くだけで、カレンダーに思い出がたまっていきます。'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = AppScope.of(context);
    final monthLabel = DateFormat('yyyy年 M月', 'ja').format(_month);

    return Scaffold(
      appBar: AppBar(
        title: Text(monthLabel),
        actions: [
          IconButton(
            tooltip: '今日',
            icon: const Icon(Icons.today_outlined),
            onPressed: _goToday,
          ),
          IconButton(
            tooltip: '探す',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: _onMenu,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export', child: Text('テキスト書き出し')),
              if (!state.isPremium)
                const PopupMenuItem(value: 'premium', child: Text('無制限にする(買い切り)')),
              const PopupMenuItem(value: 'about', child: Text('このアプリについて')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _shiftMonth(-1),
                      ),
                      Text(monthLabel, style: theme.textTheme.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _shiftMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MonthCalendar(
                    month: _month,
                    hasEntry: state.hasEntry,
                    onTapDay: _openDay,
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _monthHasEntry(state)
                        ? const SizedBox.shrink()
                        : const _EmptyMonthHint(),
                  ),
                  const SizedBox(height: 8),
                  _FooterInfo(state: state),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDay(dayStart(DateTime.now())),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('今日を書く'),
      ),
    );
  }
}

/// 表示中の月に日記が無いときの、やさしい空状態の案内。
class _EmptyMonthHint extends StatelessWidget {
  const _EmptyMonthHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          Icons.wb_sunny_outlined,
          size: 28,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 8),
        Text(
          'この月はまだ真っ白。\n今日をひとことから始めましょう。',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }
}

class _FooterInfo extends StatelessWidget {
  final AppState state;
  const _FooterInfo({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = state.remainingFree;
    final text = state.isPremium
        ? '無制限で書けます'
        : remaining == null
            ? ''
            : '無料で残り $remaining 日分';
    final streak = streakLabel(state.currentStreak());
    return Column(
      children: [
        if (streak.isNotEmpty) ...[
          Text(
            streak,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          text,
          style:
              theme.textTheme.labelMedium?.copyWith(color: theme.disabledColor),
        ),
      ],
    );
  }
}
