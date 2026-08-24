import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Patrón Template Method: Define el wrapper estándar para pantallas tipo Menú/Catálogo.
class BaseMenuScreen extends StatelessWidget {
  final String title;
  final Widget bodyContent;
  final bool isLoading;
  final Widget? floatingActionButton;

  const BaseMenuScreen({
    Key? key,
    required this.title,
    required this.bodyContent,
    this.isLoading = false,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink50, // Fondo celeste claro
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.teal500,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // Contenido inyectado
          bodyContent,

          // Loader Overlay
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.brand500),
              ),
            ),
        ],
      ),
    );
  }
}
