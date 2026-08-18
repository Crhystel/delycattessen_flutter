import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_notification_dialog.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../../children/screens/children_list_screen.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _authService = AuthService();

  int _currentStep = 0; // 0 = datos del hijo, 1 = crear cuenta

  // Paso 1
  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _firstLastNameController = TextEditingController();
  final _secondLastNameController = TextEditingController();
  List<Institution> _institutions = [];
  Institution? _selectedInstitution;
  bool _isLoadingInstitutions = true;

  // Paso 2
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  File? _photo;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
  }

  Future<void> _loadInstitutions() async {
    try {
      final institutions = await _authService.getInstitutions();
      setState(() {
        _institutions = institutions;
        _isLoadingInstitutions = false;
      });
    } catch (e) {
      debugPrint('Error cargando instituciones: $e');
      setState(() => _isLoadingInstitutions = false);
    }
  }

  void _goToStep2() {
    if (_firstNameController.text.isEmpty ||
        _firstLastNameController.text.isEmpty ||
        _selectedInstitution == null) {
      AppNotificationDialog.show(
        context,
        type: NotificationType.warning,
        title: 'Faltan datos',
        message: 'Completa primer nombre, primer apellido e institución.',
      );
      return;
    }
    setState(() => _currentStep = 1);
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _submit() async {
    if (_photo == null) {
      AppNotificationDialog.show(
        context,
        type: NotificationType.warning,
        title: 'Falta la foto',
        message: 'La foto es obligatoria.',
      );
      return;
    }
    if (_usernameController.text.isEmpty ||
        _passwordController.text.length < 6) {
      AppNotificationDialog.show(
        context,
        type: NotificationType.warning,
        title: 'Datos incompletos',
        message: 'Usuario requerido y contraseña mínimo 6 caracteres.',
      );
      return;
    }
    if (!_acceptedTerms) {
      AppNotificationDialog.show(
        context,
        type: NotificationType.warning,
        title: 'Términos y condiciones',
        message: 'Debes aceptar los Términos y Condiciones.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _authService.registerStudent(
        StudentRegistration(
          firstName: _firstNameController.text.trim(),
          secondName: _secondNameController.text.trim(),
          firstLastName: _firstLastNameController.text.trim(),
          secondLastName: _secondLastNameController.text.trim(),
          institutionId: _selectedInstitution!.id,
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          profilePicturePath: _photo!.path,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ChildrenListScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppNotificationDialog.show(
        context,
        type: NotificationType.danger,
        title: 'No se pudo crear la cuenta',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _currentStep == 0 ? Colors.white : AppColors.teal500,
        elevation: 0,
        iconTheme: IconThemeData(
          color: _currentStep == 0 ? AppColors.ink900 : Colors.white,
        ),
        title: Text(
          'Registro',
          style: GoogleFonts.nunito(
            color: _currentStep == 0 ? AppColors.ink900 : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentStep == 0 ? 'Paso 1 de 2' : 'Paso 2 de 2',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.ink900.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: _currentStep == 0 ? 0.5 : 1.0,
                color: AppColors.brand500,
                backgroundColor: AppColors.ink50,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 20),
              if (_currentStep == 0) _buildStep1() else _buildStep2(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          debugPrint(
                            'Botón presionado, paso actual: $_currentStep',
                          );
                          _currentStep == 0 ? _goToStep2() : _submit();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentStep == 0 ? 'Siguiente' : 'Crear cuenta',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Datos de tu hijo/a',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.ink900,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Ingresa la información para asignar su cuenta',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.ink900.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _label('Primer Nombre'),
        _field(_firstNameController, 'Ingrese el primer nombre de su hijo/a'),
        const SizedBox(height: 16),
        _label('Segundo Nombre'),
        _field(_secondNameController, 'Ingrese el segundo nombre de su hijo/a'),
        const SizedBox(height: 16),
        _label('Primer Apellido'),
        _field(
          _firstLastNameController,
          'Ingrese el primer apellido de su hijo/a',
        ),
        const SizedBox(height: 16),
        _label('Segundo Apellido'),
        _field(
          _secondLastNameController,
          'Ingrese el segundo apellido de su hijo/a',
        ),
        const SizedBox(height: 16),
        _label('Institución'),
        _isLoadingInstitutions
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              )
            : DropdownButtonFormField<Institution>(
                value: _selectedInstitution,
                items: _institutions
                    .map((i) => DropdownMenuItem(value: i, child: Text(i.name)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedInstitution = value),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.secondary500,
                ),
                decoration: InputDecoration(
                  hintText: 'Selecciona la institución',
                  hintStyle: GoogleFonts.nunito(
                    color: AppColors.ink900.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.account_balance_outlined,
                    color: AppColors.secondary500,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.secondary500,
                      width: 1.4,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.secondary500,
                      width: 1.4,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.secondary700,
                      width: 1.8,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Crea la cuenta',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.ink900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Esta cuenta permitirá a tu hijo/a acceder a la aplicación',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: AppColors.ink900.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _pickPhoto,
            child: CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.ink50,
              backgroundImage: _photo != null ? FileImage(_photo!) : null,
              child: _photo == null
                  ? const Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.secondary500,
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _pickPhoto,
            child: Text(
              'Tomar Foto',
              style: GoogleFonts.nunito(
                color: AppColors.secondary500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Center(
          child: Text(
            'Puedes tomar una foto o elegir de la galería',
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: AppColors.ink900.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _label('Usuario'),
        TextField(
          controller: _usernameController,
          style: GoogleFonts.nunito(color: AppColors.ink900),
          decoration: _decoration('Ej. usuario123', icon: Icons.person_outline),
        ),
        const SizedBox(height: 16),
        _label('Contraseña'),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.nunito(color: AppColors.ink900),
          decoration: _decoration(
            'Mínimo 6 caracteres',
            icon: Icons.lock_outline,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Checkbox(
              value: _acceptedTerms,
              onChanged: (value) =>
                  setState(() => _acceptedTerms = value ?? false),
              activeColor: AppColors.secondary500,
            ),
            Expanded(
              child: Text(
                'Acepto Términos y Condiciones',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.ink900,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.secondary500,
      ),
    ),
  );

  Widget _field(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: GoogleFonts.nunito(color: AppColors.ink900),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(
          color: AppColors.ink900.withValues(alpha: 0.35),
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.secondary500,
            width: 1.4,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.secondary500,
            width: 1.4,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.secondary700,
            width: 1.8,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.ink900.withValues(alpha: 0.4))
          : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.ink50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
