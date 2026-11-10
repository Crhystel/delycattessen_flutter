import 'dart:async';

import 'package:delycattessen_flutter/core/network/api_exception.dart';
import 'package:delycattessen_flutter/features/menu/models/menu_models.dart';
import 'package:delycattessen_flutter/features/menu/services/menu_service.dart';
import 'package:delycattessen_flutter/features/menu/services/product_catalog_source.dart';
import 'package:delycattessen_flutter/features/menu/widgets/product_catalog_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _inactive = ApiException(
  'El usuario está inactivo',
  statusCode: 401,
  code: 'user_inactive',
);

/// Todas las peticiones fallan como cuando la cuenta se desactiva con la
/// sesión abierta.
class _InactiveMenuService extends MenuService {
  @override
  Future<dynamic> performGetRequest(String url, {bool requiresAuth = true}) =>
      Future<dynamic>.error(_inactive);
}

class _InactiveCatalogSource implements ProductCatalogSource {
  @override
  String get id => 'inactive';

  @override
  String get allergyOwnerLabel => 'tus alergias';

  @override
  Future<List<MenuItem>> loadItems() => Future.error(_inactive);

  @override
  Future<CatalogOffers> loadOffers() => Future.error(_inactive);

  @override
  Future<Set<int>> loadAllergenIds() => Future.error(_inactive);
}

void main() {
  test(
    'getActiveOffers rethrows the error without leaving uncaught ones',
    () async {
      final uncaught = <Object>[];
      Object? thrown;

      await runZonedGuarded(() async {
        try {
          await _InactiveMenuService().getActiveOffers();
        } catch (e) {
          thrown = e;
        }
        // Deja correr los microtasks donde llegarían los errores sueltos.
        await Future<void>.delayed(Duration.zero);
      }, (error, _) => uncaught.add(error));

      expect(thrown, same(_inactive));
      expect(uncaught, isEmpty);
    },
  );

  testWidgets('ProductCatalogView shows the error without uncaught ones', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ProductCatalogView(source: _InactiveCatalogSource())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Un error asíncrono sin capturar haría fallar este test por sí solo.
    expect(tester.takeException(), isNull);
    expect(find.text('El usuario está inactivo'), findsOneWidget);
  });
}
