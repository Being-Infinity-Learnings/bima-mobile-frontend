/// The basic coin building blocks shared across the app: amount
/// formatting, the currency name, the coin icon and the animated amount.
///
/// No providers here, so any screen can use these.
library;

import 'package:flutter/material.dart';

import '../../../config/app_config.dart';

/// Formats a coin amount with thousands separators, e.g. `12500` → `12,500`.
String formatCoins(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// The currency name for [count]: "BECoin" or "BECoins".
String coinsLabel(int count) =>
    count == 1 ? AppConfig.coinName : AppConfig.coinNamePlural;

// ─────────────────────────────────────────────────────────────────────────────
// Coin icon
// ─────────────────────────────────────────────────────────────────────────────

/// A gold coin stamped with the ∞ mark. Purely decorative, so it is hidden
/// from screen readers; the amount next to it carries the meaning.
class CoinIcon extends StatelessWidget {
  final double size;

  const CoinIcon({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConfig.coinGoldLight,
              AppConfig.coinGold,
              AppConfig.coinGoldDeep,
            ],
            stops: [0, 0.45, 1],
          ),
          // A soft drop shadow only where it's big enough to be seen.
          boxShadow: size >= 28
              ? [
                  BoxShadow(
                    color: AppConfig.coinGoldDeep.withValues(alpha: 0.35),
                    blurRadius: size * 0.35,
                    offset: Offset(0, size * 0.08),
                  ),
                ]
              : null,
        ),
        padding: EdgeInsets.all(size * 0.12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppConfig.coinInk.withValues(alpha: 0.3),
              width: size >= 28 ? size * 0.04 : 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.all_inclusive_rounded,
              size: size * 0.48,
              color: AppConfig.coinInk,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated amount
// ─────────────────────────────────────────────────────────────────────────────

/// A coin amount that counts up (or down) to [value] whenever it changes.
///
/// The first value is shown as-is; only later changes animate. Digits are
/// tabular so the text doesn't jitter while counting, and the animation is
/// skipped when the system "reduce motion" setting is on.
class AnimatedCoinCount extends StatelessWidget {
  final int value;
  final TextStyle? style;

  /// Text appended after the number, e.g. `' BECoins available'`.
  final String suffix;

  final Duration duration;

  const AnimatedCoinCount({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final textStyle = (style ?? const TextStyle()).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Semantics(
      label: '${formatCoins(value)}$suffix',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: value.toDouble()),
        duration: reduceMotion ? Duration.zero : duration,
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => Text(
          '${formatCoins(animated.round())}$suffix',
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
