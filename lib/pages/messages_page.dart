import 'package:flutter/material.dart';
import '../app_colors.dart';

/**
 * Página de Mensajes - Pantalla de funcionalidad en desarrollo
 * 
 * Esta página sirve como placeholder para la futura funcionalidad de mensajería
 * que permitirá la comunicación entre pacientes y profesionales de la salud.
 * 
 * Actualmente muestra un estado "Próximamente" con un diseño limpio y informativo.
 */
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo consistente con el resto de la aplicación
      backgroundColor: AppColors.background,

      // Barra de aplicación con título
      appBar: AppBar(
        title: const Text('Mensajes'),
        backgroundColor: Colors.transparent, // Fondo transparente
        foregroundColor: AppColors.textDark, // Color del texto e íconos
        elevation: 0, // Sin sombra para diseño plano
      ),

      // Cuerpo centrado con contenido informativo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centrado vertical
          children: [
            // Ícono grande representativo de mensajes
            Icon(
              Icons.message_outlined, // Ícono de mensaje outline
              size: 80, // Tamaño grande para buen impacto visual
              color: AppColors.textLight.withOpacity(
                0.5,
              ), // Color sutil y translúcido
            ),
            const SizedBox(height: 20), // Espaciado entre ícono y texto
            // Título principal "Próximamente"
            Text(
              'Próximamente',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600, // Peso semi-bold para destacar
                color: AppColors.textLight, // Color consistente con el tema
              ),
            ),
            const SizedBox(height: 10), // Espaciado entre título y descripción
            // Descripción informativa sobre la funcionalidad futura
            Text(
              'La funcionalidad de mensajes estará disponible pronto',
              style: TextStyle(fontSize: 16, color: AppColors.textLight),
              textAlign:
                  TextAlign.center, // Texto centrado para mejor legibilidad
            ),
          ],
        ),
      ),
    );
  }
}
