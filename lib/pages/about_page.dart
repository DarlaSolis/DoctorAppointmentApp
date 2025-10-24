import 'package:flutter/material.dart';
import '../app_colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sobre Nosotros'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Aplicación de Citas Médicas - Conectamos pacientes con profesionales de la salud.',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
