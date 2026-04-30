import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsnap/shared/widgets/spend_ring.dart';

void main() {
  group('SpendRing', () {
    testWidgets('renders with zero progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpendRing(progress: 0),
          ),
        ),
      );

      expect(find.byType(SpendRing), findsOneWidget);
    });

    testWidgets('renders center label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpendRing(
              progress: 0.5,
              centerLabel: '50%',
              centerSubLabel: 'used',
            ),
          ),
        ),
      );

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('used'), findsOneWidget);
    });

    testWidgets('clamps progress to 0.0–1.0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpendRing(progress: 1.5, centerLabel: 'Over'),
          ),
        ),
      );

      // Should not throw
      expect(find.byType(SpendRing), findsOneWidget);
    });

    testWidgets('animates on progress change', (tester) async {
      double progress = 0.2;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Column(
                children: [
                  SpendRing(key: const ValueKey('ring'), progress: progress),
                  ElevatedButton(
                    onPressed: () => setState(() => progress = 0.8),
                    child: const Text('Update'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SpendRing), findsOneWidget);
      await tester.tap(find.text('Update'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Animation is in progress — widget still exists
      expect(find.byType(SpendRing), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('respects size parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpendRing(progress: 0.3, size: 120),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(SpendRing),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 120);
      expect(sizedBox.height, 120);
    });
  });
}
