# Arquitectura del proyecto — D'Elycattessen (Flutter)

Este documento explica cómo está organizado el código para que cualquier persona que se una al proyecto sepa **dónde poner cada cosa** y bajo qué reglas se desarrolla.

## Idea general: organización por *feature*, no por tipo de archivo

Cada módulo de negocio vive en su carpeta bajo `lib/features/`, con sus propias subcarpetas. Lo que usan **dos o más features** va en `lib/core/`.

```
lib/
├── main.dart
├── core/
│   ├── config/    env.dart                      Variables de entorno (--dart-define)
│   ├── layout/    responsive.dart               AppLayout, ResponsiveCenter (tablet)
│   ├── network/   api_config, api_exception,    Endpoints, errores tipados, cliente HTTP base
│   │              base_api_service, error_handler_mixin
│   ├── storage/   token_storage.dart            Único acceso al JWT
│   ├── theme/     app_colors, app_spacing,      Tokens de diseño y tema
│   │              app_radius, app_theme, app_notification_style,
│   │              app_text (escala tipográfica Nunito del rediseño, opt-in)
│   ├── utils/     date_formatter, error_message, app_image_cache_helper
│   └── widgets/   app_bottom_sheet, app_card, app_confirmation_dialog,
│                  app_notification_dialog/messenger, app_scaffold, empty_state,
│                  light_app_bar, primary_button, child_avatar_chip, floating_bubbles,
│                  header_actions (botones de cuenta del encabezado de caja y estudiante/docente),
│                  profile_bubble (burbuja de perfil de las pestañas del padre),
│                  tab_header (cabecera de inicio y pestañas: texto a la izquierda y burbuja/acción
│                  a la derecha anclada siempre a la misma altura), subpage_header (cabecera de subpantallas),
│                  greeting_text (saludo único: fecha arriba y "¡Hola, X!" debajo, en todas las vistas con saludo),
│                  app_network_image (ÚNICA forma de cargar fotos de red: siempre BoxFit.cover y nunca
│                  ancho y alto de caché a la vez, que estira la foto), dashed_border,
│                  segmented_switch (selector de 2–3 opciones: Menú del mes | Productos, Recargar | Movimientos), form_page,
│                  collapsing_header (sliver de cabecera que se encoge pegado al scroll,
│                  sin animaciones por tiempo; deja fija la parte "kept" y vuelve solo al inicio),
│                  collapsing_scroll_view (el CustomScrollView que lo aloja: con 2 o más elementos el
│                  encabezado SIEMPRE se pliega por completo —añade el recorrido que falte— y al soltar
│                  termina plegado o expandido, nunca a medias; con 0 o 1 elemento no se pliega) y
│                  collapsing_fold_scope (aviso opcional de cuánto se pliega),
│                  form_section_card, profile_summary_card, labeled_text_field,
│                  notification_header, photo_source_dialog, photo_guidelines_screen,
│                  face_capture_camera_screen,
│                  terms_checkbox (casilla "Acepto los términos y condiciones"; con `termsUrl` el texto es un
│                  enlace con ícono que abre el documento en un WebView: la recarga con Kushki)
└── features/
    ├── auth/         Login, registro de padre y estudiante, recuperar/cambiar contraseña, Mi perfil (padre y docente: menú con flechita a nombres, correo —pide la contraseña actual—, contraseña y, solo docente, alergias), rol (UserRole)
    ├── children/     Hijos del padre (incluye editar sus datos y su foto, y darlos de baja con `DeactivateChildScreen`: lista las condiciones — sin saldo, sin preórdenes pendientes ni recarga en proceso —, pide la contraseña del padre y vuelve al inicio o al registro si no queda ninguno; `ChildrenProvider.removeChild` lo saca de la lista y el menú cambia de hijo sin preguntar por el carrito), control parental (límite diario, días y aviso de saldo bajo), ParentShell (navegación del padre, burbuja de perfil y cierre de sesión), Inicio con el título "Avisos" (y su contador) sobre las alertas de saldo bajo y la recarga rápida, barra y hoja "¿Para quién?" para cambiar de hijo, ChildrenProvider
    ├── contingency/  Inicio de estudiante y docente (saludo único, QR dinámico para identificarse en caja; el estudiante ve el menú del mes y los productos, el docente los productos y su crédito; todo de solo lectura) y token QR dinámico
    ├── menu/         Menú mensual, carrito, pedidos, catálogo de productos y sus ofertas (combos con sus platillos, dentro del scroll de la lista; tocar un combo abre su detalle como el de un producto, y la cabecera del catálogo se encoge pegada al scroll; en el Menú del mes solo quedan fijos los días y el buscador; los días se cortan a 20 px del borde y se centra el elegido). El menú del mes es UNA sola vista, `MonthlyMenuView` (burbujas decorativas, cabecera plegable, buscador, días): `MenuScreen` (padre, con carrito y selector de hijo) y `MemberMenuScreen` (estudiante, solo lectura) solo le pasan datos y callbacks; `MenuCartBar` es su barra de pedido, `MonthlyMenuOrdering` agrupa las acciones de pedir (nulo = solo lectura) y `MonthlyMenuDayHeading` el encabezado del día. Stock de combos: el combo no tiene stock propio; el backend manda `available_quantity` por combo y `stock` por ítem (campos aditivos: si faltan, el combo se considera disponible). `Combo.isAvailable` es el dato derivado, y `CatalogOffers.visibleCombos` deja fuera los agotados en las superficies solo informativas (padre, estudiante, docente), que muestran "Quedan N" / "Última unidad" con `CatalogStockBadges.low`; el POS muestra todos los combos, el agotado atenuado con "Agotado" y sin botón de agregar, y el stock exacto ("Stock: N", `CatalogStockBadges.exact`). El umbral de "pocas unidades" vive solo en `LowStockRule` y lo comparten productos y combos Vista del padre: los combos van en un carrusel (`ComboCarousel`), Pedidos muestra la foto de cada pedido con filtro por mes y el detalle es tipo factura
    ├── pos/          Caja: identificación (rostro/QR), venta, checkout, crédito del docente. El inicio de caja sigue el rediseño en tres variantes (teléfono, tablet horizontal y tablet vertical) con todas sus medidas en `PosHomeMetrics` (`PosOptionCard` y `PosQuickSaleButton` pintan lo que esa clase dicta)
    ├── users/        Gestión de alergias
    └── wallet/       Billetera, recargas (Payphone/Kushki), PIN de pago, historial de movimientos
```

