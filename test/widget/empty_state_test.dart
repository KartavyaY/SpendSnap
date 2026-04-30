import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsnap/shared/widgets/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders title and description', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Nothing here',
              description: 'Add something to get started.',
            ),
          ),
        ),
      );

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Add something to get started.'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Empty',
              description: 'No data.',
              icon: Icons.inbox,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('action button not shown when onAction is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Empty',
              description: 'No data.',
              actionLabel: 'Add',
              // onAction not provided
            ),
          ),
        ),
      );

      expect(find.text('Add'), findsNothing);
    });

    testWidgets('action button shown when onAction provided', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Empty',
              description: 'No data.',
              actionLabel: 'Add Now',
              onAction: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Add Now'), findsOneWidget);
      await tester.tap(find.text('Add Now'));
      expect(pressed, isTrue);
    });

    testWidgets('tapping action button fires callback', (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'No transactions',
              description: 'Add your first transaction.',
              icon: Icons.receipt_long_outlined,
              actionLabel: 'Add Transaction',
              onAction: () => tapCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add Transaction'));
      await tester.tap(find.text('Add Transaction'));
      expect(tapCount, 2);
    });
  });
}
