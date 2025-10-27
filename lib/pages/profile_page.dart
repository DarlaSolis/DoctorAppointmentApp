import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_colors.dart';
import '../routes.dart';

/**
 * Página de Registro de Usuario - Permite crear nuevas cuentas en la aplicación
 * 
 * Esta página maneja el proceso completo de registro:
 * - Validación de formulario de email y contraseña
 * - Creación de usuario en Firebase Authentication
 * - Almacenamiento de datos básicos en Firestore
 * - Navegación automática al home tras registro exitoso
 * - Manejo de errores específicos de Firebase Auth
 */
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  // Controladores y servicios
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Estados de la UI
  bool _isLoading = false; // Indicador de carga durante registro
  bool _obscureText = true; // Control de visibilidad de contraseña

  // Animaciones
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Configurar animaciones de entrada
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 800,
      ), // Duración media para suavidad
    );

    // Animación de fade in gradual
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Animación de deslizamiento desde abajo
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    // Iniciar animaciones automáticamente
    _animationController.forward();
  }

  @override
  void dispose() {
    // Limpiar recursos para evitar memory leaks
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /**
   * Maneja el proceso completo de registro de usuario
   * - Valida el formulario
   * - Crea usuario en Firebase Authentication
   * - Guarda datos básicos en Firestore
   * - Navega al home en caso de éxito
   * - Maneja errores específicos de Firebase
   */
  Future<void> _register() async {
    // Validar formulario antes de proceder
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Crear usuario en Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Obtener el UID del usuario recién creado
      final user = userCredential.user!;

      // Guardar datos básicos en Firestore usando el UID correcto
      await _firestore.collection('usuarios').doc(user.uid).set({
        'nombre':
            user.email?.split('@').first ??
            'Usuario', // Nombre por defecto del email
        'email': user.email,
        'fecha_creacion':
            FieldValue.serverTimestamp(), // Timestamp del servidor
        'ultima_actualizacion': FieldValue.serverTimestamp(),
      });

      // Navegar al home limpiando el stack de navegación
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } on FirebaseAuthException catch (e) {
      // Manejar errores específicos de Firebase Auth
      String message = 'Error al registrarse';
      if (e.code == 'email-already-in-use') {
        message = 'El correo ya está en uso.';
      } else if (e.code == 'weak-password') {
        message = 'La contraseña es muy débil.';
      } else if (e.code == 'invalid-email') {
        message = 'El correo no es válido.';
      }

      if (mounted) {
        _showErrorSnackbar(message);
      }
    } catch (e) {
      // Manejar errores genéricos
      if (mounted) {
        _showErrorSnackbar('Error inesperado: $e');
      }
    } finally {
      // Siempre detener el loading indicator
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /**
   * Muestra un mensaje de error en forma de Snackbar
   * @param message Mensaje de error a mostrar
   */
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /**
   * Alterna entre mostrar y ocultar la contraseña
   */
  void _togglePasswordVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context), // Navegación hacia atrás
        ),
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildAnimatedIcon(), // Ícono animado
                  const SizedBox(height: 30),
                  _buildRegisterCard(), // Tarjeta de registro
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /**
   * Construye el ícono animado de registro
   * Círculo con gradiente e ícono de "añadir persona"
   */
  Widget _buildAnimatedIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [AppShadows.mediumShadow],
      ),
      child: const Icon(Icons.person_add_alt_1, size: 40, color: Colors.white),
    );
  }

  /**
   * Construye la tarjeta principal del formulario de registro
   * Contiene título, campos de entrada y botones de acción
   */
  Widget _buildRegisterCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.cardGradient,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [AppShadows.softShadow],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título con gradiente
              Text(
                'Crear Cuenta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  foreground: Paint()
                    ..shader = AppGradients.primaryGradient.createShader(
                      const Rect.fromLTWH(0, 0, 200, 70),
                    ),
                ),
              ),
              const SizedBox(height: 8),
              // Subtítulo informativo
              Text(
                'Completa tus datos para registrarte',
                style: TextStyle(fontSize: 16, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Campos del formulario
              _buildEmailField(), // Campo de email
              const SizedBox(height: 20),
              _buildPasswordField(), // Campo de contraseña
              const SizedBox(height: 30),

              // Botón de registro
              _buildRegisterButton(),
              const SizedBox(height: 20),

              // Sección de login para usuarios existentes
              _buildLoginSection(),
            ],
          ),
        ),
      ),
    );
  }

  /**
   * Construye el campo de entrada para el email
   * Incluye validación de formato de email
   */
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: 'Correo electrónico',
        labelStyle: const TextStyle(color: AppColors.textLight),
        prefixIcon: Icon(Icons.email_rounded, color: AppColors.primaryPurple),
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
      validator: (value) => value!.isEmpty || !value.contains('@')
          ? 'Ingrese un correo válido'
          : null,
    );
  }

  /**
   * Construye el campo de entrada para la contraseña
   * Incluye toggle de visibilidad y validación de longitud
   */
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscureText,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        labelStyle: const TextStyle(color: AppColors.textLight),
        prefixIcon: Icon(Icons.lock_rounded, color: AppColors.primaryPurple),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            color: AppColors.primaryPurple,
          ),
          onPressed: _togglePasswordVisibility, // Toggle visibilidad
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
      validator: (value) => value!.length < 6
          ? 'La contraseña debe tener al menos 6 caracteres'
          : null,
    );
  }

  /**
   * Construye el botón principal de registro
   * Muestra loading indicator durante el proceso
   */
  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: _isLoading ? null : AppGradients.buttonGradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: _isLoading ? null : [AppShadows.softShadow],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? Colors.grey : Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: _isLoading
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
                  Icon(Icons.person_add_alt_1, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Crear cuenta',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  /**
   * Construye la sección para usuarios que ya tienen cuenta
   * Enlace para regresar a la página de login
   */
  Widget _buildLoginSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes cuenta?',
          style: TextStyle(color: AppColors.textLight),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => Navigator.pop(context), // Regresar a login
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryPurple),
          child: const Text(
            'Iniciar sesión',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
