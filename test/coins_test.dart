import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_frontend/features/auth/data/auth_models.dart';
import 'package:flutter_frontend/features/coins/presentation/coin_widgets.dart';
import 'package:flutter_frontend/features/coins/providers/coin_balance_provider.dart';
import 'package:flutter_frontend/features/store/presentation/store_screen.dart';

Map<String, dynamic> _userJson([Map<String, dynamic> extra = const {}]) => {
  'id': 'user-1',
  'firebaseUid': 'firebase-1',
  'email': 'student@example.com',
  'phone': null,
  'fullName': 'Test Student',
  'gender': 'Female',
  'collegeName': 'Test College',
  'rollNumber': 'R-001',
  'role': 'STUDENT',
  'approved': true,
  'blocked': false,
  ...extra,
};

void main() {
  group('formatCoins', () {
    test('adds thousands separators', () {
      expect(formatCoins(0), '0');
      expect(formatCoins(999), '999');
      expect(formatCoins(1000), '1,000');
      expect(formatCoins(12500), '12,500');
      expect(formatCoins(1234567), '1,234,567');
      expect(formatCoins(-1500), '-1,500');
    });

    test('names the currency, singular or plural', () {
      expect(coinsLabel(1), 'BECoin');
      expect(coinsLabel(0), 'BECoins');
      expect(coinsLabel(420), 'BECoins');
    });
  });

  group('UserModel.fromJson', () {
    test('reads the coin balance', () {
      final user = UserModel.fromJson(_userJson({'coinBalance': 420}));
      expect(user.coinBalance, 420);
    });

    test('defaults the coin balance to 0 when missing', () {
      final user = UserModel.fromJson(_userJson());
      expect(user.coinBalance, 0);
    });

    test('has no saved address when none of the saved fields are set', () {
      final user = UserModel.fromJson(
        _userJson({'savedRecipientName': null, 'savedCity': '   '}),
      );
      expect(user.savedAddress, isNull);
    });

    test('reads the saved address and ignores blank fields', () {
      final user = UserModel.fromJson(
        _userJson({
          'savedRecipientName': ' Asha Rao ',
          'savedAddressLine1': '12 MG Road',
          'savedAddressLine2': '',
          'savedCity': 'Bengaluru',
          'savedState': 'Karnataka',
          'savedPostalCode': '560001',
          'savedCountry': 'India',
          'savedContactPhone': '9876543210',
        }),
      );

      final address = user.savedAddress!;
      expect(address.recipientName, 'Asha Rao');
      expect(address.addressLine1, '12 MG Road');
      expect(address.addressLine2, isNull);
      expect(address.city, 'Bengaluru');
      expect(address.postalCode, '560001');
      expect(address.contactPhone, '9876543210');
    });

    test('copyWith changes only the given fields', () {
      final user = UserModel.fromJson(_userJson({'coinBalance': 100}));
      final updated = user.copyWith(coinBalance: 170);

      expect(updated.coinBalance, 170);
      expect(updated.id, user.id);
      expect(updated.fullName, user.fullName);
      expect(user.coinBalance, 100);
    });
  });

  group('AnimatedCoinCount', () {
    Widget build(int value) => MaterialApp(
      home: Scaffold(body: AnimatedCoinCount(value: value)),
    );

    testWidgets('shows the first value at once and counts up to a new one', (
      tester,
    ) async {
      await tester.pumpWidget(build(350));
      expect(find.text('350'), findsOneWidget);

      await tester.pumpWidget(build(1420));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('1,420'), findsNothing, reason: 'still counting');

      await tester.pumpAndSettle();
      expect(find.text('1,420'), findsOneWidget);
    });

    testWidgets('jumps straight to the new value when motion is reduced', (
      tester,
    ) async {
      Widget reduced(int value) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: build(value),
      );

      await tester.pumpWidget(reduced(10));
      await tester.pumpWidget(reduced(80));
      await tester.pump();
      expect(find.text('80'), findsOneWidget);
    });
  });

  group('CoinBalancePill', () {
    Widget build({required int? balance, VoidCallback? onTap}) =>
        ProviderScope(
          overrides: [coinBalanceProvider.overrideWithValue(balance)],
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: CoinBalancePill(onTap: onTap)),
            ),
          ),
        );

    testWidgets('shows a dash until the balance has loaded', (tester) async {
      await tester.pumpWidget(build(balance: null));
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('shows the balance and reports taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(build(balance: 2500, onTap: () => taps++));

      expect(find.text('2,500'), findsOneWidget);

      await tester.tap(find.byType(CoinBalancePill));
      expect(taps, 1);
    });
  });

  // Smallest common phone width with a 7-digit balance, in both themes.
  group('layout on a narrow phone', () {
    for (final brightness in Brightness.values) {
      Widget build(Widget child) => ProviderScope(
        overrides: [coinBalanceProvider.overrideWithValue(1234567)],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: child,
        ),
      );

      setUp(() {
        final view = TestWidgetsFlutterBinding.instance.platformDispatcher
            .implicitView!;
        view.physicalSize = const Size(320, 640);
        view.devicePixelRatio = 1;
      });

      tearDown(() {
        TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
            .reset();
      });

      testWidgets('Store tab renders without overflow (${brightness.name})', (
        tester,
      ) async {
        await tester.pumpWidget(build(const StoreScreen()));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Rewards are on the way'), findsOneWidget);
        expect(find.text('1,234,567'), findsOneWidget);
      });

      testWidgets('Redeem coins card renders without overflow '
          '(${brightness.name})', (tester) async {
        await tester.pumpWidget(
          build(
            Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: RedeemCoinsCard(onTap: () {}),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('1,234,567 BECoins available'), findsOneWidget);
        expect(find.text('Redeem BECoins'), findsOneWidget);
      });
    }
  });
}
