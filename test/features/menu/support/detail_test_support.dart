import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phones from small to large and a tablet (logical dp).
const detailSizes = <String, Size>{
  'small phone 320x568': Size(320, 568),
  'phone 360x640': Size(360, 640),
  'large phone 411x891': Size(411, 891),
  'tablet 800x1280': Size(800, 1280),
};

const detailTextScales = [1.0, 2.0];

/// Shows [child] in a screen of [size] with the given text scale. [scroll]
/// wraps it in a scroll view with a page margin, like a detail screen does.
Future<void> pumpDetailPiece(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(411, 891),
  double textScale = 1.0,
  bool scroll = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: page!,
      ),
      home: Scaffold(
        body: scroll
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: child,
              )
            : child,
      ),
    ),
  );
}
