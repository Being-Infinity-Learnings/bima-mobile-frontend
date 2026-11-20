/// The bottom-nav tabs of [AppShell] and the provider that selects one.
///
/// Screens switch tabs with `ref.goToTab(AppTab.store)` rather than hard-coded
/// indexes, so adding or reordering a tab only means changing this enum and
/// the shell's screen list.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom-nav tabs, in display order.
enum AppTab { home, store, history, alerts, profile }

/// The currently selected bottom-nav tab.
final selectedTabProvider = StateProvider<AppTab>((_) => AppTab.home);

extension AppTabNavigation on WidgetRef {
  /// Switches the bottom nav to [tab].
  void goToTab(AppTab tab) => read(selectedTabProvider.notifier).state = tab;
}
