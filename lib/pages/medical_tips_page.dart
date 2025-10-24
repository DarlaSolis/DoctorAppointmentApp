import 'package:flutter/material.dart';
import '../app_colors.dart';

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
          _buildTipCard(
            'Dolor de Cabeza',
            Icons.sick,
            '• Descanse en un lugar tranquilo y oscuro\n• Tome agua para mantenerse hidratado\n• Aplique compresas frías en la frente\n• Evite luces brillantes y ruidos fuertes',
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            'Dolor Estomacal',
            Icons.emoji_food_beverage,
            '• Té de manzanilla o jengibre\n• Evite alimentos picantes o grasosos\n• Descanse en posición fetal\n• Manténgase hidratado con sorbos de agua',
          ),
          const SizedBox(height: 16),
          _buildTipCard(
            'Dolor de Garganta',
            Icons.record_voice_over,
            '• Haga gárgaras con agua salada tibia\n• Beba líquidos calientes\n• Evite hablar en exceso\n• Use pastillas para la garganta',
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String title, IconData icon, String tips) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 12),
            Text(
              tips,
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}
