import 'package:flutter/material.dart';

import '../services/product_catalog_source.dart';
import '../widgets/product_catalog_view.dart';

/// Catálogo de productos de la sede del docente (solo consulta).
class TeacherProductsScreen extends StatefulWidget {
  const TeacherProductsScreen({super.key});

  @override
  State<TeacherProductsScreen> createState() => _TeacherProductsScreenState();
}

class _TeacherProductsScreenState extends State<TeacherProductsScreen> {
  // Una sola instancia: la vista recarga solo cuando cambia el `id` de la fuente.
  final ProductCatalogSource _source = TeacherCatalogSource();

  @override
  Widget build(BuildContext context) {
    return ProductCatalogView(source: _source, showBackButton: true);
  }
}
