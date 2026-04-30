// integration_test/transaction_crud_test.dart
// Run with: flutter test integration_test/transaction_crud_test.dart
// Requires Firebase emulator or test Firebase project with pre-seeded user.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spendsnap/main.dart' as app;

const _testEmail = 'integration_test@spendsnap.test';
const _testPassword = 'password123';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Transaction CRUD', () {
    testWidgets('add → verify → edit → verify → delete → verify', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Login
      await tester.enterText(find.byType(TextFormField).at(0), _testEmail);
      await tester.enterText(find.byType(TextFormField).at(1), _testPassword);
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to transactions
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();

      // Add transaction
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        '999',
      );
      await tester.tap(find.text('Add Transaction'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify transaction appears
      expect(find.textContaining('999'), findsOneWidget);

      // Edit transaction — tap on it
      await tester.tap(find.textContaining('999'));
      await tester.pumpAndSettle();

      // Clear amount and enter new value
      await tester.enterText(find.byType(TextFormField).first, '1234');
      await tester.tap(find.text('Update Transaction'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify updated
      expect(find.textContaining('1,234'), findsOneWidget);

      // Delete — swipe to dismiss
      await tester.drag(
        find.textContaining('1,234'),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();

      // Confirm delete in dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify removed
      expect(find.textContaining('1,234'), findsNothing);
    });
  });
}
