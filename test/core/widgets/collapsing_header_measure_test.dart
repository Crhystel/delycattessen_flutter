import 'package:delycattessen_flutter/core/widgets/collapsing_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts how many times its build runs.
class _Probe extends StatelessWidget {
  const _Probe({required this.label, required this.height, required this.log});

  final String label;
  final double height;
  final List<String> log;

  @override
  Widget build(BuildContext context) {
    log.add(label);
    return SizedBox(height: height, child: Text(label));
  }
}

Widget _app({
  required List<String> log,
  double topInset = 0,
  CollapsingHeaderKeep keep = CollapsingHeaderKeep.bottom,
}) => MaterialApp(
  home: Scaffold(
    body: CustomScrollView(
      slivers: [
        CollapsingHeader(
          keep: keep,
          topInset: topInset,
          kept: _Probe(label: 'kept', height: 50, log: log),
          collapsible: _Probe(label: 'collapsible', height: 120, log: log),
        ),
        SliverList.builder(
          itemCount: 40,
          itemBuilder: (_, i) => SizedBox(
            key: i == 0 ? const Key('first-row') : null,
            height: 60,
            child: Text('fila $i'),
          ),
        ),
      ],
    ),
  ),
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('once measured, a rebuild builds the header content only once', (
    tester,
  ) async {
    _phone(tester);
    final log = <String>[];
    await tester.pumpWidget(_app(log: log));
    await tester.pump(); // the measured sizes arrive after the first frame
    await tester.pump();

    log.clear();
    await tester.pumpWidget(_app(log: log));

    // Before: kept and collapsible were built three times each (content and
    // two measuring prototypes). Now they are built once.
    expect(log.where((l) => l == 'kept'), hasLength(1));
    expect(log.where((l) => l == 'collapsible'), hasLength(1));
  });

  testWidgets('the extents are the same before and after measuring', (
    tester,
  ) async {
    _phone(tester);
    final log = <String>[];
    await tester.pumpWidget(_app(log: log));
    final firstFrame = tester.getTopLeft(find.byKey(const Key('first-row'))).dy;

    await tester.pump();
    await tester.pump();

    expect(firstFrame, 170);
    expect(tester.getTopLeft(find.byKey(const Key('first-row'))).dy, 170);
  });

  for (final keep in CollapsingHeaderKeep.values) {
    testWidgets('topInset (${keep.name}) is kept above the pinned part', (
      tester,
    ) async {
      _phone(tester);
      final log = <String>[];
      await tester.pumpWidget(_app(log: log, topInset: 30, keep: keep));
      await tester.pump();
      await tester.pump();

      // Expanded: the whole header plus the inset.
      expect(tester.getTopLeft(find.byKey(const Key('first-row'))).dy, 200);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Folded: only the kept part, under the inset (never at y = 0).
      final kept = find.text('kept').hitTestable();
      expect(tester.getTopLeft(kept).dy, 30);
      expect(find.text('collapsible').hitTestable(), findsNothing);
    });
  }

  testWidgets('a content that grows after the first layout re-measures', (
    tester,
  ) async {
    _phone(tester);
    final log = <String>[];
    Widget app(double keptHeight) => MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            CollapsingHeader(
              kept: _Probe(label: 'kept', height: keptHeight, log: log),
              collapsible: _Probe(label: 'collapsible', height: 120, log: log),
            ),
            SliverList.builder(
              itemCount: 40,
              itemBuilder: (_, i) => SizedBox(
                key: i == 0 ? const Key('first-row') : null,
                height: 60,
                child: Text('fila $i'),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(app(50));
    await tester.pump();
    await tester.pump();
    await tester.pumpWidget(app(90));
    await tester.pump();
    await tester.pump();

    expect(tester.getTopLeft(find.byKey(const Key('first-row'))).dy, 210);
  });
}
