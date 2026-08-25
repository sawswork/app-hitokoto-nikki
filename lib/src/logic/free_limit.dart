/// 無料枠の制限ロジック。
///
/// 無料では「作成したエントリ数の合計」が [freeEntryLimit] 件まで。
/// 買い切り(プレミアム)なら無制限。既存日の上書きは新規ではないため、
/// 判定は「新規エントリを1件増やせるか」を対象にする。
library;

/// 無料で作成できるエントリ数の上限(= 30日分)。
const int freeEntryLimit = 30;

/// 現在 [currentCount] 件あるとき、新規エントリをもう1件作れるか。
///
/// [isPremium] が true なら常に true。
/// 無料時は [currentCount] が [freeEntryLimit] 未満のときのみ true。
bool canAddNewEntry(int currentCount, {required bool isPremium}) {
  if (isPremium) return true;
  return currentCount < freeEntryLimit;
}

/// 無料で残り何件作れるか(プレミアムなら null = 無制限)。
int? remainingFreeEntries(int currentCount, {required bool isPremium}) {
  if (isPremium) return null;
  final remaining = freeEntryLimit - currentCount;
  return remaining < 0 ? 0 : remaining;
}
