// integration_test/auth_flow_test.dart
// Run with: flutter test integration_test/auth_flow_test.dart
// Requires Firebase emulator or test Firebase project.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:spendsnap/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth flow', () {
    testWidgets('signup → dashboard → logout → login page', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should land on login page if not authenticated
      expect(find.text('Welcome back'), findsOneWidget);

      // Navigate to signup
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();
      expect(find.text('Create account'), findsOneWidget);

      // Fill signup form with test credentials
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Test User',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'test_${DateTime.now().millisecondsSinceEpoch}@test.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'password123',
      );

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should be on dashboard now
      expect(find.text('Hello,'), findsAny);

      // Logout
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should be back on login
      expect(find.text('Welcome back'), findsOneWidget);
    });
  });
}
