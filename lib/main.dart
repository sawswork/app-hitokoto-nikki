import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'src/purchase/purchase_store.dart';
import 'src/repository/json_diary_repository.dart';
import 'src/screens/calendar_screen.dart';
import 'src/state/app_state.dart';
import 'src/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja');

  final dir = await getApplicationDocumentsDirectory();
  final repository = JsonDiaryRepository(File('${dir.path}/diary.json'));
  // 実際のストア連携は Mac・審査が必要なため、まずはフェイクで組み立てる。
  final purchase = FakePurchaseStore();

  final state = AppState(repository: repository, purchase: purchase);
  await state.load();

  runApp(HitokotoNikkiApp(state: state));
}

class HitokotoNikkiApp extends StatelessWidget {
  final AppState state;
  const HitokotoNikkiApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'ひとこと日記',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const CalendarScreen(),
      ),
    );
  }
}
