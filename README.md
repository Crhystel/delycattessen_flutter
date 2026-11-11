# delycattessen_flutter

A new Flutter project.

## Pipeline CI/CD

El pipeline vive en `.github/workflows/ci.yml` y se ve por etapas en la pestaña Actions:

```
1 · Análisis ─┐
              ├─► 3 · Build APK ─► 4 · Publicar
2 · Tests ────┘
```

- **1 · Análisis** (`flutter analyze`) y **2 · Tests** (`flutter test --coverage`) corren en paralelo en cada push o pull request hacia `main` y `develop`.
- **3 · Build APK** y **4 · Publicar** solo corren en push a `main`/`develop`, con un tag `v*` o manualmente (*Actions > Run workflow*). El APK queda como artefacto `delycattessen-apk` (7 días); con un tag `v1.0.0` se crea además un Release con el APK adjunto.
- La app toma su configuración de `env.example.json`. Para apuntar el APK al backend de staging, define la variable del repositorio `STAGING_API_URL` (*Settings > Secrets and variables > Actions > Variables*).
- El APK se firma con la clave de debug (TODO de `android/app/build.gradle.kts`): sirve para demos e instalación directa, no para publicar en Play Store.
- La versión de Flutter del CI está fijada en `FLUTTER_VERSION` (mismo valor que en local).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
