/// Coin UI tied to the signed-in student: the live balance pill. The basic
/// pieces live in `coin_basics.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../providers/coin_balance_provider.dart';
import 'coin_basics.dart';

export 'coin_basics.dart';

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

  /// The pill's height; the coin, the number and the padding scale with it.
  final double height;

  const CoinBalancePill({super.key, this.onTap, this.height = 30});

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

    // Everything scales with the height; at the default 30 this is an 18pt
    // coin and 14pt digits. The coin sits in the round end like a badge.
    final height = widget.height;
    final coinSize = height * 0.6;
    final amountStyle = TextStyle(
      fontSize: height * 0.47,
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
        child: Container(
          height: height,
          padding: EdgeInsets.only(
            left: (height - coinSize) / 2,
            right: height * 0.4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoinIcon(size: coinSize),
              SizedBox(width: height * 0.2),
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
