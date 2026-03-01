import 'package:flutter/material.dart' hide SafeArea, SliverSafeArea;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safearea/safearea.dart';

void main() {
  group('SafeArea', () {
    testWidgets('SafeArea - nested baseMinimum does not accumulate padding', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.all(20.0)),
          child: SafeArea(
            baseMinimum: EdgeInsets.all(20),
            child: SafeArea(baseMinimum: EdgeInsets.all(30), child: Placeholder()),
          ),
        ),
      );

      // Outer safe area applies 20 padding -> 760x560 space remaining.
      // Inner safe area applies max(30, 30-20) = 30 total padding from edges -> 740x540
      expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(30.0, 30.0));
      expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(770.0, 570.0));
    });
  });

  group('SliverSafeArea', () {
    Widget buildWidget(EdgeInsets mediaPadding, Widget sliver) {
      late final ViewportOffset offset;
      addTearDown(() => offset.dispose());

      return MediaQuery(
        data: MediaQueryData(padding: mediaPadding),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Viewport(
            offset: offset = ViewportOffset.fixed(0.0),
            slivers: <Widget>[
              const SliverToBoxAdapter(
                child: SizedBox(width: 800.0, height: 100.0, child: Text('before')),
              ),
              sliver,
              const SliverToBoxAdapter(
                child: SizedBox(width: 800.0, height: 100.0, child: Text('after')),
              ),
            ],
          ),
        ),
      );
    }

    void verify(WidgetTester tester, List<Rect> expectedRects) {
      final List<Rect> testAnswers = tester
          .renderObjectList<RenderBox>(find.byType(SizedBox))
          .map<Rect>((RenderBox target) {
            final Offset topLeft = target.localToGlobal(Offset.zero);
            final Offset bottomRight = target.localToGlobal(target.size.bottomRight(Offset.zero));
            return Rect.fromPoints(topLeft, bottomRight);
          })
          .toList();
      expect(testAnswers, equals(expectedRects));
    }

    testWidgets('SliverSafeArea - nested baseMinimum does not accumulate padding', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          const EdgeInsets.all(20.0),
          const SliverSafeArea(
            baseMinimum: EdgeInsets.all(20),
            sliver: SliverSafeArea(
              baseMinimum: EdgeInsets.all(30),
              sliver: SliverToBoxAdapter(
                child: SizedBox(width: 800.0, height: 100.0, child: Text('padded')),
              ),
            ),
          ),
        ),
      );

      // Top padding total will be max(30, 30) = 30.
      verify(tester, <Rect>[
        const Rect.fromLTWH(0.0, 0.0, 800.0, 100.0),
        const Rect.fromLTWH(30.0, 130.0, 740.0, 100.0),
        const Rect.fromLTWH(0.0, 260.0, 800.0, 100.0), // 130 + 100 + 30 = 260
      ]);
    });

    testWidgets('SafeArea nested in SliverSafeArea baseMinimum does not accumulate padding', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          const EdgeInsets.all(20.0),
          const SliverSafeArea(
            baseMinimum: EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: SafeArea(
                baseMinimum: EdgeInsets.all(30),
                child: SizedBox(width: 800.0, height: 100.0, child: Text('padded')),
              ),
            ),
          ),
        ),
      );

      verify(tester, <Rect>[
        const Rect.fromLTWH(0.0, 0.0, 800.0, 100.0),
        const Rect.fromLTWH(
          30.0,
          130.0,
          740.0,
          100.0,
        ), // SizedBox is pushed 10px down internally by inner SafeArea
        const Rect.fromLTWH(
          0.0,
          260.0,
          800.0,
          100.0,
        ), // Inner SafeArea's box consumes space. Height 100 + 20 top padding (Sliver) + 10 top padding (inner) + 10 bottom padding (inner) + 20 bottom padding (Sliver)= 160 space. 100(before) + 160 = 260
      ]);
    });

    testWidgets('SliverSafeArea nested in SafeArea baseMinimum does not accumulate padding', (
      WidgetTester tester,
    ) async {
      late final ViewportOffset offset;
      addTearDown(() => offset.dispose());

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.all(20.0)),
          child: SafeArea(
            baseMinimum: EdgeInsets.all(20.0),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Viewport(
                offset: offset = ViewportOffset.fixed(0.0),
                slivers: const <Widget>[
                  SliverToBoxAdapter(
                    child: SizedBox(width: 800.0, height: 100.0, child: Text('before')),
                  ),
                  SliverSafeArea(
                    baseMinimum: EdgeInsets.all(30),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(width: 800.0, height: 100.0, child: Text('padded')),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(width: 800.0, height: 100.0, child: Text('after')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final List<Rect> testAnswers = tester
          .renderObjectList<RenderBox>(find.byType(SizedBox))
          .map<Rect>((RenderBox target) {
            final Offset topLeft = target.localToGlobal(Offset.zero);
            final Offset bottomRight = target.localToGlobal(target.size.bottomRight(Offset.zero));
            return Rect.fromPoints(topLeft, bottomRight);
          })
          .toList();

      // Outer safe area applies 20 padding natively inside the media constraints.
      // So viewport starts at x=20, y=20.
      expect(
        testAnswers,
        equals(<Rect>[
          const Rect.fromLTWH(20.0, 20.0, 760.0, 100.0),
          const Rect.fromLTWH(
            30.0,
            130.0,
            740.0,
            100.0,
          ), // SliverSafeArea adds 10 more padding, so x=30. y=20+100+10 = 130
          const Rect.fromLTWH(
            20.0,
            240.0,
            760.0,
            100.0,
          ), // SliverSafeArea bottom adds 10 padding. 130 + 100 + 10 = 240.
        ]),
      );
    });
  });
}
