import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/session/session_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/auth_gate_screen.dart';
import 'features/children/providers/children_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // De borde a borde (no inmersivo): el fondo cubre la barra de estado y la
  // zona de la cámara, y cada pantalla respeta el área segura. El modo
  // inmersivo hacía que los márgenes cambiaran al reaparecer las barras.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Ninguna excepción sin capturar (API, red o de programación) debe cerrar
  // la app: se registra y la app sigue funcionando.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChildrenProvider(),
      child: MaterialApp(
        title: "D'Elycattessen",
        debugShowCheckedModeBanner: false,
        navigatorKey: SessionManager.navigatorKey,
        theme: AppTheme.light(),
        home: const AuthGateScreen(),
      ),
    );
  }
}
