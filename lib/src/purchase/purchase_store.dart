import 'package:flutter/foundation.dart';

/// 買い切り(非消費型)課金の状態を抽象化する。
///
/// 実際のストア連携(in_app_purchase / StoreKit)は、プロダクトID登録や
/// App Store Connect 設定・審査など Mac・外部作業が必要なため、まずは
/// この抽象とフェイク実装で UI と制限ロジックを組み立てる。
/// オフライン方針のため、外部サーバーでのレシート検証は行わない。
abstract class PurchaseStore extends ChangeNotifier {
  /// プレミアム(無制限)が有効か。
  bool get isPremium;

  /// 購入処理を開始する。
  Future<void> buy();

  /// 過去の購入を復元する(機種変更後の引き継ぎ)。
  Future<void> restore();
}

/// テスト・開発用のフェイク。実際の課金は行わず、状態だけを保持する。
class FakePurchaseStore extends PurchaseStore {
  bool _isPremium = false;

  FakePurchaseStore({bool isPremium = false}) {
    _isPremium = isPremium;
  }

  @override
  bool get isPremium => _isPremium;

  @override
  Future<void> buy() async {
    _isPremium = true;
    notifyListeners();
  }

  @override
  Future<void> restore() async {
    // フェイクでは復元しても状態は変わらない(実装時に差し替え)。
    notifyListeners();
  }

  /// テスト用:購入状態を直接設定する。
  @visibleForTesting
  void setPremium(bool value) {
    _isPremium = value;
    notifyListeners();
  }
}
