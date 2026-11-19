import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_frontend/features/auth/data/auth_models.dart';
import 'package:flutter_frontend/features/auth/providers/auth_provider.dart';
import 'package:flutter_frontend/features/auth/providers/auth_state.dart';
import 'package:flutter_frontend/shared/enums/auth_status.dart';
import 'package:flutter_frontend/features/quiz/data/quiz_models.dart';
import 'package:flutter_frontend/features/quiz/data/quiz_repository.dart';
import 'package:flutter_frontend/features/quiz/presentation/quiz_results_screen.dart';
import 'package:flutter_frontend/features/quiz/providers/quiz_providers.dart';

const _quizId = 'quiz-1';

/// Never called: the results screen only reads the state the test sets.
/// (The real repository talks to Firebase as soon as it's created.)
class _NoRepository implements QuizRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A finished quiz, without a socket.
class _FinishedQuiz extends QuizRuntimeController {
  _FinishedQuiz(QuizRuntimeState finished) : super(_quizId, _NoRepository()) {
    state = finished;
  }
}

/// A signed-in student. The real AuthNotifier talks to Firebase as soon as
/// it's created.
class _SignedIn extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedIn(UserModel user)
    : super(AuthState(status: AuthStatus.authenticated, user: user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _student = UserModel.fromJson({
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
});

QuizRuntimeState _finished({int coins = 42, int? balance = 1250}) =>
    QuizRuntimeState(
      connectionStatus: SocketConnectionStatus.connected,
      leaderboard: const [
        LeaderboardEntry(
          rank: 1,
          userId: 'user-1',
          fullName: 'Test Student',
          profileImage: null,
          totalScore: 2384,
        ),
      ],
      myFinalResult: FinalResult(
        rank: 1,
        totalScore: 2384,
        totalParticipants: 1,
        coinsEarned: coins,
        coinBalance: balance,
      ),
      totalParticipants: 1,
    );

/// Shows the results screen on a phone of [size] (in points) with the given
/// safe-area insets, plays the whole reveal (podium, result card, then the
/// coins card) and returns any layout overflow that ran off the bottom.
///
/// Sideways overflows are left out on purpose: the test font draws every
/// letter as a wide square, so text-heavy rows of the existing screen
/// overflow sideways here but fit on a real iPhone. The coin widgets'
/// widths are tested at 320pt in quiz_coins_test.dart.
Future<List<String>> _showResults(
  WidgetTester tester, {
  required Size size,
  required double top,
  required double bottom,
  required QuizRuntimeState state,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
  addTearDown(tester.view.reset);

  final overflows = <String>[];
  final reportError = FlutterError.onError;
  FlutterError.onError = (details) {
    final message = details.exceptionAsString();
    if (!message.contains('overflowed')) return reportError?.call(details);
    if (message.contains('on the bottom')) overflows.add(message);
  };

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _SignedIn(_student)),
        quizRuntimeControllerProvider(
          _quizId,
        ).overrideWith((ref) => _FinishedQuiz(state)),
      ],
      child: const MaterialApp(home: QuizResultsScreen(quizId: _quizId)),
    ),
  );

  // The reveal takes about 5s. The confetti never settles, so step through.
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  FlutterError.onError = reportError;
  return overflows;
}

void main() {
  const phones = {
    'iPhone SE': (size: Size(375, 667), top: 20.0, bottom: 0.0),
    'iPhone 17 Pro': (size: Size(402, 874), top: 62.0, bottom: 34.0),
  };

  for (final MapEntry(key: name, value: phone) in phones.entries) {
    testWidgets('results screen fits without overflow on $name', (
      tester,
    ) async {
      final overflows = await _showResults(
        tester,
        size: phone.size,
        top: phone.top,
        bottom: phone.bottom,
        state: _finished(),
      );

      expect(overflows, isEmpty);
      expect(find.text('1 player competed'), findsOneWidget);
      expect(find.text('You earned'), findsOneWidget);
      expect(find.text('+42 BECoins'), findsOneWidget);
      expect(find.text('1,250'), findsOneWidget);
    });
  }

  testWidgets('no coins card when the student earned no coins', (tester) async {
    final overflows = await _showResults(
      tester,
      size: const Size(402, 874),
      top: 62,
      bottom: 34,
      state: _finished(coins: 0, balance: null),
    );

    expect(overflows, isEmpty);
    expect(find.text('You earned'), findsNothing);
  });
}
