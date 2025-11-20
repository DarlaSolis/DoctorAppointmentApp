import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/login_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/messages_page.dart';
import 'pages/settings_page.dart';
import 'pages/profile_edit_page.dart';
import 'pages/privacy_page.dart';
import 'pages/about_page.dart';
import 'pages/medical_tips_page.dart';
import 'pages/edit_appointment_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/graphics_page.dart';

class Routes {
  static const String login = '/';
  static const String home = '/home';
  static const String forgot = '/forgot';
  static const String register = '/register';
  static const String messages = '/messages';
  static const String settings = '/settings'; // Constante
  static const String profileEdit = '/profile-edit';
  static const String privacy = '/privacy';
  static const String about = '/about';
  static const String medicalTips = '/medical-tips';
  static const String editCita = '/edit-cita';
  static const String dashboard = '/dashboard';
  static const String graphics = '/graphics';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case forgot:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case messages:
        return MaterialPageRoute(builder: (_) => const MessagesPage());
      case settings: // ← Ahora no hay conflicto
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case profileEdit:
        return MaterialPageRoute(builder: (_) => const ProfileEditPage());
      case privacy:
        return MaterialPageRoute(builder: (_) => const PrivacyPage());
      case about:
        return MaterialPageRoute(builder: (_) => const AboutPage());
      case medicalTips:
        return MaterialPageRoute(builder: (_) => const MedicalTipsPage());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case graphics:
        return MaterialPageRoute(builder: (_) => const GraphicsPage());
      case editCita:
        final args = routeSettings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) =>
              EditCitaPage(citaId: args['citaId'], citaData: args['citaData']),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}
