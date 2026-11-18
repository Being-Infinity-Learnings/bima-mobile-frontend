/// Reusable coin UI: the coin icon, an animated amount, the balance pill
/// and the "Redeem coins" card.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../providers/coin_balance_provider.dart';

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

/// The currency name for [count]: "BE Coin" or "BE Coins".
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

  /// Text appended after the number, e.g. `' BE Coins available'`.
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

// ─────────────────────────────────────────────────────────────────────────────
// Balance pill
// ─────────────────────────────────────────────────────────────────────────────

/// The student's live coin balance in a compact gold pill.
///
/// When the balance goes up, the pill pops and glows briefly while the
/// number counts up. Pass [onTap] to make it a button (e.g. to open the
/// Store); without it, the pill is display-only.
class CoinBalancePill extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  const CoinBalancePill({super.key, this.onTap});

  @override
  ConsumerState<CoinBalancePill> createState() => _CoinBalancePillState();
}

class _CoinBalancePillState extends ConsumerState<CoinBalancePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebrate = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.12)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.12, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 70,
    ),
  ]).animate(_celebrate);

  late final Animation<double> _glow = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 75,
    ),
  ]).animate(_celebrate);

  @override
  void dispose() {
    _celebrate.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balance = ref.watch(coinBalanceProvider);

    ref.listen<int?>(coinBalanceProvider, (previous, next) {
      final reduceMotion =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (previous != null && next != null && next > previous && !reduceMotion) {
        _celebrate.forward(from: 0);
      }
    });

    final amountStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: AppConfig.coinTextColor(isDark),
    );

    final pill = Material(
      color: AppConfig.coinSurfaceColor(isDark),
      shape: StadiumBorder(
        side: BorderSide(color: AppConfig.coinBorderColor(isDark)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap == null ? null : _handleTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(7, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CoinIcon(size: 18),
              const SizedBox(width: 6),
              if (balance == null)
                Text('—', style: amountStyle)
              else
                AnimatedCoinCount(value: balance, style: amountStyle),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: widget.onTap != null,
      label: balance == null
          ? '${AppConfig.coinNamePlural} balance loading'
          : '${AppConfig.coinNamePlural} balance: '
                '${formatCoins(balance)} ${coinsLabel(balance)}',
      hint: widget.onTap != null ? 'Opens the Store' : null,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _celebrate,
        child: pill,
        builder: (context, child) {
          final glow = _glow.value;
          return Transform.scale(
            scale: _scale.value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: glow > 0
                    ? [
                        BoxShadow(
                          color: AppConfig.coinGold.withValues(
                            alpha: 0.45 * glow,
                          ),
                          blurRadius: 18 * glow,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Redeem coins" card
// ─────────────────────────────────────────────────────────────────────────────

/// A gold card showing the live balance with a call to action to spend it.
class RedeemCoinsCard extends ConsumerWidget {
  final VoidCallback onTap;

  const RedeemCoinsCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balance = ref.watch(coinBalanceProvider) ?? 0;
    final accent = AppConfig.coinTextColor(isDark);

    return Semantics(
      button: true,
      label:
          'Redeem ${AppConfig.coinNamePlural}. '
          '${formatCoins(balance)} ${coinsLabel(balance)} available',
      hint: 'Opens the Store',
      excludeSemantics: true,
      child: Material(
        color: AppConfig.coinSurfaceColor(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppConfig.coinBorderColor(isDark)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppConfig.coinGold.withValues(
                      alpha: isDark ? 0.12 : 0.2,
                    ),
                  ),
                  child: const Center(child: CoinIcon(size: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Redeem ${AppConfig.coinNamePlural}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppConfig.bodyTextColor(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedCoinCount(
                        value: balance,
                        suffix: ' ${coinsLabel(balance)} available',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 22, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
