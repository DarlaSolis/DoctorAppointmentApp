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
 * - Seleccionar rol (Paciente o Médico) al registrarse
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
  final _confirmPassCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  String _selectedRol = 'paciente';
  final List<String> _roles = ['paciente', 'medico'];

  // Servicios de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _firebaseService = FirebaseService();

  // Estados de la UI
  bool _loading = false; // Indicador de carga durante login/registro
  bool _obscureText = true; // Mostrar/ocultar contraseña
  bool _obscureConfirmText = true; // Mostrar/ocultar confirmación de contraseña
  bool _isLogin = true; // Alternar entre login y registro

  // Seguimiento de fortaleza de contraseña
  double _passwordStrength = 0.0;
  String _passwordFeedback = '';
  bool _showStrengthIndicator = false;

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
    _confirmPassCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  /**
   * Función para recargar/limpiar formulario
   */
  Future<void> _recargarFormulario() async {
    // Simular un breve delay para la animación de refresh
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _emailCtrl.clear();
      _passCtrl.clear();
      _confirmPassCtrl.clear();
      _nameCtrl.clear();
      _obscureText = true;
      _obscureConfirmText = true;
      _selectedRol = 'paciente';
      _passwordStrength = 0.0;
      _passwordFeedback = '';
      _showStrengthIndicator = false;
    });

    // Mostrar confirmación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Formulario recargado'),
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
   * Calcula la fortaleza de la contraseña
   */
  void _calculatePasswordStrength(String password) {
    double strength = 0.0;
    String feedback = '';

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordFeedback = '';
        _showStrengthIndicator = false;
      });
      return;
    }

    // Longitud mínima
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.2;

    // Mayúsculas
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;

    // Números
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;

    // Caracteres especiales
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.2;

    // Determinar feedback
    if (strength < 0.4) {
      feedback = 'Débil - Usa mayúsculas, números y caracteres especiales';
    } else if (strength < 0.7) {
      feedback = 'Moderada - Podría ser más segura';
    } else {
      feedback = 'Fuerte - ¡Excelente contraseña!';
    }

    setState(() {
      _passwordStrength = strength;
      _passwordFeedback = feedback;
      _showStrengthIndicator = true;
    });
  }

  /**
   * Maneja el proceso de inicio de sesión CON REDIRECCIÓN POR ROL
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

      final user = _auth.currentUser;
      if (user != null) {
        final rol = await _firebaseService.obtenerRolUsuario(user.uid);
        if (rol == 'medico') {
          Navigator.pushReplacementNamed(context, Routes.home);
        } else {
          Navigator.pushReplacementNamed(context, Routes.home);
        }
      }
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
   * Maneja el proceso de registro de nuevo usuario CON ROL
   */
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que las contraseñas coincidan
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _showErrorSnackbar('Las contraseñas no coinciden');
      return;
    }

    // Validar fortaleza de contraseña
    if (_passwordStrength < 0.4 && !_isLogin) {
      _showErrorSnackbar(
        'La contraseña es demasiado débil. Intenta una más segura.',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
          );

      await _firebaseService.guardarUsuario(
        uid: userCredential.user!.uid,
        nombre: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        rol: _selectedRol,
      );

      if (!mounted) return;

      if (_selectedRol == 'medico') {
        Navigator.pushReplacementNamed(context, Routes.dashboard);
      } else {
        Navigator.pushReplacementNamed(context, Routes.home);
      }
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
   * Alterna entre mostrar y ocultar la confirmación de contraseña
   */
  void _toggleConfirmPasswordVisibility() {
    setState(() => _obscureConfirmText = !_obscureConfirmText);
  }

  /**
   * Cambia entre modo Login y Registro
   * También limpia el formulario al cambiar
   */
  void _toggleLoginRegister() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _selectedRol = 'paciente'; // ✅ Resetear rol al cambiar
      _passwordStrength = 0.0;
      _passwordFeedback = '';
      _showStrengthIndicator = false;
    });
  }

  /**
   * Devuelve el color según la fortaleza de la contraseña
   */
  Color _getStrengthColor(double strength) {
    if (strength < 0.4) return Colors.red;
    if (strength < 0.7) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: RefreshIndicator(
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
   */
  Widget _buildAnimatedLogo() {
    return GestureDetector(
      onDoubleTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
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
   * Contiene el formulario dinámico (login/registro) CON SELECTOR DE ROL
   */
  Widget _buildAuthCard() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: Container(
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
                if (!_isLogin) ...[
                  _buildNameField(),
                  const SizedBox(height: 20),
                ],

                if (!_isLogin) ...[
                  _buildRolSelector(),
                  const SizedBox(height: 20),
                ],

                // Campos comunes
                _buildEmailField(),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 20),

                // Indicador de fortaleza de contraseña (solo en registro)
                if (!_isLogin && _showStrengthIndicator) ...[
                  _buildPasswordStrengthIndicator(),
                  const SizedBox(height: 10),
                ],

                // Campo de confirmación de contraseña (solo en registro)
                if (!_isLogin) ...[
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 20),
                ],

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
      ),
    );
  }

  /**
   * Campo de texto para nombre completo (solo en registro)
   */
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      readOnly: _loading,
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
        if (!_isLogin && v != null && v.length < 3) {
          return 'El nombre debe tener al menos 3 caracteres';
        }
        return null;
      },
    );
  }

  /**
   * Selector de rol para registro
   */
  Widget _buildRolSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de usuario *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedRol,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: _loading ? Colors.grey[100] : Colors.transparent,
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: _loading ? Colors.grey : AppColors.primaryPurple,
              ),
              iconEnabledColor: _loading
                  ? Colors.grey
                  : AppColors.primaryPurple,
              iconDisabledColor: Colors.grey,
              items: _roles.map((rol) {
                return DropdownMenuItem(
                  value: rol,
                  child: Row(
                    children: [
                      Icon(
                        rol == 'medico' ? Icons.medical_services : Icons.person,
                        color: _loading ? Colors.grey : AppColors.primaryPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        rol == 'medico' ? 'Médico' : 'Paciente',
                        style: TextStyle(
                          color: _loading ? Colors.grey : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _loading
                  ? null
                  : (value) {
                      setState(() {
                        _selectedRol = value ?? 'paciente';
                      });
                    },
              validator: (value) =>
                  value == null ? 'Selecciona un tipo de usuario' : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedRol == 'medico'
              ? 'Accederás al panel médico con estadísticas'
              : 'Podrás agendar citas médicas',
          style: TextStyle(
            fontSize: 12,
            color: _loading ? Colors.grey : AppColors.textLight,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /**
   * Campo de texto para email con validación
   */
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailCtrl,
      readOnly: _loading,
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
      readOnly: _loading,
      obscureText: _obscureText,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        labelStyle: const TextStyle(color: AppColors.textLight),
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryPurple),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            color: _loading ? Colors.grey : AppColors.primaryPurple,
          ),
          onPressed: _loading ? null : _togglePasswordVisibility,
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
      onChanged: (value) {
        if (!_isLogin) {
          _calculatePasswordStrength(value);
        }
      },
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
        if (v.length < 6) return 'Mínimo 6 caracteres';
        return null;
      },
    );
  }

  /**
   * Campo de texto para confirmar contraseña (solo en registro)
   */
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPassCtrl,
      readOnly: _loading,
      obscureText: _obscureConfirmText,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: 'Confirmar contraseña',
        labelStyle: const TextStyle(color: AppColors.textLight),
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryPurple),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmText ? Icons.visibility : Icons.visibility_off,
            color: _loading ? Colors.grey : AppColors.primaryPurple,
          ),
          onPressed: _loading ? null : _toggleConfirmPasswordVisibility,
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
        if (!_isLogin && (v == null || v.isEmpty)) {
          return 'Confirma tu contraseña';
        }
        if (!_isLogin && v != _passCtrl.text) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
    );
  }

  /**
   * Indicador visual de fortaleza de contraseña
   */
  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Fortaleza: ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            Text(
              _passwordStrength < 0.4
                  ? 'Débil'
                  : _passwordStrength < 0.7
                  ? 'Moderada'
                  : 'Fuerte',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getStrengthColor(_passwordStrength),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _passwordStrength,
          backgroundColor: Colors.grey[300],
          color: _getStrengthColor(_passwordStrength),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 4),
        Text(
          _passwordFeedback,
          style: TextStyle(
            fontSize: 12,
            color: _getStrengthColor(_passwordStrength),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /**
   * Enlace para recuperar contraseña
   */
  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _loading
            ? null
            : () => Navigator.pushNamed(context, Routes.forgot),
        style: TextButton.styleFrom(
          foregroundColor: _loading ? Colors.grey : AppColors.primaryPurple,
        ),
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
                  Icon(_isLogin ? Icons.login : Icons.person_add, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
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
          onPressed: _loading ? null : _toggleLoginRegister,
          style: TextButton.styleFrom(
            foregroundColor: _loading ? Colors.grey : AppColors.primaryPurple,
          ),
          child: Text(
            _isLogin ? 'Crear cuenta' : 'Iniciar sesión',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