## Qué lleva cada carpeta de una feature

| Carpeta | Contenido | Ejemplos |
|---|---|---|
| `models/` | Datos puros y enums | `Child`, `UserRole`, `RechargeGateway`, `DocumentType` |
| `services/` | Backend, pasarelas y flujos que orquestan servicios | `AuthService`, `WalletService`, `KushkiService`, `CardRechargeService` |
| `providers/` | Estado con `ChangeNotifier` | `ChildrenProvider`, `ParentMenuController`, `PreOrderDeliveryController`, `PosCartController` |
| `screens/` | Pantallas completas | `MenuScreen`, `PosCheckoutScreen` |
| `widgets/` | Widgets propios de la feature | `IdentifiedUserSheet`, `StatusCard`, `CustomBottomNav` |
| `utils/` | Reglas puras y helpers | `CartRules`, `PaymentMethodPolicy`, `RechargeLaunchers`, `routeAfterAuth` |

No se crean carpetas vacías: se agregan cuando existe el primer archivo.

## Qué va en `core/` (y qué no)

`core/` es solo para lo que se reutiliza en **más de una feature**. Pregunta antes de poner algo ahí: "¿lo usan al menos 2 módulos?". Si no, va en la feature. Por eso, por ejemplo, el escáner (`BaseScannerScreen`) vive en `pos`, el contador de requisitos de contraseña en `auth` y la barra inferior del padre en `children`.

`core/` **nunca importa de `features/`**.

## Patrones establecidos — reutilízalos

