# Arquitectura del proyecto — D'Elycattessen (Flutter)

Este documento explica cómo está organizado el código para que cualquier persona que se una al proyecto sepa **dónde poner cada cosa** sin duplicar archivos ni romper la estructura existente.

## Idea general: organización por *feature*, no por tipo de archivo

En vez de tener carpetas globales `screens/`, `models/`, `services/` con todo mezclado, cada módulo de negocio (login, menú, billetera, etc.) vive en su propia carpeta bajo `lib/features/`, con sus propias subcarpetas internas. Esto evita que un archivo de "menú" y uno de "auth" terminen en la misma carpeta genérica sin relación entre sí.

```
lib/
├── main.dart                # Punto de entrada de la app
├── core/                    # Código transversal, compartido por TODAS las features
│   ├── config/               # Configuración/env (claves públicas, flags)
│   ├── network/               # Cliente HTTP base, manejo de errores, endpoints
│   ├── storage/               # Persistencia local (tokens, etc.)
│   ├── theme/                 # Colores y estilos globales
│   └── widgets/               # Widgets reutilizables entre features (nav bar, dialogs...)
└── features/                 # Un módulo de negocio por carpeta
    ├── auth/                  # Login, registro de padres/estudiantes
    ├── children/               # Listado y detalle de hijos
    ├── menu/                   # Catálogo, carrito, detalle de producto, pre-órdenes
    ├── users/                   # Gestión de alergias/intolerancias
    └── wallet/                  # Recarga y billetera (Kushki/Payphone)
```

## Qué va dentro de cada `feature/<nombre>/`

Cada feature se subdivide siempre igual, en hasta 3 carpetas:

- **`models/`** — Clases de datos puras (`fromJson`/`toJson`). Sin lógica de red ni de UI.
- **`services/`** — Toda la comunicación con el backend (HTTP). Ningún widget debe llamar `http.get`/`http.post` directamente; siempre pasa por un `Service` de esta carpeta.
- **`screens/`** — Pantallas (widgets de UI) de esa feature. Consumen los `services/` y `models/` de la misma feature.

Ejemplo real (`features/auth/`):
```
auth/
├── models/auth_models.dart      # LoginRequest, LoginResponse, Institution, etc.
├── services/auth_service.dart   # AuthService extends BaseApiService
└── screens/login_screen.dart, parent_register_screen.dart, ...
```

Si una feature es muy simple y todavía no tiene servicio propio (ej. una pantalla de solo lectura), no crees una carpeta `services/` vacía — agrégala cuando exista el primer archivo que la necesite.

## Qué va en `core/` (y qué NO)

`core/` es solo para lo que se reutiliza en **más de una feature**. Antes de poner algo aquí, pregúntate: "¿esto lo usan al menos 2 módulos distintos?". Si la respuesta es no, va dentro de la feature correspondiente, no en `core/`.

| Carpeta | Contenido | Ejemplo actual |
|---|---|---|
| `core/config/` | Variables de entorno / configuración pública | `Env.kushkiPublicMerchantId` (via `String.fromEnvironment`) |
| `core/network/` | Cliente HTTP base y catálogo de endpoints | `BaseApiService`, `ErrorHandlerMixin`, `ApiConfig` |
| `core/storage/` | Persistencia local | `TokenStorage` (guarda/lee tokens JWT) |
| `core/theme/` | Colores y estilos compartidos | `AppColors` |
| `core/widgets/` | Widgets de UI reutilizables entre features | `CustomBottomNav`, `CustomHeaderShape`, `BaseMenuScreen`, `AppNotificationDialog`, `FloatingBubbles` |

## Patrones ya establecidos — reutilízalos, no los reinventes

- **`BaseApiService` + `ErrorHandlerMixin`** (`core/network/`): todo `Service` de una feature debe extender `BaseApiService`. Este ya trae `performGetRequest`, `performPostRequest`, `performPutRequest` y `performMultipartPostRequest`, con manejo de headers, token y errores centralizado. **No** escribas un nuevo servicio que arme `http.get`/`http.post` a mano — extiende `BaseApiService` como hace `AuthService`.
- **`ApiConfig`** (`core/network/api_config.dart`): todas las URLs del backend viven aquí como constantes/métodos estáticos. No hardcodees una URL dentro de un `Service` — agrégala a `ApiConfig` primero.
- **`TokenStorage`**: única fuente para leer/guardar el JWT. No dupliques el manejo de tokens en otra parte.

## Convenciones de nombres

- Un archivo por clase principal, nombre en `snake_case` (ej. `auth_service.dart` → `AuthService`).
- Sufijos consistentes: `*_screen.dart` (UI), `*_service.dart` (HTTP), `*_models.dart` o `*_model.dart` (datos).
- Los imports dentro del proyecto son relativos (`../../../core/...`), no uses paquete completo (`package:delycattessen_flutter/...`) salvo que ya se use así en el archivo que estés editando.

## Antes de crear un archivo nuevo, revisa esto para no duplicar

1. **¿Ya existe una carpeta de esta feature?** Revisa `lib/features/` antes de crear una nueva — reutiliza la existente si el módulo ya tiene una.
2. **¿Esto es HTTP?** Va en `services/` de la feature, extendiendo `BaseApiService`. La URL va primero en `ApiConfig`.
3. **¿Esto es un modelo de datos?** Va en `models/` de la feature, no dentro de `screens/`.
4. **¿Este widget se usa en más de una feature?** Va en `core/widgets/`. Si solo lo usa una pantalla, va junto a esa pantalla dentro de la misma feature (o inline si es pequeño).
5. **¿Es un secreto o configuración (API key, merchant ID, base URL sensible)?** Va vía `core/config/env.dart` con `String.fromEnvironment` / `--dart-define`, nunca hardcodeado en el widget o servicio. Ver `env.example.json` como referencia de qué variables existen.

## Notas de estado del proyecto

- Hubo una migración reciente de una estructura antigua (`lib/ui/...`, `lib/data/...`) hacia la estructura por feature descrita arriba. Si encuentras código nuevo bajo `lib/ui/` o `lib/data/`, probablemente es remanente de la estructura vieja — no agregues archivos ahí, muévelos/créalos siguiendo el patrón de `lib/features/` y `lib/core/`.
