import 'package:flutter/material.dart';

import '../utils/date_key.dart';

/// 1か月分のカレンダーグリッド。日記のある日は [hasEntry] で色づける。
///
/// 外部の table_calendar 等に頼らず、依存を増やさずに主役の画面を作る。
class MonthCalendar extends StatelessWidget {
  final DateTime month; // その月の任意の日
  final bool Function(DateTime day) hasEntry;
  final void Function(DateTime day) onTapDay;

  const MonthCalendar({
    super.key,
    required this.month,
    required this.hasEntry,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // 日曜=0 の並びにする(Dart の weekday は 月=1..日=7)。
    final leadingBlanks = first.weekday % 7;
    final today = dayStart(DateTime.now());

    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(month.year, month.month, d);
      cells.add(_DayCell(
        day: day,
        filled: hasEntry(day),
        isToday: isSameDay(day, today),
        onTap: () => onTapDay(day),
      ));
    }

    const weekdayLabels = ['日', '月', '火', '水', '木', '金', '土'];
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    weekdayLabels[i],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: i == 0
                          ? theme.colorScheme.error
                          : (i == 6
                              ? theme.colorScheme.primary
                              : theme.disabledColor),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool filled;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.filled,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = filled ? scheme.primary : Colors.transparent;
    final fg = filled ? scheme.onPrimary : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isToday && !filled
              ? BorderSide(color: scheme.primary, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: theme.textTheme.bodyMedium!.copyWith(
                color: fg,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              ),
              child: Text('${day.day}'),
            ),
          ),
        ),
      ),
    );
  }
}
