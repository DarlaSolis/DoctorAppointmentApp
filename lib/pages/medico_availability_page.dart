import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../firebase_service.dart';

class MedicoAvailabilityPage extends StatefulWidget {
  const MedicoAvailabilityPage({super.key});

  @override
  State<MedicoAvailabilityPage> createState() => _MedicoAvailabilityPageState();
}

class _MedicoAvailabilityPageState extends State<MedicoAvailabilityPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  List<Map<String, dynamic>> _horariosDisponibles = [];
  List<Map<String, dynamic>> _horariosOcupados = [];
  bool _isLoading = false;
  String? _medicoId;

  @override
  void initState() {
    super.initState();
    _cargarHorarios();
    _generarHorariosFuturos();
  }

  Future<void> _generarHorariosFuturos() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firebaseService.generarHorariosFuturos(user.uid);
      print('✅ Horarios futuros generados');
    } catch (e) {
      print('❌ Error generando horarios: $e');
    }
  }

  Future<void> _cargarHorarios() async {
    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null) return;

    _medicoId = user.uid;

    try {
      // Generar horarios para los próximos 30 días (solo primera vez)
      await _firebaseService.generarHorariosFuturos(_medicoId!);

      // Cargar horarios disponibles
      final hoy = DateTime.now();
      final fechaLimite = hoy.add(const Duration(days: 30));

      final snapshot = await _firestore
          .collection('disponibilidad_medicos')
          .where('medico_id', isEqualTo: _medicoId)
          .where(
            'fecha',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(hoy.year, hoy.month, hoy.day),
            ),
          )
          .where(
            'fecha',
            isLessThanOrEqualTo: Timestamp.fromDate(
              DateTime(fechaLimite.year, fechaLimite.month, fechaLimite.day),
            ),
          )
          .get();

      final allHorarios = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'fecha_obj': (data['fecha'] as Timestamp).toDate(),
          'hora_inicio_obj': (data['hora_inicio'] as Timestamp).toDate(),
          'hora_fin_obj': (data['hora_fin'] as Timestamp).toDate(),
        };
      }).toList();

      // Separar disponibles y ocupados
      _horariosDisponibles = allHorarios
          .where((h) => h['esta_disponible'] == true)
          .toList();

      _horariosOcupados = allHorarios
          .where((h) => h['esta_disponible'] == false)
          .toList();

      // Ordenar por fecha y hora
      _horariosDisponibles.sort((a, b) {
        final fechaA = a['fecha_obj'] as DateTime;
        final fechaB = b['fecha_obj'] as DateTime;
        final horaA = a['hora_inicio_obj'] as DateTime;
        final horaB = b['hora_inicio_obj'] as DateTime;

        if (fechaA.compareTo(fechaB) != 0) {
          return fechaA.compareTo(fechaB);
        }
        return horaA.compareTo(horaB);
      });

      _horariosOcupados.sort((a, b) {
        final fechaA = a['fecha_obj'] as DateTime;
        final fechaB = b['fecha_obj'] as DateTime;
        final horaA = a['hora_inicio_obj'] as DateTime;
        final horaB = b['hora_inicio_obj'] as DateTime;

        if (fechaA.compareTo(fechaB) != 0) {
          return fechaA.compareTo(fechaB);
        }
        return horaA.compareTo(horaB);
      });

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error cargando horarios: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarHorario(String horarioId) async {
    final confirmado = await _mostrarConfirmacion(
      '¿Está seguro de que desea eliminar este horario?\nLos pacientes no podrán agendar en este horario.',
    );

    if (!confirmado) return;

    setState(() => _isLoading = true);

    try {
      await _firestore
          .collection('disponibilidad_medicos')
          .doc(horarioId)
          .delete();

      _mostrarSnackbar('Horario eliminado', Colors.green);
      await _cargarHorarios();
    } catch (e) {
      _mostrarSnackbar('Error eliminando horario: $e', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _mostrarConfirmacion(String mensaje) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _mostrarSnackbar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Mis Horarios'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryPurple,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: const Color.fromARGB(255, 200, 162, 200),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: 'Disponibles'),
              Tab(icon: Icon(Icons.event_busy), text: 'Ocupados'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildHorariosDisponibles(),
                  _buildHorariosOcupados(),
                ],
              ),
      ),
    );
  }

  Widget _buildHorariosDisponibles() {
    if (_horariosDisponibles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay horarios disponibles',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los horarios se generan automáticamente cada día\n(9:00 AM - 9:00 PM, citas de 1.5 horas)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarHorarios,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Horarios disponibles: ${_horariosDisponibles.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _horariosDisponibles.length,
              itemBuilder: (context, index) {
                final horario = _horariosDisponibles[index];
                return _buildTarjetaHorario(horario, true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorariosOcupados() {
    if (_horariosOcupados.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No hay horarios ocupados',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Los horarios ocupados aparecerán cuando\nlos pacientes agenden citas',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Horarios ocupados: ${_horariosOcupados.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _horariosOcupados.length,
              itemBuilder: (context, index) {
                final horario = _horariosOcupados[index];
                return _buildTarjetaHorario(horario, false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaHorario(Map<String, dynamic> horario, bool disponible) {
    final fecha = horario['fecha_obj'] as DateTime;
    final horaInicio = horario['hora_inicio_obj'] as DateTime;
    final horaFin = horario['hora_fin_obj'] as DateTime;

    final fechaFormateada = DateFormat('EEEE, d MMMM y', 'es_ES').format(fecha);
    final horarioFormateado =
        '${DateFormat('hh:mm a').format(horaInicio)} - ${DateFormat('hh:mm a').format(horaFin)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: disponible ? Colors.white : Colors.grey[100],
      child: ListTile(
        leading: Icon(
          disponible ? Icons.check_circle : Icons.event_busy,
          color: disponible ? Colors.green : Colors.red,
        ),
        title: Text(
          fechaFormateada,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: disponible ? AppColors.textDark : Colors.grey[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(horarioFormateado),
            Text(
              disponible ? 'Disponible' : 'Ocupado',
              style: TextStyle(
                color: disponible ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: disponible ? () => _eliminarHorario(horario['id']) : null,
        ),
      ),
    );
  }
}
