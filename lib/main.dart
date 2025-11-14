import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'app_colors.dart';
import 'bloc/dashboard_bloc.dart';

/**
 * Función principal de la aplicación - Punto de entrada de la app
 */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

/**
 * Widget principal de la aplicación - MyApp
 */
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DashboardBloc>(create: (context) => DashboardBloc()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DoctorAppointmentApp',
        initialRoute: Routes.login,
        onGenerateRoute: Routes.generateRoute,

        // Tema personalizado de la aplicación CORREGIDO
        theme: ThemeData(
          // Color primario de la aplicación
          primaryColor: AppColors.primaryBlue,

          // Esquema de color principal
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryBlue,
            primary: AppColors.primaryBlue,
            secondary: AppColors.primaryPurple,
          ),

          // Color de fondo por defecto para Scaffold
          scaffoldBackgroundColor: AppColors.background,

          // Tema personalizado para AppBar
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Tema personalizado para botones elevados - CORREGIDO
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Tema para tarjetas - CORREGIDO (CardThemeData en lugar de CardTheme)
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(8),
            color: Colors.white,
          ),

          // Tema para inputs
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            labelStyle: const TextStyle(color: AppColors.textLight),
            hintStyle: TextStyle(color: Colors.grey.shade500),
          ),

          // Tema para íconos
          iconTheme: const IconThemeData(color: AppColors.primaryBlue),

          // Tema para texto
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
            displayMedium: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: TextStyle(color: AppColors.textDark),
            bodyMedium: TextStyle(color: AppColors.textDark),
            titleMedium: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Usar Material 3 (puedes cambiar a false si prefieres Material 2)
          useMaterial3: true,
        ),

        // Configuración adicional para una experiencia más fluida
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!,
          );
        },
      ),
    );
  }
}
