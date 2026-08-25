import 'package:flutter/material.dart';

import '../logic/free_limit.dart';
import '../state/app_state.dart';

/// 買い切りの購入導線(ボトムシート)。誇張せず、事実だけを伝える。
Future<void> showPaywall(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const _PaywallSheet(),
  );
}

class _PaywallSheet extends StatefulWidget {
  const _PaywallSheet();

  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (mounted) {
      setState(() => _busy = false);
      if (AppScope.of(context).isPremium) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '無制限に書くには',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '無料では $freeEntryLimit 日分まで書けます。'
            '買い切りで購入すると、日数の上限がなくなり、'
            'すべての機能が使えます。月額ではありません。一度の購入だけです。',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : () => _run(AppScope.of(context).buyPremium),
            child: const Text('買い切りで購入(500円)'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed:
                _busy ? null : () => _run(AppScope.of(context).restorePurchase),
            child: const Text('購入を復元(機種変更したとき)'),
          ),
        ],
      ),
    );
  }
}
