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
│   │              app_radius, app_theme, app_notification_style
│   ├── utils/     date_formatter, error_message, app_image_cache_helper
│   └── widgets/   app_bottom_sheet, app_card, app_confirmation_dialog,
│                  app_notification_dialog/messenger, app_scaffold, empty_state,
│                  light_app_bar, primary_button, child_avatar_chip, floating_bubbles,
│                  notification_header, photo_source_dialog, photo_guidelines_screen,
│                  face_capture_camera_screen
└── features/
    ├── auth/         Login, registro de padre y estudiante, recuperar/cambiar contraseña, rol (UserRole)
    ├── children/     Hijos del padre, control parental, ParentShell (navegación del padre), ChildrenProvider
    ├── contingency/  Pantalla de estudiante/docente y token QR dinámico
    ├── menu/         Menú mensual, carrito, pedidos, catálogo de productos
    ├── pos/          Caja: identificación (rostro/QR), venta, checkout, crédito del docente
    ├── users/        Gestión de alergias
    └── wallet/       Billetera, recargas (Payphone/Kushki), PIN de pago, historial de movimientos
```

## Qué lleva cada carpeta de una feature

| Carpeta | Contenido | Ejemplos |
|---|---|---|
| `models/` | Datos puros y enums | `Child`, `UserRole`, `RechargeGateway`, `DocumentType` |
| `services/` | Backend, pasarelas y flujos que orquestan servicios | `AuthService`, `WalletService`, `KushkiService`, `CardRechargeService` |
| `providers/` | Estado con `ChangeNotifier` | `ChildrenProvider`, `ParentMenuController`, `PreOrderDeliveryController` |
| `screens/` | Pantallas completas | `MenuScreen`, `PosCheckoutScreen` |
| `widgets/` | Widgets propios de la feature | `IdentifiedUserSheet`, `StatusCard`, `CustomBottomNav` |
| `utils/` | Reglas puras y helpers | `CartRules`, `PaymentMethodPolicy`, `RechargeLaunchers`, `routeAfterAuth` |

No se crean carpetas vacías: se agregan cuando existe el primer archivo.

## Qué va en `core/` (y qué no)

`core/` es solo para lo que se reutiliza en **más de una feature**. Pregunta antes de poner algo ahí: "¿lo usan al menos 2 módulos?". Si no, va en la feature. Por eso, por ejemplo, el escáner (`BaseScannerScreen`) vive en `pos`, el contador de requisitos de contraseña en `auth` y la barra inferior del padre en `children`.

`core/` **nunca importa de `features/`**.

## Patrones establecidos — reutilízalos

- **`BaseApiService` + `ErrorHandlerMixin`:** todo service de nuestro backend extiende `BaseApiService` (GET/POST/PUT/PATCH/multipart con token y errores centralizados). Los errores del backend llegan como `ApiException`; los de red como `NetworkException`. Para mostrarlos: `errorMessageOf(e)`.
- **`ApiConfig`:** todas las URLs del backend. La base viene de `Env.apiBaseUrl`.
- **`TokenStorage`:** única fuente del JWT.
- **Estrategia por pasarela:** `RechargeGateway` (la decide el backend) + `RechargeLauncher` por pasarela. Agregar una pasarela = un valor del enum y un launcher; la pantalla no cambia.
- **Políticas por tabla:** `PaymentMethodPolicy` decide qué métodos de pago se ofrecen según el rol. Agregar un método = una entrada en sus tablas.
- **Abstracciones por rol:** `AllergyOwner` y `ProductCatalogSource` evitan `if/else` por rol en las pantallas.
- **Lógica fuera de la pantalla:** si una pantalla empieza a calcular, validar o consultar resultados, extrae un `provider`/`service` (ejemplos: `ParentMenuController`, `CardRechargeService`, `PreOrderDeliveryController`) y deja a la pantalla solo pintar.
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
- Código en inglés; textos de cara al usuario en español.
- Todo controller, timer o listener se libera en `dispose()`; tras un `await` se comprueba `mounted` antes de usar `context`.

## Configuración y secretos

- Variables por `--dart-define` o `--dart-define-from-file=env.json`. `env.json` no se sube; `env.example.json` lista las variables: `API_BASE_URL`, `KUSHKI_PUBLIC_MERCHANT_ID`, `KUSHKI_BASE_URL`.
- Nunca se hardcodea una clave, token o URL sensible en un widget o service.

## Pruebas

`test/` replica la estructura de `lib/` (`test/features/<feature>/…` y `test/core/…`). Hay pruebas de políticas, reglas, modelos, providers y services. Los services se simulan heredando de la clase real o implementando su interfaz; HTTP con `MockClient`.

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
