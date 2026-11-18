/// The signed-in student's coin balance, and the one place that refreshes it.
///
/// The balance lives on the user returned by `/auth/me`, so [authProvider]
/// stays the single source of truth. Widgets watch [coinBalanceProvider];
/// anything that knows the balance changed calls [CoinBalanceController].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

/// The current coin balance, or null while the profile hasn't loaded yet.
final coinBalanceProvider = Provider<int?>(
  (ref) => ref.watch(authProvider.select((s) => s.user?.coinBalance)),
);

final coinBalanceControllerProvider = Provider<CoinBalanceController>(
  CoinBalanceController.new,
);

/// Keeps the coin balance up to date.
///
/// Call [refresh] when the balance may have changed on the server (a quiz
/// just ended, the app came back to the foreground, a tab was opened), and
/// [setBalance] when an API response already includes the new balance
/// (quiz results, redemptions).
class CoinBalanceController {
  CoinBalanceController(this._ref);

  final Ref _ref;

  /// Non-forced refreshes closer together than this are skipped, so quick
  /// tab switches and app resumes don't flood `/auth/me`.
  static const _minRefreshInterval = Duration(seconds: 10);

  DateTime? _lastSyncedAt;
  Future<void>? _inFlight;

  /// Fetches the latest balance from the server.
  ///
  /// Use [force] right after an event that changes the balance (e.g. "Back
  /// to Home" after a quiz) so the throttle never hides fresh coins.
  /// Concurrent calls share one request.
  Future<void> refresh({bool force = false}) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final lastSyncedAt = _lastSyncedAt;
    if (!force &&
        lastSyncedAt != null &&
        DateTime.now().difference(lastSyncedAt) < _minRefreshInterval) {
      return Future.value();
    }

    final request = _ref
        .read(authProvider.notifier)
        .refreshUser()
        .whenComplete(() {
          _lastSyncedAt = DateTime.now();
          _inFlight = null;
        });

    _inFlight = request;
    return request;
  }

  /// Applies a balance the server already returned, without a refetch.
  void setBalance(int balance) {
    _ref.read(authProvider.notifier).setCoinBalance(balance);
    _lastSyncedAt = DateTime.now();
  }
}
