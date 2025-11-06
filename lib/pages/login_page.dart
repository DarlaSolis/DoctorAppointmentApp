import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app_colors.dart';
import '../routes.dart';
import '../firebase_service.dart';

/**
 * Página de Login/Registro - Maneja la autenticación de usuarios
 * 
 * Esta página permite a los usuarios:
 * - Iniciar sesión con email y contraseña
 * - Registrarse creando una nueva cuenta
 * - Recuperar contraseña (a través de la página correspondiente)
 * 
 * Incluye animaciones suaves y validación de formularios.
 */
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // Controladores para los campos de texto
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  // Servicios de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _firebaseService = FirebaseService();

  // Estados de la UI
  bool _loading = false; // Indicador de carga durante login/registro
  bool _obscureText = true; // Mostrar/ocultar contraseña
  bool _isLogin = true; // Alternar entre login y registro

  // Animaciones
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Configurar animaciones de entrada
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Animación de fade in
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Animación de deslizamiento desde abajo
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Iniciar animaciones
    _animationController.forward();
  }

  @override
  void dispose() {
    // Limpiar controladores para evitar memory leaks
    _animationController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  /**
   * NUEVO: Función para recargar/limpiar formulario
   */
  Future<void> _recargarFormulario() async {
    // Simular un breve delay para la animación de refresh
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _emailCtrl.clear();
      _passCtrl.clear();
      _nameCtrl.clear();
      _obscureText = true;
    });

    // Mostrar confirmación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.refresh, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Formulario recargado ugu'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /**
   * Maneja el proceso de inicio de sesión
   * - Valida el formulario
   * - Autentica con Firebase Auth
   * - Navega a la página principal si es exitoso
   * - Muestra errores si falla
   */
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.home);
    } catch (e) {
      String errorMessage = 'Error al iniciar sesión';

      // Manejar errores específicos de Firebase Auth
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'Usuario no existe';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Contraseña incorrecta';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Correo electrónico inválido';
      }

      if (mounted) {
        _showErrorSnackbar(errorMessage);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /**
   * Maneja el proceso de registro de nuevo usuario
   * - Valida el formulario
   * - Crea cuenta en Firebase Auth
   * - Guarda información adicional en Firestore
   * - Navega a la página principal si es exitoso
   */
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
          );

      // GUARDAR USUARIO EN FIRESTORE con información adicional
      await _firebaseService.guardarUsuario(
        uid: userCredential.user!.uid,
        nombre: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.home);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error al registrarse';

      // Manejar errores específicos de registro
      if (e.code == 'email-already-in-use') {
        errorMessage = 'El correo ya está en uso';
      } else if (e.code == 'weak-password') {
        errorMessage = 'La contraseña es muy débil';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Correo electrónico inválido';
      }

      if (mounted) {
        _showErrorSnackbar(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error inesperado: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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

  /**
   * Cambia entre modo Login y Registro
   * También limpia el formulario al cambiar
   */
  void _toggleLoginRegister() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        // NUEVO: Tap para ocultar teclado
        onTap: () => FocusScope.of(context).unfocus(),
        child: RefreshIndicator(
          // NUEVO: Pull to refresh
          onRefresh: _recargarFormulario,
          color: AppColors.primaryBlue,
          backgroundColor: Colors.white,
          displacement: 40,
          strokeWidth: 3,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildAnimatedLogo(), // Logo con animación
                const SizedBox(height: 30),
                _buildAuthCard(), // Tarjeta de autenticación
              ],
            ),
          ),
        ),
      ),
    );
  }

  /**
   * Construye el logo animado de la aplicación
   * Usa CachedNetworkImage para carga eficiente de imagen
   * NUEVO: Agregado GestureDetector para doble tap
   */
  Widget _buildAnimatedLogo() {
    return GestureDetector(
      // NUEVO: Doble tap en logo
      onDoubleTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(width: 8),
                Text('¡👋 Bienvenido a DoctorAppointmentApp!'),
              ],
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [AppShadows.mediumShadow],
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(70),
          child: CachedNetworkImage(
            imageUrl: 'https://cdn-icons-png.flaticon.com/512/3844/3844988.png',
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services,
                size: 50,
                color: Colors.white,
              ),
            ),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /**
   * Construye la tarjeta principal de autenticación
   * Contiene el formulario dinámico (login/registro)
   */
  Widget _buildAuthCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.cardGradient,
        borderRadius: BorderRadius.circular(20),
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
                'Citas Médicas',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  foreground: Paint()
                    ..shader = AppGradients.primaryGradient.createShader(
                      const Rect.fromLTWH(0, 0, 200, 70),
                    ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Inicia sesión en tu cuenta' : 'Crea tu cuenta',
                style: TextStyle(fontSize: 16, color: AppColors.textLight),
              ),
              const SizedBox(height: 32),

              // Campo de nombre solo visible en registro
              if (!_isLogin) ...[_buildNameField(), const SizedBox(height: 20)],

              // Campos comunes
              _buildEmailField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 20),

              // Olvidó contraseña solo en login
              if (_isLogin) ...[
                _buildForgotPassword(),
                const SizedBox(height: 25),
              ],

              // Botón de acción principal
              _buildAuthButton(),
              const SizedBox(height: 20),

              // Alternar entre login y registro
              _buildToggleAuth(),
            ],
          ),
        ),
      ),
    );
  }

  /**
   * Campo de texto para nombre completo (solo en registro)
   */
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: 'Nombre completo',
        labelStyle: const TextStyle(color: AppColors.textLight),
        prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryPurple),
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
      validator: (v) {
        if (!_isLogin && (v == null || v.isEmpty)) {
          return 'Ingresa tu nombre';
        }
        return null;
      },
    );
  }

  /**
   * Campo de texto para email con validación
   */
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: 'Correo electrónico',
        labelStyle: const TextStyle(color: AppColors.textLight),
        prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryPurple),
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
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingresa tu correo';
        if (!v.contains('@') || !v.contains('.')) return 'Correo inválido';
        return null;
      },
    );
  }

  /**
   * Campo de texto para contraseña con toggle de visibilidad
   */
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passCtrl,
      obscureText: _obscureText,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        labelStyle: const TextStyle(color: AppColors.textLight),
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryPurple),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            color: AppColors.primaryPurple,
          ),
          onPressed: _togglePasswordVisibility,
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
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
        if (v.length < 6) return 'Mínimo 6 caracteres';
        return null;
      },
    );
  }

  /**
   * Enlace para recuperar contraseña
   */
  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.pushNamed(context, Routes.forgot),
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryPurple),
        child: const Text(
          '¿Olvidó su contraseña?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /**
   * Botón principal de autenticación (Login/Registro)
   * Muestra loading durante el proceso
   */
  Widget _buildAuthButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: _loading ? null : AppGradients.buttonGradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: _loading ? null : [AppShadows.softShadow],
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : (_isLogin ? _login : _register),
        style: ElevatedButton.styleFrom(
          backgroundColor: _loading ? Colors.grey : Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isLogin ? Icons.arrow_forward : Icons.person_add,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  /**
   * Enlace para alternar entre Login y Registro
   */
  Widget _buildToggleAuth() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? '¿No tienes cuenta?' : '¿Ya tienes cuenta?',
          style: TextStyle(color: AppColors.textLight),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: _toggleLoginRegister,
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryPurple),
          child: Text(
            _isLogin ? 'Crear cuenta' : 'Iniciar sesión',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
