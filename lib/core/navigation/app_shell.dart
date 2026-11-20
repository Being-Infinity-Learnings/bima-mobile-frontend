import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/coins/providers/coin_balance_provider.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/store/presentation/store_screen.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../../config/app_config.dart';
import 'app_tab.dart';

export 'app_tab.dart';

// Tracks how many unread notifications have come in since the user last
// visited the notifications tab. Exposed so the badge can read it.
final _unreadCountProvider = StateProvider<int>((_) => 0);

/// Tabs that show the coin balance; opening one refreshes it.
const _tabsShowingCoins = {AppTab.home, AppTab.store, AppTab.profile};

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  StreamSubscription<RemoteMessage>? _fgSub;
  StreamSubscription<RemoteMessage>? _tapSub;

  // Must stay in the same order as [AppTab].
  final _screens = const [
    HomeScreen(),
    StoreScreen(),
    HistoryScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  AppTab get _selectedTab => ref.read(selectedTabProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Increment badge whenever a foreground message arrives and the user is
    // NOT already on the notifications tab.
    _fgSub = FirebaseMessaging.onMessage.listen((msg) {
      if (_selectedTab != AppTab.alerts) {
        ref.read(_unreadCountProvider.notifier).update((c) => c + 1);
      }
    });

    // When a notification is tapped from the system tray, jump straight to
    // the notifications tab and clear the badge.
    _tapSub = FirebaseMessaging.onMessageOpenedApp.listen((_) {
      _selectTab(AppTab.alerts);
    });

    // Handle the case where the app was terminated and launched via a notif.
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null && mounted) {
        _selectTab(AppTab.alerts);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fgSub?.cancel();
    _tapSub?.cancel();
    super.dispose();
  }

  // Coins can be awarded while the app is in the background (e.g. a quiz
  // finished), so catch up when the student comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(coinBalanceControllerProvider).refresh();
    }
  }

  void _selectTab(AppTab tab) {
    ref.read(selectedTabProvider.notifier).state = tab;
    if (tab == AppTab.alerts) {
      // Clear badge when user lands on the notifications tab.
      ref.read(_unreadCountProvider.notifier).state = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(_unreadCountProvider);
    final selectedTab = ref.watch(selectedTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Screens can switch tabs directly through the provider, so react to
    // the selection itself rather than only to bottom-nav taps.
    ref.listen<AppTab>(selectedTabProvider, (previous, next) {
      if (next != previous && _tabsShowingCoins.contains(next)) {
        ref.read(coinBalanceControllerProvider).refresh();
      }
    });

    return Scaffold(
      backgroundColor: AppConfig.scaffoldColor(isDark),

      // The persistent branding strip lives here, above the tab content, so
      // every tab shows it without each screen needing its own copy. Each
      // tab screen still draws its own SafeArea, so the top inset is
      // consumed here and removed below to avoid double padding.
      body: Column(
        children: [
          SafeArea(bottom: false, child: const AppBrandBar()),

          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: IndexedStack(
                index: selectedTab.index,
                children: _screens,
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab.index,
        onDestinationSelected: (index) => _selectTab(AppTab.values[index]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Store',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'History',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
