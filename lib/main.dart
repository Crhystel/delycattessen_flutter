import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/auth_gate_screen.dart';
import 'features/children/providers/children_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
        theme: AppTheme.light(),
        home: const AuthGateScreen(),
      ),
    );
  }
}
