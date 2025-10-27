import 'package:flutter/material.dart';
import '../app_colors.dart';

/**
 * Página de Consejos Médicos - Proporciona recomendaciones de salud básicas
 * 
 * Esta página muestra una colección de consejos médicos para:
 * - Dolencias comunes y su manejo inicial
 * - Remedios caseros y cuidados básicos
 * - Recomendaciones de primeros auxilios
 * - Prevención y autocuidado
 * 
 * NOTA: Estos consejos son informativos y no sustituyen la consulta médica profesional
 */
class MedicalTipsPage extends StatelessWidget {
  const MedicalTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consejos Médicos'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjeta para dolor de cabeza
          _buildTipCard(
            'Dolor de Cabeza',
            Icons.sick, // Ícono representativo del síntoma
            '• Descanse en un lugar tranquilo y oscuro\n• Tome agua para mantenerse hidratado\n• Aplique compresas frías en la frente\n• Evite luces brillantes y ruidos fuertes',
          ),
          const SizedBox(height: 16),

          // Tarjeta para dolor estomacal
          _buildTipCard(
            'Dolor Estomacal',
            Icons.emoji_food_beverage, // Ícono relacionado con alimentación
            '• Té de manzanilla o jengibre\n• Evite alimentos picantes o grasosos\n• Descanse en posición fetal\n• Manténgase hidratado con sorbos de agua',
          ),
          const SizedBox(height: 16),

          // Tarjeta para dolor de garganta
          _buildTipCard(
            'Dolor de Garganta',
            Icons.record_voice_over, // Ícono representativo de la voz
            '• Haga gárgaras con agua salada tibia\n• Beba líquidos calientes\n• Evite hablar en exceso\n• Use pastillas para la garganta',
          ),

          // Sección de advertencia médica
          const SizedBox(height: 24),
          _buildMedicalWarning(),
        ],
      ),
    );
  }

  /**
   * Construye una tarjeta individual de consejo médico
   * @param title Título del síntoma o condición
   * @param icon Ícono representativo de la condición
   * @param tips Lista de consejos formateados con puntos
   * @return Widget Card con la información del consejo médico
   */
  Widget _buildTipCard(String title, IconData icon, String tips) {
    return Card(
      elevation: 4, // Sombra suave para efecto de elevación
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior con ícono y título
            Row(
              children: [
                // Contenedor circular para el ícono
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(
                      0.1,
                    ), // Fondo sutil
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 20),
                ),
                const SizedBox(width: 12), // Espaciado entre ícono y texto
                // Título de la condición
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Espaciado entre título y consejos
            // Lista de consejos médicos
            Text(
              tips,
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  /**
   * Construye la sección de advertencia médica
   * Informa al usuario que estos consejos no sustituyen la consulta profesional
   */
  Widget _buildMedicalWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Ícono de advertencia
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          // Texto de advertencia
          Expanded(
            child: Text(
              'Estos consejos son informativos. Consulte a un profesional de la salud para diagnóstico y tratamiento adecuados.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
