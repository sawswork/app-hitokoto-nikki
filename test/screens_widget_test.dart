import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:hitokoto_nikki/src/models/diary_entry.dart';
import 'package:hitokoto_nikki/src/purchase/purchase_store.dart';
import 'package:hitokoto_nikki/src/repository/diary_repository.dart';
import 'package:hitokoto_nikki/src/screens/export_screen.dart';
import 'package:hitokoto_nikki/src/screens/paywall.dart';
import 'package:hitokoto_nikki/src/screens/search_screen.dart';
import 'package:hitokoto_nikki/src/state/app_state.dart';
import 'package:hitokoto_nikki/src/theme/app_theme.dart';

/// 検索・書き出し画面を直接 pump するための共通ヘルパー。
Future<AppState> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Iterable<DiaryEntry>? initial,
}) async {
  final state = AppState(
    repository: InMemoryDiaryRepository(initial),
    purchase: FakePurchaseStore(),
  );
  await state.load();
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: screen,
      ),
    ),
  );
  return state;
}

DiaryEntry _entry(DateTime date, String text) =>
    DiaryEntry(date: date, text: text, updatedAt: date);

void main() {
  setUpAll(() async => initializeDateFormatting('ja'));

  group('検索画面', () {
    final sample = [
      _entry(DateTime(2024, 3, 1), '桜が咲いた'),
      _entry(DateTime(2024, 3, 5), '雨の一日'),
      _entry(DateTime(2024, 3, 9), '桜が散った'),
    ];

    testWidgets('最初は案内文だけが出る（結果なし）', (tester) async {
      await pumpScreen(tester, const SearchScreen(), initial: sample);
      expect(find.text('書いた言葉を探せます'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('語を入れると部分一致で新しい順に並ぶ', (tester) async {
      await pumpScreen(tester, const SearchScreen(), initial: sample);

      await tester.enterText(find.byType(TextField), '桜');
      await tester.pumpAndSettle();

      // 「桜」を含む2件が出て、無関係な1件は出ない。
      expect(find.text('桜が咲いた'), findsOneWidget);
      expect(find.text('桜が散った'), findsOneWidget);
      expect(find.text('雨の一日'), findsNothing);

      // 新しい順(3/9 が 3/1 より上)。
      final chiru = tester.getTopLeft(find.text('桜が散った'));
      final saita = tester.getTopLeft(find.text('桜が咲いた'));
      expect(chiru.dy, lessThan(saita.dy));
    });

    testWidgets('一致しない語は「見つかりませんでした」', (tester) async {
      await pumpScreen(tester, const SearchScreen(), initial: sample);

      await tester.enterText(find.byType(TextField), '雪');
      await tester.pumpAndSettle();

      expect(find.text('見つかりませんでした'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('検索結果から編集画面へ遷移できる', (tester) async {
      await pumpScreen(tester, const SearchScreen(), initial: sample);

      await tester.enterText(find.byType(TextField), '雨');
      await tester.pumpAndSettle();

      await tester.tap(find.text('雨の一日'));
      await tester.pumpAndSettle();

      // 編集画面のタイトルと日付ラベルが出る。
      expect(find.text('日記'), findsOneWidget);
      expect(find.textContaining('2024年'), findsOneWidget);
    });
  });

  group('書き出し画面', () {
    testWidgets('日記が無いと「まだ日記がありません」', (tester) async {
      await pumpScreen(tester, const ExportScreen());
      await tester.pumpAndSettle();
      expect(find.text('まだ日記がありません'), findsOneWidget);
    });

    testWidgets('全日記の本文が表示される', (tester) async {
      await pumpScreen(
        tester,
        const ExportScreen(),
        initial: [
          _entry(DateTime(2024, 1, 1), '元日の朝'),
          _entry(DateTime(2024, 1, 2), '初詣に行った'),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('元日の朝'), findsOneWidget);
      expect(find.textContaining('初詣に行った'), findsOneWidget);
    });

    testWidgets('コピーボタンでクリップボードに入り、通知が出る', (tester) async {
      // クリップボードのプラットフォーム呼び出しを捕まえる。
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await pumpScreen(
        tester,
        const ExportScreen(),
        initial: [_entry(DateTime(2024, 1, 1), '元日の朝')],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('コピー'));
      await tester.pumpAndSettle();

      expect(copied, contains('元日の朝'));
      expect(find.text('コピーしました'), findsOneWidget);
    });
  });

  group('購入導線(paywall)', () {
    // showPaywall を押せるボタンだけの簡易画面で検証する。
    Future<AppState> pumpPaywallHost(WidgetTester tester) async {
      final state = AppState(
        repository: InMemoryDiaryRepository(),
        purchase: FakePurchaseStore(),
      );
      await state.load();
      await tester.pumpWidget(
        AppScope(
          state: state,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => showPaywall(context),
                    child: const Text('開く'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return state;
    }

    testWidgets('誇張のない説明と2つのボタンが出る', (tester) async {
      await pumpPaywallHost(tester);
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.text('無制限に書くには'), findsOneWidget);
      expect(find.text('買い切りで購入(500円)'), findsOneWidget);
      expect(find.text('購入を復元(機種変更したとき)'), findsOneWidget);
      // 月額ではないことを明記している(誇張・誤認防止)。
      expect(find.textContaining('月額ではありません'), findsOneWidget);
    });

    testWidgets('購入するとプレミアムになりシートが閉じる', (tester) async {
      final state = await pumpPaywallHost(tester);
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('買い切りで購入(500円)'));
      await tester.pumpAndSettle();

      expect(state.isPremium, isTrue);
      // シートが閉じている。
      expect(find.text('無制限に書くには'), findsNothing);
    });

    testWidgets('復元しても購入前ならシートは開いたまま', (tester) async {
      final state = await pumpPaywallHost(tester);
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('購入を復元(機種変更したとき)'));
      await tester.pumpAndSettle();

      // フェイクでは復元しても購入状態にならないため、閉じない。
      expect(state.isPremium, isFalse);
      expect(find.text('無制限に書くには'), findsOneWidget);
    });
  });
}
