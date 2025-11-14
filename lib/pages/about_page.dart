import 'package:flutter/material.dart';
import '../app_colors.dart';

/**
 * Página "Sobre Nosotros" - Muestra información acerca de la aplicación
 * 
 * Esta página proporciona a los usuarios información básica sobre
 * la aplicación de citas médicas, su propósito y funcionalidades.
 */
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo de la aplicación usando los colores definidos en la app
      backgroundColor: AppColors.background,

      // Barra de aplicación personalizada
      appBar: AppBar(
        title: const Text('Sobre Nosotros'),
        backgroundColor: Colors.transparent, // Fondo transparente
        elevation: 0, // Sin sombra para un look más plano y moderno
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

      // Cuerpo principal de la página
      body: const Padding(
        padding: EdgeInsets.all(16), // Espaciado alrededor del contenido
        child: Card(
          // Tarjeta que contiene la información
          child: Padding(
            padding: EdgeInsets.all(20), // Espaciado interno del texto
            child: Text(
              // Descripción de la aplicación
              'Aplicación de Citas Médicas - Conectamos pacientes con profesionales de la salud.',
              style: TextStyle(fontSize: 16), // Tamaño de fuente legible
            ),
          ),
        ),
      ),
    );
  }
}
