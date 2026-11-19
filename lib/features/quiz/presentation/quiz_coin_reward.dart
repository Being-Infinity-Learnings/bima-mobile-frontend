/// The "BECoins earned" card on the quiz results screen.
///
/// When it appears, the coin spins in and lands with a tap of haptics, the
/// amount counts up, a few small coins burst out, a gold shine sweeps across
/// the card and the new balance ticks up. With "Reduce Motion" on, it shows
/// the final values straight away.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/app_config.dart';
import '../../coins/presentation/coin_basics.dart';
import '../data/quiz_models.dart';

/// `1` → "1st", `2` → "2nd", `3` → "3rd", `11` → "11th", `22` → "22nd".
String ordinal(int n) {
  final lastTwo = n % 100;
  if (lastTwo >= 11 && lastTwo <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

/// Where the coins came from, e.g. "36 for your score · +5 for finishing 1st".
String coinBreakdownText(FinalResult result) {
  final rank = result.rank;
  if (result.coinBonus <= 0 || rank == null) return 'Based on your score';
  return '${formatCoins(result.scoreCoins)} for your score · '
      '+${formatCoins(result.coinBonus)} for finishing ${ordinal(rank)}';
}

/// What a screen reader announces for the whole card.
String _semanticsLabel(FinalResult result) {
  final earned = result.coinsEarned;
  final parts = <String>[
    'Earned ${formatCoins(earned)} ${coinsLabel(earned)}.',
    if (result.coinBonus > 0 && result.rank != null)
      '${formatCoins(result.scoreCoins)} for your score, plus '
          '${formatCoins(result.coinBonus)} for finishing '
          '${ordinal(result.rank!)}.',
    if (result.coinBalance != null)
      'New balance ${formatCoins(result.coinBalance!)} '
          '${coinsLabel(result.coinBalance!)}.',
  ];
  return parts.join(' ');
}

class QuizCoinReward extends StatefulWidget {
  final FinalResult result;

  const QuizCoinReward({super.key, required this.result});

  @override
  State<QuizCoinReward> createState() => _QuizCoinRewardState();
}

class _QuizCoinRewardState extends State<QuizCoinReward>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1600);

  /// The point (0–1) of the animation where the coin lands face-on.
  static const _coinLandsAt = 0.45;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: _duration,
  );

  // Each part of the reveal runs in its own slice of the one controller.
  late final Animation<double> _cardFade = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0, 0.18, curve: Curves.easeOut),
  );
  late final Animation<double> _cardScale = Tween<double>(begin: 0.94, end: 1)
      .animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0, 0.25, curve: Curves.easeOutBack),
        ),
      );
  late final Animation<double> _coinSpin = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.05, _coinLandsAt, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _coinPop = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.05, _coinLandsAt, curve: Curves.easeOutBack),
  );
  late final Animation<double> _countUp = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.2, 0.75, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _burst = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.42, 1),
  );
  late final Animation<double> _shine = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.55, 0.9, curve: Curves.easeInOut),
  );
  late final Animation<double> _balanceUp = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.6, 1, curve: Curves.easeOutCubic),
  );

  bool _started = false;
  bool _hapticPlayed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _ctrl.value = 1;
    } else {
      _ctrl.addListener(_playLandingHaptic);
      _ctrl.forward();
    }
  }

  void _playLandingHaptic() {
    if (_hapticPlayed || _ctrl.value < _coinLandsAt) return;
    _hapticPlayed = true;
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = widget.result;
    final earned = result.coinsEarned;
    final balance = result.coinBalance;
    final coinText = AppConfig.coinTextColor(isDark);
    final muted = AppConfig.mutedTextColor(isDark);
    const tabular = [FontFeature.tabularFigures()];

    final card = Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConfig.coinGold.withValues(alpha: isDark ? 0.16 : 0.24),
            AppConfig.cardColor(isDark),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppConfig.coinBorderColor(isDark)),
        boxShadow: [
          BoxShadow(
            color: AppConfig.coinGold.withValues(alpha: isDark ? 0.08 : 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _SpinningCoin(spin: _coinSpin, pop: _coinPop, burst: _burst),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reads as one phrase with the amount below:
                    // "You earned +41 BECoins".
                    Text(
                      'You earned',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: coinText.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // "+41 BECoins" as one line, so the two sizes share a
                    // baseline; it shrinks rather than overflows if huge.
                    AnimatedBuilder(
                      animation: _countUp,
                      builder: (_, _) => FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '+${formatCoins((earned * _countUp.value).round())}',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  fontFeatures: tabular,
                                ),
                              ),
                              TextSpan(
                                text: ' ${coinsLabel(earned)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: coinText.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          style: TextStyle(color: coinText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coinBreakdownText(result),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (balance != null) ...[
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: AppConfig.coinBorderColor(isDark).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'New balance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const CoinIcon(size: 16),
                const SizedBox(width: 6),
                AnimatedBuilder(
                  animation: _balanceUp,
                  builder: (_, _) {
                    final from = math.max(balance - earned, 0);
                    final shown = (from + (balance - from) * _balanceUp.value)
                        .round();
                    return Text(
                      formatCoins(shown),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppConfig.bodyTextColor(isDark),
                        fontFeatures: tabular,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return Semantics(
      container: true,
      label: _semanticsLabel(result),
      excludeSemantics: true,
      child: FadeTransition(
        opacity: _cardFade,
        child: ScaleTransition(
          scale: _cardScale,
          child: Stack(
            children: [
              card,
              // One gold shine sweeping across the card.
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CustomPaint(
                      painter: _ShinePainter(progress: _shine, isDark: isDark),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spinning coin with a burst of small coins
// ─────────────────────────────────────────────────────────────────────────────

class _SpinningCoin extends StatelessWidget {
  final Animation<double> spin;
  final Animation<double> pop;
  final Animation<double> burst;

  const _SpinningCoin({
    required this.spin,
    required this.pop,
    required this.burst,
  });

  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Drawn outside the coin's box on purpose: the small coins fly up
          // and out over the card.
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _CoinBurstPainter(progress: burst)),
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([spin, pop]),
            builder: (_, child) {
              // One full turn around the vertical axis, landing face-on,
              // with a little perspective so it reads as a real coin.
              final angle = (1 - spin.value) * 2 * math.pi;
              final glow = spin.value;
              return Transform.scale(
                scale: 0.4 + 0.6 * pop.value,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateY(angle),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppConfig.coinGold.withValues(
                            alpha: 0.45 * glow,
                          ),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              );
            },
            child: const CoinIcon(size: _size),
          ),
        ],
      ),
    );
  }
}

/// Small coins that pop up out of the big one, arc over and fade away.
class _CoinBurstPainter extends CustomPainter {
  final Animation<double> progress;

  _CoinBurstPainter({required this.progress}) : super(repaint: progress);

  // Fixed seed: the burst looks the same every time (and in tests).
  static final List<_BurstCoin> _coins = _BurstCoin.generate(14, seed: 7);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;

    final origin = size.center(Offset.zero);
    // Fade in quickly, then fade out over the last 40%.
    final opacity = t < 0.1 ? t / 0.1 : (t > 0.6 ? (1 - t) / 0.4 : 1.0);

    final rim = Paint()
      ..color = AppConfig.coinGoldDeep.withValues(alpha: opacity);
    final face = Paint()..color = AppConfig.coinGold.withValues(alpha: opacity);
    final shine = Paint()
      ..color = AppConfig.coinGoldLight.withValues(alpha: opacity * 0.9);

    for (final coin in _coins) {
      // Simple projectile: launch velocity plus gravity.
      final dx = coin.vx * t;
      final dy = coin.vy * t + 0.5 * 260 * t * t;
      final center = origin + Offset(dx, dy);
      final r = coin.radius;
      // Squash horizontally as it spins, so each coin seems to flip.
      final squash =
          0.35 + 0.65 * (math.cos(coin.spin * t * math.pi * 2)).abs();
      final rect = Rect.fromCenter(
        center: center,
        width: r * 2 * squash,
        height: r * 2,
      );
      canvas.drawOval(rect, rim);
      canvas.drawOval(rect.deflate(r * 0.22), face);
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(-r * 0.25 * squash, -r * 0.3),
          width: r * 0.5 * squash,
          height: r * 0.5,
        ),
        shine,
      );
    }
  }

  @override
  bool shouldRepaint(_CoinBurstPainter old) => old.progress != progress;
}

class _BurstCoin {
  final double vx;
  final double vy;
  final double radius;
  final double spin;

  const _BurstCoin(this.vx, this.vy, this.radius, this.spin);

  static List<_BurstCoin> generate(int count, {required int seed}) {
    final random = math.Random(seed);
    return List.generate(count, (i) {
      // Spread evenly over an upward fan, with a little jitter.
      final fan = (i / (count - 1)) - 0.5; // -0.5 … 0.5
      final angle =
          -math.pi / 2 + fan * 2.2 + (random.nextDouble() - 0.5) * 0.25;
      final speed = 110 + random.nextDouble() * 70;
      return _BurstCoin(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
        3 + random.nextDouble() * 2.5,
        1 + random.nextDouble() * 2,
      );
    });
  }
}

/// A soft diagonal band of light that crosses the card once.
class _ShinePainter extends CustomPainter {
  final Animation<double> progress;
  final bool isDark;

  _ShinePainter({required this.progress, required this.isDark})
    : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;

    final bandWidth = size.width * 0.35;
    final left = -bandWidth + (size.width + bandWidth * 2) * t;
    final rect = Rect.fromLTWH(left, 0, bandWidth, size.height);
    final peak = AppConfig.whiteColor.withValues(alpha: isDark ? 0.10 : 0.45);

    canvas.save();
    // Lean the band so it reads as a reflection, not a wipe.
    canvas.translate(size.width / 2, size.height / 2);
    canvas.skew(-0.35, 0);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [peak.withValues(alpha: 0), peak, peak.withValues(alpha: 0)],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShinePainter old) =>
      old.progress != progress || old.isDark != isDark;
}
