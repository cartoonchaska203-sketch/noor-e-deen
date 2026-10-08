import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noor_e_deen/core/state/app_state.dart';
import 'package:noor_e_deen/features/tasbeeh/tasbeeh_screen.dart';

/// Widget test: the tasbeeh counter increments on tap.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.load();
  });

  Widget wrap() => AppStateScope(
        notifier: AppState.instance,
        child: const MaterialApp(home: TasbeehScreen()),
      );

  testWidgets('counter starts at 0 and increments on tap',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // Counter shows 0 initially.
    expect(find.text('0'), findsOneWidget);

    // Tap the counter button (the Semantics-labeled area).
    final counter = find.bySemanticsLabel(
        RegExp(r'Tasbeeh: 0 / 100'));
    expect(counter, findsOneWidget);
    await tester.tap(counter);
    await tester.pump();

    // Counter now shows 1.
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('undo restores the previous count', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    Future<void> tapCounter() async {
      // The semantics label includes the live count, so re-find each tap.
      final counter = find.bySemanticsLabel(RegExp(r'Tasbeeh: \d+ / 100'));
      expect(counter, findsOneWidget);
      await tester.tap(counter);
      await tester.pump();
    }

    await tapCounter();
    await tapCounter();
    expect(find.text('2'), findsOneWidget);

    // Tap undo (icon button).
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });
}
