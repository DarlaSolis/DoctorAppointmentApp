import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';

/**
 * Pantalla de Recuperación de Contraseña - Permite a los usuarios resetear su contraseña
 * 
 * Esta página proporciona:
 * - Formulario para ingresar email de recuperación
 * - Envío de enlace de reset via Firebase Auth
 * - Manejo de errores específicos de Firebase
 * - Animaciones suaves y feedback visual
 * - Navegación de regreso al login
 */
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  // Controladores y servicios
  final _emailCtrl = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Estados de la UI
  bool _loading = false; // Indicador de carga durante el envío

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
        milliseconds: 700,
      ), // Duración rápida pero visible
    );

    // Animación de fade in gradual
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Animación de deslizamiento desde arriba
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    // Iniciar animaciones automáticamente
    _animationController.forward();
  }

  @override
  void dispose() {
    // Limpiar recursos para evitar memory leaks
    _animationController.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  /**
   * Maneja el proceso de envío de correo de recuperación
   * - Valida el formato del email
   * - Envía el correo via Firebase Auth
   * - Muestra feedback de éxito/error
   * - Navega de regreso automáticamente en éxito
   */
  Future<void> _sendReset() async {
    final email = _emailCtrl.text.trim();

    // Validación básica del email
    if (email.isEmpty || !email.contains('@')) {
      _showErrorSnackbar('Ingrese un correo válido');
      return;
    }

    setState(() => _loading = true);

    try {
      // Enviar correo de recuperación via Firebase Auth
      await _auth.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Correo enviado a $email')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Esperar 2 segundos para que el usuario vea el mensaje
      await Future.delayed(const Duration(seconds: 2));

      // Regresar a la pantalla de login
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Manejar errores específicos de Firebase Auth
      String errorMessage = 'Error al enviar el correo';
      String errorString = e.toString();

      if (errorString.contains('user-not-found') ||
          errorString.contains('user_not_found')) {
        errorMessage = 'No existe una cuenta con este correo';
      } else if (errorString.contains('invalid-email')) {
        errorMessage = 'Correo electrónico inválido';
      }

      if (mounted) {
        _showErrorSnackbar(errorMessage);
      }
    } finally {
      // Siempre detener el loading indicator
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
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
                  // Icono animado de recuperación
                  _buildAnimatedIcon(),
                  const SizedBox(height: 30),

                  // Card del formulario de recuperación
                  _buildResetCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /**
   * Construye el ícono animado de recuperación
   * Círculo con gradiente e ícono de candado
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
      child: const Icon(
        Icons.lock_reset_rounded,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  /**
   * Construye la tarjeta principal del formulario de recuperación
   * Contiene título, instrucciones, campo de email y botones
   */
  Widget _buildResetCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.cardGradient,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [AppShadows.softShadow],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título con gradiente
            Text(
              'Recuperar Contraseña',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                foreground: Paint()
                  ..shader = AppGradients.primaryGradient.createShader(
                    const Rect.fromLTWH(0, 0, 200, 70),
                  ),
              ),
            ),
            const SizedBox(height: 12),
            // Instrucciones para el usuario
            const Text(
              'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña',
              style: TextStyle(fontSize: 16, color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Campo de email
            _buildEmailField(),
            const SizedBox(height: 30),

            // Botón de enviar enlace
            _buildSendButton(),
            const SizedBox(height: 20),

            // Enlace para volver al login
            _buildBackToLogin(),
          ],
        ),
      ),
    );
  }

  /**
   * Construye el campo de entrada para el email
   * Usa TextField en lugar de TextFormField ya que la validación es simple
   */
  Widget _buildEmailField() {
    return TextField(
      controller: _emailCtrl,
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
    );
  }

  /**
   * Construye el botón principal para enviar el enlace de recuperación
   * Muestra loading indicator durante el proceso
   */
  Widget _buildSendButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: _loading ? null : AppGradients.buttonGradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: _loading ? null : [AppShadows.softShadow],
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : _sendReset,
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
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Enviar Enlace',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  /**
   * Construye el enlace para volver a la pantalla de login
   * Proporciona una alternativa rápida para usuarios que recuerden su contraseña
   */
  Widget _buildBackToLogin() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      style: TextButton.styleFrom(foregroundColor: AppColors.primaryPurple),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          SizedBox(width: 8),
          Text(
            'Volver al inicio de sesión',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
