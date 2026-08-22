import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/screens/menu_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "D'Elycattessen",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B2D9E)),
        textTheme: GoogleFonts.nunitoTextTheme(),
        fontFamily: GoogleFonts.nunito().fontFamily,
      ),
      // Apuntamos directamente a MenuScreen para facilitar las pruebas
      // Asumimos el studentId 1 de prueba
      home: const MenuScreen(studentId: 1),
    );
  }
}
