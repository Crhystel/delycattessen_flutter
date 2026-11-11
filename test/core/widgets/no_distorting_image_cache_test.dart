import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The one file allowed to mention both cache sides (it documents why not).
const _allowedFile = 'app_network_image.dart';

/// Returns the text inside the parentheses that open at [openIndex].
String _callArguments(String source, int openIndex) {
  var depth = 0;
  for (var i = openIndex; i < source.length; i++) {
    final char = source[i];
    if (char == '(') depth++;
    if (char == ')') {
      depth--;
      if (depth == 0) return source.substring(openIndex + 1, i);
    }
  }
  return source.substring(openIndex + 1);
}

/// Why [source] would distort a photo, or null when it is fine.
String? distortionIn(String source) {
  if (source.contains('memCacheWidth') && source.contains('memCacheHeight')) {
    return 'memCacheWidth together with memCacheHeight';
  }
  for (final match in RegExp(r'ResizeImage\(').allMatches(source)) {
    final args = _callArguments(source, match.end - 1);
    final fixesBoth = args.contains('width:') && args.contains('height:');
    if (fixesBoth && !args.contains('policy: ResizeImagePolicy.fit')) {
      return 'ResizeImage with width and height without ResizeImagePolicy.fit';
    }
  }
  return null;
}

void main() {
  group('distortionIn', () {
    test('flags both memCache sides', () {
      expect(
        distortionIn('CachedNetworkImage(memCacheWidth: 1, memCacheHeight: 1)'),
        isNotNull,
      );
    });

    test('accepts a single memCache side', () {
      expect(distortionIn('CachedNetworkImage(memCacheWidth: 1)'), isNull);
    });

    test('flags ResizeImage with both sides and the exact policy', () {
      expect(
        distortionIn(
          'ResizeImage(CachedNetworkImageProvider(u), width: 1, height: 1)',
        ),
        isNotNull,
      );
    });

    test('accepts ResizeImage with both sides and the fit policy', () {
      expect(
        distortionIn(
          'ResizeImage(p, width: 1, height: 1, policy: ResizeImagePolicy.fit)',
        ),
        isNull,
      );
    });

    test('accepts ResizeImage with one side', () {
      expect(distortionIn('ResizeImage(p, width: 1)'), isNull);
    });
  });

  test('no file in lib/ decodes photos to exact width and height', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (path.endsWith('/$_allowedFile')) continue;
      final reason = distortionIn(entity.readAsStringSync());
      if (reason != null) offenders.add('$path: $reason');
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These files stretch photos. Use AppNetworkImage (one cache side):\n'
          '${offenders.join('\n')}',
    );
  });
}
