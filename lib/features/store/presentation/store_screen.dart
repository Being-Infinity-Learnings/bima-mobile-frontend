/// The Store tab.
///
/// Until the store item list ships, this shows the student's balance, a
/// "rewards are coming" message and how to earn coins.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../../core/navigation/app_tab.dart';
import '../../coins/presentation/coin_widgets.dart';
import '../../coins/providers/coin_balance_provider.dart';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The tab stays mounted inside AppShell's IndexedStack, so only animate
    // while it is actually on screen.
    final isVisible = ref.watch(selectedTabProvider) == AppTab.store;

    return Scaffold(
      backgroundColor: AppConfig.scaffoldColor(isDark),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppConfig.backgroundGradient(isDark),
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppConfig.primaryColor,
            onRefresh: () =>
                ref.read(coinBalanceControllerProvider).refresh(force: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ─────────────────────────────────────────
                      Row(
                        children: [
                          Text(
                            'Store',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppConfig.bodyTextColor(isDark),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Scales down rather than overflowing if a huge
                          // balance meets a narrow phone.
                          const Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: CoinBalancePill(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _ComingSoonCard(isDark: isDark, animate: isVisible),

                      const SizedBox(height: 28),

                      Text(
                        'How to earn ${AppConfig.coinNamePlural}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppConfig.bodyTextColor(isDark),
                        ),
                      ),

                      const SizedBox(height: 14),

                      _EarnTip(
                        isDark: isDark,
                        icon: Icons.bolt_rounded,
                        color: AppConfig.accentLime,
                        title: 'Score in every quiz',
                        body: 'The more points you score, the more '
                            '${AppConfig.coinNamePlural} you take home.',
                      ),

                      const SizedBox(height: 10),

                      _EarnTip(
                        isDark: isDark,
                        icon: Icons.emoji_events_rounded,
                        color: AppConfig.accentGold,
                        title: 'Finish on the podium',
                        body: 'Top 3 finishers win bonus '
                            '${AppConfig.coinNamePlural}.',
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Rewards are coming" card
// ─────────────────────────────────────────────────────────────────────────────

class _ComingSoonCard extends StatelessWidget {
  final bool isDark;
  final bool animate;

  const _ComingSoonCard({required this.isDark, required this.animate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppConfig.coinSurfaceColor(isDark),
            AppConfig.cardColor(isDark),
          ],
        ),
        border: Border.all(color: AppConfig.coinBorderColor(isDark)),
      ),
      child: Column(
        children: [
          _FloatingCoin(animate: animate),
          const SizedBox(height: 24),
          Text(
            'Rewards are on the way',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppConfig.bodyTextColor(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soon you can swap your ${AppConfig.coinNamePlural} for real '
            'rewards right here. Keep playing quizzes to stack them up!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppConfig.mutedTextColor(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// A large coin that gently bobs over a soft glow.
class _FloatingCoin extends StatefulWidget {
  final bool animate;

  const _FloatingCoin({required this.animate});

  @override
  State<_FloatingCoin> createState() => _FloatingCoinState();
}

class _FloatingCoinState extends State<_FloatingCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  late final Animation<double> _float = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _FloatingCoin oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final shouldAnimate = widget.animate && !reduceMotion;
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 104,
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) {
          final t = _float.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Glow breathes slightly as the coin rises.
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppConfig.coinGold.withValues(alpha: 0.22 + 0.10 * t),
                      AppConfig.coinGold.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Transform.translate(offset: Offset(0, 6 - 12 * t), child: child),
            ],
          );
        },
        child: const CoinIcon(size: 64),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Earn tip row
// ─────────────────────────────────────────────────────────────────────────────

class _EarnTip extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _EarnTip({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = AppConfig.accentOnSurface(isDark, color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.cardColor(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppConfig.borderColor(isDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.12 : 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppConfig.bodyTextColor(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppConfig.mutedTextColor(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
