import 'package:cached_network_image/cached_network_image.dart';
import 'package:delycattessen_flutter/core/utils/app_image_cache_helper.dart';
import 'package:delycattessen_flutter/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _url = 'https://example.test/photo.jpg';
const _errorKey = Key('error');

Future<void> _pump(WidgetTester tester, Widget child, {double? maxWidth}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: maxWidth, child: child),
        ),
      ),
    ),
  );
}

CachedNetworkImage _cached(WidgetTester tester) =>
    tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

/// Exactly one cache side must be set, never both.
void _expectSingleSide(CachedNetworkImage image) {
  final sides = [image.memCacheWidth, image.memCacheHeight];
  expect(sides.where((s) => s != null), hasLength(1), reason: '$sides');
  expect(image.fit, BoxFit.cover);
}

int? _cacheFor(WidgetTester tester, double logical) {
  final context = tester.element(find.byType(AppNetworkImage));
  return AppImageCacheHelper.cacheSize(context, logical);
}

void main() {
  group('AppNetworkImage cache sides', () {
    testWidgets('square box caches one side with BoxFit.cover', (tester) async {
      await _pump(
        tester,
        const AppNetworkImage(url: _url, width: 100, height: 100),
      );

      final image = _cached(tester);
      _expectSingleSide(image);
      expect(
        image.memCacheWidth ?? image.memCacheHeight,
        _cacheFor(tester, 100),
      );
    });

    testWidgets('wide box caches only the width', (tester) async {
      await _pump(
        tester,
        const AppNetworkImage(url: _url, width: 200, height: 100),
      );

      final image = _cached(tester);
      _expectSingleSide(image);
      expect(image.memCacheWidth, _cacheFor(tester, 200));
      expect(image.memCacheHeight, isNull);
    });

    testWidgets('tall box caches only the height', (tester) async {
      await _pump(
        tester,
        const AppNetworkImage(url: _url, width: 100, height: 200),
      );

      final image = _cached(tester);
      _expectSingleSide(image);
      expect(image.memCacheHeight, _cacheFor(tester, 200));
      expect(image.memCacheWidth, isNull);
    });

    testWidgets('infinite width uses the available width', (tester) async {
      await _pump(
        tester,
        const AppNetworkImage(url: _url, width: double.infinity, height: 80),
        maxWidth: 300,
      );

      final image = _cached(tester);
      _expectSingleSide(image);
      expect(image.memCacheWidth, _cacheFor(tester, 300));
    });

    testWidgets('without sizes it measures the incoming constraints', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 120,
          height: 60,
          child: AppNetworkImage(url: _url),
        ),
      );

      final image = _cached(tester);
      _expectSingleSide(image);
      expect(image.memCacheWidth, _cacheFor(tester, 120));
    });

    testWidgets('circle clips to an oval and caches one side', (tester) async {
      await _pump(tester, const AppNetworkImage.circle(url: _url, size: 52));

      expect(find.byType(ClipOval), findsOneWidget);
      final image = _cached(tester);
      _expectSingleSide(image);
      expect(
        image.memCacheWidth ?? image.memCacheHeight,
        _cacheFor(tester, 52),
      );
    });
  });

  group('AppNetworkImage fallbacks', () {
    for (final url in <String?>[null, '']) {
      testWidgets('shows the error widget when url is "$url"', (tester) async {
        await _pump(
          tester,
          AppNetworkImage(
            url: url,
            width: 50,
            height: 50,
            error: const SizedBox(key: _errorKey),
          ),
        );

        expect(find.byKey(_errorKey), findsOneWidget);
        expect(find.byType(CachedNetworkImage), findsNothing);
      });
    }
  });
}
