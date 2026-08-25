import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:hitokoto_nikki/src/models/diary_entry.dart';
import 'package:hitokoto_nikki/src/purchase/purchase_store.dart';
import 'package:hitokoto_nikki/src/repository/diary_repository.dart';
import 'package:hitokoto_nikki/src/screens/calendar_screen.dart';
import 'package:hitokoto_nikki/src/state/app_state.dart';
import 'package:hitokoto_nikki/src/theme/app_theme.dart';

Future<AppState> pumpApp(
  WidgetTester tester, {
  Iterable<DiaryEntry>? initial,
  bool premium = false,
}) async {
  final state = AppState(
    repository: InMemoryDiaryRepository(initial),
    purchase: FakePurchaseStore(isPremium: premium),
  );
  await state.load();
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const CalendarScreen(),
      ),
    ),
  );
  return state;
}

void main() {
  setUpAll(() async => initializeDateFormatting('ja'));

  testWidgets('カレンダー画面が表示される', (tester) async {
    await pumpApp(tester);
    expect(find.text('今日を書く'), findsOneWidget);
    // 曜日ヘッダー。
    expect(find.text('日'), findsWidgets);
    expect(find.text('月'), findsWidgets);
  });

  testWidgets('日記が無い月ではやさしい空状態の案内が出る', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('この月はまだ真っ白'), findsOneWidget);
  });

  testWidgets('その月に日記があれば空状態の案内は消える', (tester) async {
    await pumpApp(
      tester,
      initial: [
        DiaryEntry(
          date: DateTime.now(),
          text: '今日の一言',
          updatedAt: DateTime.now(),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('この月はまだ真っ白'), findsNothing);
  });

  testWidgets('日をタップ → 書いて戻ると保存される', (tester) async {
    final state = await pumpApp(tester);

    // 「今日を書く」からエディタへ。
    await tester.tap(find.text('今日を書く'));
    await tester.pumpAndSettle();
    expect(find.text('日記'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'テスト日記');
    // 戻る(自動保存)。
    final backButton = find.byTooltip('Back');
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(state.entryCount, 1);
    expect(state.hasEntry(DateTime.now()), isTrue);
  });

  testWidgets('無料枠が満杯だと新規作成で購入導線が出る', (tester) async {
    final initial = List.generate(
      30,
      (i) => DiaryEntry(
        date: DateTime(2020, 1, 1).add(Duration(days: i)),
        text: '$i',
        updatedAt: DateTime(2020, 1, 1),
      ),
    );
    await pumpApp(tester, initial: initial);

    await tester.tap(find.text('今日を書く'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '31件目');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // 購入ボトムシートの文言が表示される。
    expect(find.text('無制限に書くには'), findsOneWidget);
  });
}