- **`BaseApiService` + `ErrorHandlerMixin`:** todo service de nuestro backend extiende `BaseApiService` (GET/POST/PUT/PATCH/multipart con token y errores centralizados). Los errores del backend y de red llegan como `ApiException` con un mensaje ya legible. Para mostrarlos: `errorMessageOf(e)`. El error de red es un mensaje corto ("Error de conexión: Revisa tu internet…"); el detalle técnico (host, excepción) solo va al log. Las pantallas lo muestran con `NotificationMixin`, no como texto suelto.
- **`ApiConfig`:** todas las URLs del backend. La base viene de `Env.apiBaseUrl`.
- **`TokenStorage`:** única fuente del JWT. La sesión de la app persiste hasta que el usuario cierra sesión o el refresh es rechazado; no existe cierre por inactividad (la web sí lo tiene).
- **Estrategia por pasarela:** `RechargeGateway` (la decide el backend) + `RechargeLauncher` por pasarela. Agregar una pasarela = un valor del enum y un launcher; la pantalla no cambia.
- **Políticas por tabla:** `PaymentMethodPolicy` decide qué métodos de pago se ofrecen según el rol. Agregar un método = una entrada en sus tablas.
- **Abstracciones por rol:** `AllergyOwner` y `ProductCatalogSource` evitan `if/else` por rol en las pantallas.
- **Lógica fuera de la pantalla:** si una pantalla empieza a calcular, validar o consultar resultados, extrae un `provider`/`service` (ejemplos: `ParentMenuController`, `CardRechargeService`, `PreOrderDeliveryController`, `PosCartController` — el carrito de caja con productos y combos, compartido por el menú y el checkout del POS) y deja a la pantalla solo pintar.
- **Términos y condiciones:** el registro del padre, el del hijo y el cambio de foto del hijo (diálogo previo en `EditChildScreen`) exigen la casilla `TermsCheckbox` y envían `accept_terms`; el backend guarda la versión aceptada y la fecha como evidencia legal. La recarga con Kushki enlaza sus términos.
- **Stock fresco en caja:** `PosMenuScreen` recarga el catálogo al volver del checkout, al fallar un cobro y al volver la app a primer plano; `PosCartController.setCatalog` reconstruye el carrito sobre el stock nuevo y devuelve los nombres ajustados para avisar al cajero.
- **Regla única de stock en caja:** `PosCartController` decide si algo se puede agregar. El stock de un producto sale del catálogo del POS o, si no está en él, del `stock` del ítem del combo (con ninguno de los dos se rechaza, por seguridad); stock 0 es agotado, como lo trata el servidor; un combo además se limita a su `availableQuantity` contando lo que ya hay en el carrito, y un producto suelto y el mismo dentro de un combo suman juntos. El menú y el checkout usan la misma validación.
- **El detalle nunca se oculta por alérgenos:** los tres detalles (`ProductDetailScreen`, `ComboDetailScreen`, `DishDetailScreen`) se abren siempre; lo que se bloquea es la compra. Cada anfitrión (catálogo, POS, menú mensual) arma un `AllergenAdvisory` (alérgenos del ítem, conflictos de quien consulta y a quién se le habla: el hijo, el cliente del POS, "tú" o nadie) con funciones puras (`catalog_allergens`, `dish_allergens`, `CustomerAllergenCheck`) y lo pasa al detalle, que siempre pinta `AllergenSectionCard` (caja roja con conflicto, verde sin él, solo chips si no se sabe quién consulta). Con conflicto y `onAdd` la barra inferior es `BlockedPurchaseBar` ("No disponible para Pepito", y en el plato "Pedir para otro hijo", que abre el selector de hijos). Las guardas de `PosCartController` y de `MenuScreen` se conservan: un ítem con alérgenos del cliente jamás llega al carrito.
- **Movimientos alineados y con saldo:** todas las filas de `TransactionRow` (recarga, consumo y fallida) comparten la misma columna final (la flecha, porque todas abren detalle), así el borde derecho del monto es el mismo. Debajo del monto, en tenue, la fila muestra "Saldo $X" (el que quedó después del movimiento) cuando llega `balance_after` del backend, alineado al mismo borde derecho; sin él (crédito del docente, backend antiguo, pendiente o fallida) no se muestra nada. Los detalles (comprobante y hoja de recarga) no repiten el saldo. "Pidiendo para" (`ChildOrderingRow`) muestra la foto del hijo con las iniciales de respaldo.
- **Detalle con `DetailScaffold`:** foto, etiqueta (`DetailTag`), hoja redondeada, cuadrícula de datos (`DetailInfoGrid`), tarjetas (`DetailSectionCard`), "También en combo" / "Otros combos" y barra inferior fija comparten piezas en `menu/widgets/`; una pantalla de detalle nueva las compone, no las copia.
- **Inyección por constructor:** los providers y services nuevos reciben sus dependencias con valor por defecto, para poder simularlas en tests.

