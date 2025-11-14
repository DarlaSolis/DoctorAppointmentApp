import 'package:flutter/material.dart';
import '../app_colors.dart';

/**
 * Página de Política de Privacidad - Informa sobre el manejo de datos personales
 * 
 * Esta página detalla cómo la aplicación maneja y protege la información del usuario,
 * enfocándose especialmente en la confidencialidad de los datos médicos y el cumplimiento
 * de normativas de protección de datos y salud.
 */
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo consistente con el tema de la aplicación
      backgroundColor: AppColors.background,

      // Barra de aplicación con título
      appBar: AppBar(
        title: const Text('Privacidad'),
        backgroundColor: Colors.transparent, // Diseño sin fondo sólido
        elevation: 0, // Sin sombra para diseño plano y moderno
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryPurple,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Color.fromARGB(255, 200, 162, 200),
          onPressed: () => Navigator.pop(context), // Navegación hacia atrás
        ),
      ),

      // Cuerpo principal con contenido de privacidad
      body: Padding(
        padding: const EdgeInsets.all(16), // Margen interno consistente
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Alineación a la izquierda
          children: [
            // Tarjeta principal de política de privacidad
            Container(
              decoration: BoxDecoration(
                gradient:
                    AppGradients.cardGradient, // Gradiente visual atractivo
                borderRadius: BorderRadius.circular(20), // Bordes redondeados
                boxShadow: [
                  AppShadows.softShadow,
                ], // Sombra sutil para profundidad
              ),
              child: const Padding(
                padding: EdgeInsets.all(24), // Espaciado interno generoso
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título principal de la política
                    Text(
                      'Política de Privacidad',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700, // Negrita para énfasis
                        color:
                            AppColors.textDark, // Color oscuro para legibilidad
                      ),
                    ),
                    SizedBox(height: 16), // Espaciado entre título y contenido
                    // Párrafo introductorio sobre el compromiso con la privacidad
                    Text(
                      'En Citas Médicas, nos comprometemos a proteger tu información personal y tu privacidad. Toda la información médica se maneja con estricta confidencialidad.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors
                            .textLight, // Color claro para texto secundario
                      ),
                    ),
                    SizedBox(height: 16), // Espaciado entre párrafos
                    // Lista de puntos clave sobre protección de datos
                    Text(
                      '• Tus datos médicos son encriptados\n• Solo personal autorizado tiene acceso\n• Cumplimos con normativas de salud\n• Puedes solicitar eliminar tus datos',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight, // Color consistente
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
