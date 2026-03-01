import 'package:flutter/material.dart' hide SafeArea, SliverSafeArea;
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

    // The inner box should have padding 30, not 50.
    final Finder boxFinder = find.byKey(const Key('inner'));
    final Size boxSize = tester.getSize(boxFinder);

    // Scaffold default size is 800x600.
    // Outer safe area applies 20 padding -> 760x560
    // Inner safe area applies max(30, 30-20) = 30 total -> 740x540
    expect(boxSize.width, 800 - 30 * 2);
    expect(boxSize.height, 600 - 30 * 2);
  });

  testWidgets('SliverSafeArea nested baseMinimum does not accumulate padding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverSafeArea(
                baseMinimum: EdgeInsets.all(20),
                sliver: SliverSafeArea(
                  baseMinimum: EdgeInsets.all(30),
                  sliver: SliverToBoxAdapter(child: SizedBox(key: Key('inner'), height: 100)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final Finder boxFinder = find.byKey(const Key('inner'));
    final Size boxSize = tester.getSize(boxFinder);

    // Width should be constrained strictly to viewport width 800 - 30*2 = 740
    expect(boxSize.width, 800 - 30 * 2);
    expect(boxSize.height, 100);
  });

  testWidgets('SafeArea nested in SliverSafeArea baseMinimum does not accumulate padding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverSafeArea(
                baseMinimum: EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: SafeArea(
                    baseMinimum: EdgeInsets.all(30),
                    child: SizedBox(key: Key('inner'), height: 100),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final Finder boxFinder = find.byKey(const Key('inner'));
    final Size boxSize = tester.getSize(boxFinder);

    expect(boxSize.width, 800 - 30 * 2);
    expect(boxSize.height, 100);
  });

  testWidgets('SliverSafeArea nested in SafeArea baseMinimum does not accumulate padding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(
            baseMinimum: EdgeInsets.all(20),
            child: CustomScrollView(
              slivers: [
                SliverSafeArea(
                  baseMinimum: EdgeInsets.all(30),
                  sliver: SliverToBoxAdapter(child: SizedBox(key: Key('inner'), height: 100)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final Finder boxFinder = find.byKey(const Key('inner'));
    final Size boxSize = tester.getSize(boxFinder);

    expect(boxSize.width, 800 - 30 * 2);
    expect(boxSize.height, 100);
  });
}
