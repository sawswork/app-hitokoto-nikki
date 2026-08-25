import 'package:flutter/material.dart';

/// アプリの配色・タイポグラフィ。落ち着いた和のトーンで「おしゃれ」を狙う。
///
/// ベース: 生成りの白 / 墨に近いダークグレー。アクセント: 藍〜青磁系の一色。
/// 既製部品そのままの雰囲気を消すため ColorScheme / TextTheme を調整する。
class AppTheme {
  AppTheme._();

  /// アクセント(藍)。書いた日のカレンダーを彩る主色。
  static const Color _seed = Color(0xFF3A6B8C);

  /// 生成りの白(ライトの背景)。
  static const Color _washi = Color(0xFFF7F4EC);

  /// 墨(ダークの背景)。
  static const Color _sumi = Color(0xFF1B1E22);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ).copyWith(surface: _washi);
    return _base(scheme, _washi);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(surface: _sumi);
    return _base(scheme, _sumi);
  }

  static ThemeData _base(ColorScheme scheme, Color scaffoldBg) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        // 日付の数字を主役に大きく見せる。
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.5),
      ),
    );
  }
}
