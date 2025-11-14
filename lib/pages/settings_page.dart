import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';
import 'profile_edit_page.dart';
import 'privacy_page.dart';
import 'about_page.dart';

/**
 * Página de Configuración - Centro de control y preferencias de la aplicación
 * 
 * Esta página proporciona acceso a:
 * - Gestión del perfil de usuario
 * - Configuración de privacidad y datos
 * - Información sobre la aplicación
 * - Cierre de sesión y gestión de cuenta
 * 
 * Sirve como hub central para todas las opciones de configuración y preferencias del usuario.
 */
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo consistente con el tema de la aplicación
      backgroundColor: AppColors.background,

      // Barra de aplicación con título
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryPurple,
        ),
      ),

      // Cuerpo principal con opciones de configuración
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Opción: Editar Perfil
            _buildSettingItem(
              icon: Icons.person,
              title: 'Perfil',
              subtitle: 'Información personal',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileEditPage(),
                  ),
                );
              },
            ),

            // Opción: Privacidad
            _buildSettingItem(
              icon: Icons.security,
              title: 'Privacidad',
              subtitle: 'Configuración de privacidad',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPage()),
                );
              },
            ),

            // Opción: Sobre Nosotros
            _buildSettingItem(
              icon: Icons.info,
              title: 'Sobre Nosotros',
              subtitle: 'Información de la aplicación',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),

            // Espacio flexible para empujar el botón de logout hacia abajo
            const Spacer(),

            // Botón de cerrar sesión (siempre visible en la parte inferior)
            _buildLogoutButton(context),
            const SizedBox(height: 20), // Margen inferior de seguridad
          ],
        ),
      ),
    );
  }

  /**
   * Construye un ítem individual de configuración
   * @param icon Ícono representativo de la opción
   * @param title Título principal de la opción
   * @param subtitle Descripción breve de la opción
   * @param onTap Función a ejecutar al hacer tap
   * @return Widget ListTile con diseño consistente para opciones de configuración
   */
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12), // Separación entre ítems
      elevation: 2, // Sombra sutil para efecto de elevación
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        // Ícono circular con color de acento
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1), // Fondo sutil
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 20),
        ),
        // Título principal en negrita
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        // Subtítulo descriptivo
        subtitle: Text(subtitle, style: TextStyle(color: AppColors.textLight)),
        // Ícono de navegación
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap, // Navegación a la página correspondiente
      ),
    );
  }

  /**
   * Construye el botón de cerrar sesión
   * Diseñado para ser prominente pero no intrusivo, ubicado en la parte inferior
   * @param context Contexto para diálogos y navegación
   * @return Widget ElevatedButton con diseño de contorno rojo
   */
  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity, // Ancho completo
      height: 55, // Altura consistente con otros botones de la app
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.redAccent,
        ), // Borde rojo para advertencia
      ),
      child: ElevatedButton(
        onPressed: () async {
          await _showLogoutDialog(context); // Mostrar diálogo de confirmación
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // Fondo transparente
          foregroundColor: Colors.redAccent, // Texto e ícono rojos
          shadowColor: Colors.transparent, // Sin sombra
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0, // Sin elevación para diseño plano
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text(
              'Cerrar Sesión',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /**
   * Muestra un diálogo de confirmación para cerrar sesión
   * Previene cierres de sesión accidentales
   * @param context Contexto para mostrar el diálogo
   * @return Future que se completa cuando el diálogo se cierra
   */
  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            // Botón Cancelar - Secundario
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cerrar diálogo
              child: const Text('Cancelar'),
            ),
            // Botón Cerrar Sesión - Primario (rojo)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Cerrar diálogo primero
                await FirebaseAuth.instance
                    .signOut(); // Cerrar sesión en Firebase
                // Navegar al login limpiando todo el stack
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/', // Ruta inicial (login)
                  (route) => false, // Remover todas las rutas
                );
              },
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red), // Color de advertencia
              ),
            ),
          ],
        );
      },
    );
  }
}
