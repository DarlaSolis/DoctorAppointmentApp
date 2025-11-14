import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_colors.dart';
import '../firebase_service.dart';
import '../bloc/dashboard_bloc.dart';

/**
 * Dashboard Médico - Pantalla exclusiva para usuarios con rol de médico
 * 
 * Muestra métricas en tiempo real usando patrón BLoC:
 * - Total de citas del médico
 * - Citas pendientes
 * - Total de pacientes únicos
 * - Próxima cita programada
 * 
 * Usa BlocBuilder para gestión de estado y actualización en tiempo real
 */
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _firebaseService = FirebaseService();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /**
   * Función para recargar el dashboard
   */
  Future<void> _recargarDashboard() async {
    // Simular un breve delay para la animación de refresh
    await Future.delayed(const Duration(milliseconds: 800));

    // Recargar los datos del dashboard
    if (mounted) {
      context.read<DashboardBloc>().add(RefreshDashboardData());
    }

    // Mostrar confirmación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Dashboard actualizado'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc()..add(LoadDashboardData()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Dashboard Médico'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryPurple,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Color.fromARGB(255, 200, 162, 200),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            // Envuelve el contenido con RefreshIndicator para pull to refresh
            return RefreshIndicator(
              onRefresh: _recargarDashboard,
              color: AppColors.primaryBlue,
              backgroundColor: Colors.white,
              displacement: 40,
              strokeWidth: 3,
              child: _buildBodyContent(state, context),
            );
          },
        ),
      ),
    );
  }

  // Método separado para el contenido del body
  Widget _buildBodyContent(DashboardState state, BuildContext context) {
    // Envuelve con GestureDetector para el gesto de deslizar hacia atrás
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Detectar deslizamiento hacia la derecha para regresar
        if (details.primaryVelocity! > 0) {
          Navigator.pop(context);
        }
      },
      child: _buildStateContent(state, context),
    );
  }

  // Tu método existente para construir el contenido según el estado
  Widget _buildStateContent(DashboardState state, BuildContext context) {
    if (state is DashboardLoading) {
      return _buildLoadingState();
    } else if (state is DashboardError) {
      return _buildErrorState(state.message, context);
    } else if (state is DashboardLoaded) {
      return _buildDashboardContent(state, context);
    } else {
      return _buildInitialState(context);
    }
  }

  // Modifica _buildDashboardContent para que sea scrollable
  Widget _buildDashboardContent(DashboardLoaded state, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header informativo
          _buildHeader(state.medicoNombre),
          const SizedBox(height: 24),

          // Métricas principales
          _buildMetricsGrid(state),
          const SizedBox(height: 24),

          // Lista de próximas citas
          _buildNextAppointments(state.proximasCitas),
          const SizedBox(height: 24),

          // Estadísticas adicionales
          _buildAdditionalStats(state),
        ],
      ),
    );
  }

  // ... el resto de tus métodos permanecen igual (_buildLoadingState, _buildErrorState, etc.)

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryBlue),
          SizedBox(height: 16),
          Text(
            'Cargando dashboard...',
            style: TextStyle(color: AppColors.textLight, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<DashboardBloc>().add(RefreshDashboardData());
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.medical_services,
            color: AppColors.primaryPurple,
            size: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            'Dashboard Médico',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Presiona el botón de actualizar para cargar los datos',
            style: TextStyle(color: AppColors.textLight, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<DashboardBloc>().add(LoadDashboardData());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cargar Datos'),
          ),
        ],
      ),
    );
  }

  /**
   * Header con información del médico
   */
  Widget _buildHeader(String medicoNombre) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppShadows.mediumShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.medical_services, size: 50, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Bienvenido, Dr. $medicoNombre',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Panel de control médico',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Datos en tiempo real',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /**
   * Grid de métricas principales
   */
  Widget _buildMetricsGrid(DashboardLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métricas Principales',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          children: [
            _buildMetricCard(
              title: 'Total Citas',
              value: state.totalCitas.toString(),
              icon: Icons.calendar_today,
              color: AppColors.primaryBlue,
              subtitle: 'Todas las citas',
            ),
            _buildMetricCard(
              title: 'Citas Pendientes',
              value: state.citasPendientes.toString(),
              icon: Icons.pending_actions,
              color: Colors.orange,
              subtitle: 'Por atender',
            ),
            _buildMetricCard(
              title: 'Total Pacientes',
              value: state.totalPacientes.toString(),
              icon: Icons.people,
              color: AppColors.primaryPurple,
              subtitle: 'Pacientes únicos',
            ),
            _buildNextAppointmentCard(state.proximasCitas),
          ],
        ),
      ],
    );
  }

  /**
   * Tarjeta de métrica individual
   */
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),

            // Título
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),

            // Subtítulo
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Valor
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /**
   * Tarjeta especial para próxima cita
   */
  Widget _buildNextAppointmentCard(List<Map<String, dynamic>> proximasCitas) {
    if (proximasCitas.isEmpty) {
      return _buildMetricCardPlaceholder(
        title: 'Próxima Cita',
        icon: Icons.access_time,
        color: Colors.green,
        value: 'No hay citas',
      );
    }

    final proximaCita = proximasCitas.first;
    final fechaHora = (proximaCita['fecha_hora'] as Timestamp).toDate();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Próxima Cita',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${fechaHora.day}/${fechaHora.month}/${fechaHora.year}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              '${fechaHora.hour}:${fechaHora.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
            const SizedBox(height: 4),
            Text(
              proximaCita['especialidad'] ?? 'Consulta',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textLight,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /**
   * Placeholder para tarjetas de métricas
   */
  Widget _buildMetricCardPlaceholder({
    required String title,
    required IconData icon,
    required Color color,
    String value = 'Cargando...',
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: value == 'Cargando...' ? 14 : 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /**
   * Lista de próximas citas
   */
  Widget _buildNextAppointments(List<Map<String, dynamic>> proximasCitas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Próximas Citas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),

        if (proximasCitas.isEmpty)
          _buildEmptyState('No hay citas programadas')
        else
          Column(
            children: proximasCitas
                .map((cita) => _buildAppointmentCard(cita))
                .toList(),
          ),
      ],
    );
  }

  /**
   * Tarjeta individual de cita
   */
  Widget _buildAppointmentCard(Map<String, dynamic> cita) {
    final fechaHora = (cita['fecha_hora'] as Timestamp).toDate();
    final pacienteId = cita['paciente_id'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  cita['especialidad'] ?? 'Consulta General',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text(
                    'PENDIENTE',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 8),
                Text(
                  '${fechaHora.day}/${fechaHora.month}/${fechaHora.year}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 8),
                Text(
                  '${fechaHora.hour}:${fechaHora.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<Map<String, dynamic>?>(
              future: _firebaseService.obtenerUsuario(pacienteId),
              builder: (context, patientSnapshot) {
                final pacienteNombre =
                    patientSnapshot.data?['nombre'] ?? 'Paciente';
                return Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Paciente: $pacienteNombre',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Motivo: ${cita['motivo'] ?? 'No especificado'}',
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /**
   * Estadísticas adicionales
   */
  Widget _buildAdditionalStats(DashboardLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadísticas Adicionales',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Citas de hoy
            Expanded(
              child: _buildStatCard(
                title: 'Citas Hoy',
                value: state.citasHoy.toString(),
                icon: Icons.today,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            // Citas esta semana
            Expanded(
              child: _buildStatCard(
                title: 'Esta Semana',
                value: state.citasSemana.toString(),
                icon: Icons.date_range,
                color: AppColors.primaryPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /**
   * Tarjeta de estadística simple
   */
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /**
   * Estado vacío
   */
  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