## Reglas de capas

- Ninguna pantalla ni widget llama `http.*`: todo pasa por un `service`.
- Las URLs del backend solo existen en `ApiConfig`; el JWT solo se toca vía `TokenStorage` (cerrar sesión: `AuthService.logout()`).
- `core/` no importa de `features/`. Una feature puede usar `models/`, `services/` o `providers/` de otra, evitando crear ciclos nuevos.
- Los modelos no tienen lógica de red ni de UI; los services y providers no usan `BuildContext`.
- Para mostrar un error al usuario se usa `errorMessageOf(e)`.

## Convenciones de código

- Un archivo por clase principal, en `snake_case`, con sufijos `*_screen`, `*_service`, `*_model(s)`, `*_provider` o `*_controller`, `*_policy`, `*_rules`.
- Imports relativos dentro de `lib/`; `package:delycattessen_flutter/...` solo en `test/`.
- Colores, espacios y radios solo desde `AppColors`, `AppSpacing`, `AppRadius` y `AppTheme`.
- Código y comentarios en inglés; textos de cara al usuario en español. Comentarios breves (una o dos líneas) y solo cuando explican un porqué no obvio.
- Todo controller, timer o listener se libera en `dispose()`; tras un `await` se comprueba `mounted` antes de usar `context`.

## Configuración y secretos

- Variables por `--dart-define` o `--dart-define-from-file=env.json`. `env.json` no se sube; `env.example.json` lista las variables: `API_BASE_URL`, `KUSHKI_PUBLIC_MERCHANT_ID`, `KUSHKI_BASE_URL`.
- Nunca se hardcodea una clave, token o URL sensible en un widget o service.

## Recursos gráficos

Las imágenes y logos van en `assets/images/` (declarada en `pubspec.yaml`) y los SVG se dibujan con `flutter_svg`. Ejemplo: el logo de Kushki (`kushki_logo.svg`) se muestra con `KushkiBadge` en el formulario de tarjeta. Se usa solo para identificar a la pasarela; los logos de terceros no se modifican.

## Pruebas

`test/` replica la estructura de `lib/` (`test/features/<feature>/…` y `test/core/…`). Hay pruebas de políticas, reglas, modelos, providers y services. Los services se simulan heredando de la clase real o implementando su interfaz; HTTP con `MockClient`. Un test guardia (`test/core/widgets/no_distorting_image_cache_test.dart`) falla si alguien vuelve a fijar ancho y alto de caché a la vez en una foto: las fotos de red se cargan con `AppNetworkImage`.

## Antes de crear un archivo nuevo

1. ¿Ya existe una carpeta de esta feature? Reutilízala.
2. ¿Es HTTP? → `services/` de la feature, extendiendo `BaseApiService`; la URL primero en `ApiConfig`.
3. ¿Es un modelo? → `models/`.
4. ¿Es estado o lógica de una pantalla? → `providers/` o `services/`.
5. ¿Lo usan 2+ features? → `core/`; si no, junto a la pantalla que lo usa.
6. ¿Es un secreto o configuración? → `core/config/env.dart` y `env.example.json`.

## Git

- Ramas `main` y `develop`; se trabaja sobre `develop`.
- Conventional Commits en español (`feat:`, `fix:`, `refactor:`, `test:`, `style:`, `docs:`), con la historia de usuario cuando aplique.
- Un commit por cambio lógico: no se mezclan refactor, formato y funcionalidad nueva. Antes de entregar: `flutter analyze` y `flutter test`. Formatea solo los archivos que tocaste.

## Estado actual y deuda conocida

- Ciclos entre features (`auth`↔`children`, `menu`↔`children`, `menu`↔`wallet`, `auth`↔`pos`) y `ChildrenProvider` compartido desde `children` por `menu` y `wallet`.
- Unos 25 sitios aún crean sus services con `XService()` dentro de pantallas; se migra a inyección por constructor, empezando por wallet y POS. `BaseApiService` tampoco admite un `http.Client` inyectable.
- Pantallas largas que aún mezclan UI y llamadas a services: `children_list_screen`, `wallet_recharge_screen`, `member_home_screen`, `orders_screen`.
- Colores y radios escritos a mano que deberían estar en `AppColors`/`AppRadius`; textos fijos en español sin localización.
