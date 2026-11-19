/// A small gold "+41" pill for BECoins earned, used on History and Home.
library;

import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import 'coin_basics.dart';

class CoinAmountChip extends StatelessWidget {
  final int amount;

  /// Text after the amount, e.g. "BECoins earned". Leave it out for a
  /// compact "+41".
  final String? label;

  const CoinAmountChip({super.key, required this.amount, this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppConfig.coinTextColor(isDark);

    return Semantics(
      label: 'Earned ${formatCoins(amount)} ${coinsLabel(amount)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
        decoration: BoxDecoration(
          color: AppConfig.coinSurfaceColor(isDark),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppConfig.coinBorderColor(isDark)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CoinIcon(size: 16),
            const SizedBox(width: 5),
            Text(
              '+${formatCoins(amount)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (label != null) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
