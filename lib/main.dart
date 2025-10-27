import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'app_colors.dart';

/**
 * Función principal de la aplicación - Punto de entrada de la app
 * 
 * Esta función:
 * 1. Inicializa los bindings de Flutter
 * 2. Configura Firebase para la aplicación
 * 3. Ejecuta la aplicación principal
 * 
 * El uso de async/await asegura que Firebase esté completamente inicializado
 * antes de que la interfaz de usuario comience a renderizarse.
 */
Future<void> main() async {
  // Asegura que Flutter esté inicializado antes de cualquier operación
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con las opciones específicas de la plataforma
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ejecuta la aplicación principal
  runApp(const MyApp());
}

/**
 * Widget principal de la aplicación - MyApp
 * 
 * Este widget es la raíz de toda la aplicación y configura:
 * - El enrutamiento global
 * - El tema visual de la aplicación
 * - Las configuraciones generales de MaterialApp
 */
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Oculta la etiqueta de debug en la esquina superior derecha
      debugShowCheckedModeBanner: false,

      // Nombre de la aplicación
      title: 'DoctorAppointmentApp',

      // Ruta inicial al iniciar la aplicación (página de login)
      initialRoute: Routes.login,

      // Generador de rutas que maneja la navegación entre páginas
      onGenerateRoute: Routes.generateRoute,

      // Tema personalizado de la aplicación
      theme: ThemeData(
        // Color primario de la aplicación
        primaryColor: AppColors.primaryBlue,

        // Color de fondo por defecto para Scaffold
        scaffoldBackgroundColor: AppColors.background,

        // Tema personalizado para AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryBlue, // Fondo azul primario
          foregroundColor: Colors.white, // Texto e íconos blancos
        ),

        // Tema personalizado para botones elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue, // Fondo azul
            foregroundColor: Colors.white, // Texto blanco
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Bordes redondeados
            ),
          ),
        ),
      ),
    );
  }
}
