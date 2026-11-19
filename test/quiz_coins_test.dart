import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_frontend/features/coins/presentation/coin_amount_chip.dart';
import 'package:flutter_frontend/features/quiz/data/quiz_models.dart';
import 'package:flutter_frontend/features/quiz/presentation/quiz_coin_reward.dart';

FinalResult _result({
  int? rank = 1,
  int coins = 41,
  int bonus = 0,
  int? balance = 1208,
}) => FinalResult(
  rank: rank,
  totalScore: 2312,
  totalParticipants: 5,
  coinsEarned: coins,
  coinBonus: bonus,
  coinBalance: balance,
);

Widget _app(
  Widget child, {
  bool reduceMotion = false,
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  theme: ThemeData(brightness: brightness),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: Scaffold(
        body: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    ),
  ),
);

void main() {
  group('FinalResult.fromJson', () {
    test('reads the coins the backend sends', () {
      final result = FinalResult.fromJson({
        'rank': 1,
        'totalScore': 2312,
        'totalParticipants': 5,
        'coinsEarned': 41,
        'coinBonus': 5,
        'coinBalance': 1208,
      });

      expect(result.coinsEarned, 41);
      expect(result.coinBonus, 5);
      expect(result.scoreCoins, 36);
      expect(result.coinBalance, 1208);
      expect(result.hasCoins, isTrue);
    });

    test('means no coins when the backend sends none', () {
      final result = FinalResult.fromJson({
        'rank': 3,
        'totalScore': 0,
        'totalParticipants': 2,
      });

      expect(result.coinsEarned, 0);
      expect(result.coinBonus, 0);
      expect(result.scoreCoins, 0);
      expect(result.coinBalance, isNull);
      expect(result.hasCoins, isFalse);
    });
  });

  group('HistoryResult.fromJson', () {
    Map<String, dynamic> json([Map<String, dynamic> extra = const {}]) => {
      'quizId': 'quiz-1',
      'title': 'Weekly quiz',
      'completedAt': '2026-11-18T12:41:24.667Z',
      'rank': 1,
      'totalParticipants': 4,
      'score': 1692,
      'totalQuestions': 3,
      ...extra,
    };

    test('reads the coins earned', () {
      expect(HistoryResult.fromJson(json({'coinsEarned': 33})).coinsEarned, 33);
    });

    test('defaults to 0 coins when missing', () {
      expect(HistoryResult.fromJson(json()).coinsEarned, 0);
    });
  });

  group('coin breakdown text', () {
    test('ordinal', () {
      expect([1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 101, 111].map(ordinal), [
        '1st', '2nd', '3rd', '4th', '11th', '12th', //
        '13th', '21st', '22nd', '23rd', '101st', '111th',
      ]);
    });

    test('without a podium bonus', () {
      expect(coinBreakdownText(_result()), 'Based on your score');
    });

    test('with a podium bonus', () {
      expect(
        coinBreakdownText(_result(rank: 1, coins: 41, bonus: 5)),
        '36 for your score · +5 for finishing 1st',
      );
      expect(
        coinBreakdownText(_result(rank: 3, coins: 30, bonus: 1)),
        '29 for your score · +1 for finishing 3rd',
      );
    });
  });

  group('QuizCoinReward', () {
    testWidgets('counts up to the coins earned and shows the new balance', (
      tester,
    ) async {
      await tester.pumpWidget(_app(QuizCoinReward(result: _result())));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('+41 BECoins'), findsNothing, reason: 'still counting');

      await tester.pumpAndSettle();
      expect(find.text('+41 BECoins'), findsOneWidget);
      expect(find.text('Based on your score'), findsOneWidget);
      expect(find.text('New balance'), findsOneWidget);
      expect(find.text('1,208'), findsOneWidget);
    });

    testWidgets('shows the final values at once with Reduce Motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(QuizCoinReward(result: _result()), reduceMotion: true),
      );
      await tester.pump();

      expect(find.text('+41 BECoins'), findsOneWidget);
      expect(find.text('1,208'), findsOneWidget);
    });

    testWidgets('shows the podium bonus', (tester) async {
      await tester.pumpWidget(
        _app(QuizCoinReward(result: _result(coins: 41, bonus: 5))),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('36 for your score · +5 for finishing 1st'),
        findsOneWidget,
      );
    });

    testWidgets('leaves out the balance row when no balance is sent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(QuizCoinReward(result: _result(balance: null))),
      );
      await tester.pumpAndSettle();

      expect(find.text('+41 BECoins'), findsOneWidget);
      expect(find.text('New balance'), findsNothing);
    });

    testWidgets('reads out the final amounts to screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(QuizCoinReward(result: _result(coins: 41, bonus: 5))),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          'Earned 41 BECoins. 36 for your score, plus 5 for finishing 1st. '
          'New balance 1,208 BECoins.',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('CoinAmountChip', () {
    testWidgets('shows the amount and an optional label', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(const CoinAmountChip(amount: 1500, label: 'BECoins earned')),
      );

      expect(find.text('+1,500'), findsOneWidget);
      expect(find.text('BECoins earned'), findsOneWidget);
      expect(find.bySemanticsLabel('Earned 1,500 BECoins'), findsOneWidget);
      semantics.dispose();
    });
  });

  // Smallest common phone width, big numbers, both themes.
  group('layout on a narrow phone', () {
    for (final brightness in Brightness.values) {
      setUp(() {
        final view =
            TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
        view.physicalSize = const Size(320, 640);
        view.devicePixelRatio = 1;
      });

      tearDown(() {
        TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
            .reset();
      });

      testWidgets('coins card fits (${brightness.name})', (tester) async {
        await tester.pumpWidget(
          _app(
            QuizCoinReward(
              result: _result(
                rank: 2,
                coins: 12345,
                bonus: 3,
                balance: 1234567,
              ),
            ),
            brightness: brightness,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('+12,345 BECoins'), findsOneWidget);
        expect(find.text('1,234,567'), findsOneWidget);
      });

      testWidgets('History title row with a coin chip fits '
          '(${brightness.name})', (tester) async {
        // The title column of a History card is about 150pt wide at 320pt.
        await tester.pumpWidget(
          _app(
            const SizedBox(
              width: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text('A very long quiz title that wraps over lines'),
                  ),
                  SizedBox(width: 8),
                  CoinAmountChip(amount: 12345),
                ],
              ),
            ),
            brightness: brightness,
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('+12,345'), findsOneWidget);
      });

      testWidgets('Home chip with a label fits (${brightness.name})', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            const SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoinAmountChip(amount: 12345, label: 'BECoins earned'),
                ],
              ),
            ),
            brightness: brightness,
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
