import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';
import '../firebase_service.dart';

/**
 * Página de Edición de Perfil - Permite a los usuarios gestionar su información personal
 * 
 * Esta página proporciona un formulario completo para:
 * - Ver y editar información personal del usuario
 * - Actualizar datos demográficos y de contacto
 * - Gestionar información médica relevante
 * - Sincronizar cambios con Firebase Firestore
 */
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  // Controladores y servicios
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firebaseService = FirebaseService();

  // Controladores para cada campo del formulario
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _birthPlaceController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Estados de la UI
  bool _isLoading = false; // Indicador de carga inicial de datos
  bool _isSaving = false; // Indicador de guardado de cambios

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Cargar datos existentes al iniciar
  }

  /**
   * Carga los datos del usuario desde Firebase Firestore
   * - Obtiene información del usuario autenticado
   * - Rellena los campos del formulario con datos existentes
   * - Maneja errores de forma segura
   */
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Obtener datos adicionales del usuario desde Firestore
        final userData = await _firebaseService.obtenerUsuario(user.uid);

        if (userData != null) {
          setState(() {
            _nameController.text = userData['nombre'] ?? '';
            _ageController.text = userData['edad']?.toString() ?? '';
            _birthPlaceController.text = userData['lugar_nacimiento'] ?? '';
            _conditionsController.text = userData['padecimientos'] ?? '';
            _phoneController.text = userData['telefono'] ?? '';
          });
        }
      } catch (e) {
        print('Error cargando datos del usuario: $e');
        // Fallback: usar información básica de Firebase Auth
        _nameController.text =
            user.displayName ?? user.email?.split('@').first ?? '';
      }
    }

    setState(() => _isLoading = false);
  }

  /**
   * Maneja el proceso de guardado del perfil
   * - Valida el formulario
   * - Actualiza la información en Firestore
   * - Muestra feedback al usuario
   * - Navega de regreso tras éxito
   */
  Future<void> _saveProfile() async {
    // Validar formulario antes de proceder
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser!;
      if (user.uid.isEmpty) {
        throw Exception('Usuario no autenticado');
      }

      // GUARDAR EN COLECCIÓN USUARIOS DE FIRESTORE
      await _firebaseService.guardarUsuario(
        uid: user.uid,
        nombre: _nameController.text.trim(),
        email: user.email!,
        telefono: _phoneController.text.trim(),
        edad: int.tryParse(
          _ageController.text.trim(),
        ), // Conversión segura a int
        lugarNacimiento: _birthPlaceController.text.trim(),
        padecimientos: _conditionsController.text.trim(),
      );

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Perfil actualizado correctamente'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Esperar un momento para que el usuario vea el mensaje
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.pop(context); // Regresar a página anterior
      }
    } catch (e) {
      print('Error guardando perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Error al guardar: $e'),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      // Siempre detener el indicador de guardado
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /**
   * Limpia todos los campos del formulario
   * Útil para restablecer o empezar desde cero
   */
  void _clearForm() {
    _formKey.currentState?.reset();
    setState(() {
      _nameController.clear();
      _ageController.clear();
      _birthPlaceController.clear();
      _conditionsController.clear();
      _phoneController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Navegación hacia atrás
        ),
        actions: [
          // Mostrar acciones solo cuando no está cargando
          if (!_isLoading) ...[
            // Botón para limpiar formulario
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _clearForm,
              tooltip: 'Limpiar formulario',
            ),
            // Botón para guardar cambios
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveProfile,
              tooltip: 'Guardar cambios',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando datos del perfil...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header con información del perfil
                      _buildProfileHeader(),
                      const SizedBox(height: 24),

                      // Campos del formulario
                      _buildNameField(), // Nombre completo
                      const SizedBox(height: 16),

                      _buildAgeField(), // Edad
                      const SizedBox(height: 16),

                      _buildPhoneField(), // Teléfono
                      const SizedBox(height: 16),

                      _buildBirthPlaceField(), // Lugar de nacimiento
                      const SizedBox(height: 16),

                      _buildConditionsField(), // Condiciones médicas
                      const SizedBox(height: 30),

                      // Botones de acción principal
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /**
   * Construye el header del perfil con información del usuario
   * Muestra avatar, nombre, email e ID abreviado
   */
  Widget _buildProfileHeader() {
    final user = _auth.currentUser;
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppShadows.softShadow],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar del usuario
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [AppShadows.softShadow],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 35),
            ),
            const SizedBox(width: 16),
            // Información del usuario
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre (del formulario o datos existentes)
                  Text(
                    _nameController.text.isEmpty
                        ? user?.displayName ??
                              user?.email?.split('@').first ??
                              'Usuario'
                        : _nameController.text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Email del usuario
                  Text(
                    user?.email ?? 'No email',
                    style: TextStyle(fontSize: 14, color: AppColors.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // ID abreviado del usuario (seguridad)
                  Text(
                    'ID: ${user?.uid.substring(0, 8)}...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /**
   * Construye el campo de nombre completo
   * Campo requerido con validaciones de longitud
   */
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: 'Nombre completo *',
        labelStyle: const TextStyle(color: AppColors.textLight),
        hintText: 'Ingresa tu nombre completo',
        prefixIcon: Icon(Icons.person, color: AppColors.primaryPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa tu nombre';
        }
        if (value.length < 2) {
          return 'El nombre debe tener al menos 2 caracteres';
        }
        return null;
      },
    );
  }

  /**
   * Construye el campo de edad
   * Campo opcional con validación de rango
   */
  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: 'Edad',
        labelStyle: const TextStyle(color: AppColors.textLight),
        hintText: 'Ej: 25',
        prefixIcon: Icon(Icons.cake, color: AppColors.primaryPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final age = int.tryParse(value);
          if (age == null) {
            return 'Ingresa una edad válida';
          }
          if (age < 1 || age > 120) {
            return 'La edad debe estar entre 1 y 120 años';
          }
        }
        return null;
      },
    );
  }

  /**
   * Construye el campo de teléfono
   * Campo opcional sin validación estricta
   */
  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: 'Teléfono',
        labelStyle: const TextStyle(color: AppColors.textLight),
        hintText: 'Ej: +1234567890',
        prefixIcon: Icon(Icons.phone, color: AppColors.primaryPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  /**
   * Construye el campo de lugar de nacimiento
   * Campo opcional para información demográfica
   */
  Widget _buildBirthPlaceField() {
    return TextFormField(
      controller: _birthPlaceController,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: 'Lugar de nacimiento',
        labelStyle: const TextStyle(color: AppColors.textLight),
        hintText: 'Ej: Ciudad de México',
        prefixIcon: Icon(Icons.place, color: AppColors.primaryPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  /**
   * Construye el campo de condiciones médicas
   * Campo multilínea para información de salud
   */
  Widget _buildConditionsField() {
    return TextFormField(
      controller: _conditionsController,
      maxLines: 3, // Campo expandible para texto largo
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: 'Padecimientos o condiciones médicas',
        labelStyle: const TextStyle(color: AppColors.textLight),
        hintText:
            'Describe cualquier condición médica, alergia o padecimiento...',
        alignLabelWithHint: true, // Mejor alineación para campos multilínea
        prefixIcon: Icon(
          Icons.medical_services,
          color: AppColors.primaryPurple,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  /**
   * Construye los botones de acción principales
   * Diseño responsivo con Cancelar y Guardar
   */
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Botón Cancelar - Secundario
        Expanded(
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.textLight),
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textLight,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Botón Guardar - Primario
        Expanded(
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              gradient: _isSaving ? null : AppGradients.buttonGradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: _isSaving ? null : [AppShadows.softShadow],
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSaving ? Colors.grey : Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Guardar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Limpiar todos los controladores para evitar memory leaks
    _nameController.dispose();
    _ageController.dispose();
    _birthPlaceController.dispose();
    _conditionsController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
