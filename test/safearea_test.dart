import 'package:flutter/material.dart' hide SafeArea;
import 'package:flutter_test/flutter_test.dart';

import 'package:safearea/safearea.dart';

void main() {
  testWidgets('SafeArea nested baseMinimum does not accumulate padding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(
            baseMinimum: EdgeInsets.all(20),
            child: SafeArea(
              baseMinimum: EdgeInsets.all(30),
              child: SizedBox.expand(key: Key('inner')),
            ),
          ),
        ),
      ),
    );

    // The inner colored box should have padding 30, not 50.
    final coloredBoxFinder = find.byKey(const Key('inner'));
    final Size boxSize = tester.getSize(coloredBoxFinder);

    // Scaffold default size is 800x600.
    // Outer safe area applies 20 padding -> 760x560
    // Inner safe area applies max(30, 30-20) = 30 total -> 740x540
    expect(boxSize.width, 800 - 30 * 2);
    expect(boxSize.height, 600 - 30 * 2);
  });
}
