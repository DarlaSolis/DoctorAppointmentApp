import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // ✅ AÑADIR ESTA IMPORTACIÓN
import '../app_colors.dart';

class MedicoAvailabilityPage extends StatefulWidget {
  const MedicoAvailabilityPage({super.key});

  @override
  State<MedicoAvailabilityPage> createState() => _MedicoAvailabilityPageState();
}

class _MedicoAvailabilityPageState extends State<MedicoAvailabilityPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _disponibilidades = [];
  bool _isLoading = false;
  String? _medicoId;

  @override
  void initState() {
    super.initState();
    _cargarDisponibilidad();
  }

  Future<void> _cargarDisponibilidad() async {
    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null) return;

    _medicoId = user.uid;

    try {
      final snapshot = await _firestore
          .collection('disponibilidad_medico')
          .where('medico_id', isEqualTo: _medicoId)
          .orderBy('fecha', descending: false)
          .get();

      setState(() {
        _disponibilidades = snapshot.docs.map((doc) {
          final data = doc.data();
          return {'id': doc.id, ...data};
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando disponibilidad: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _agregarDisponibilidad() async {
    final fecha = await _seleccionarFecha();
    if (fecha == null) return;

    final horarios = await _seleccionarHorarios();
    if (horarios == null) return;

    final (horaInicio, horaFin) = horarios;

    setState(() => _isLoading = true);

    try {
      final fechaSolo = DateTime(fecha.year, fecha.month, fecha.day);
      final fechaInicioCompleta = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        horaInicio.hour,
        horaInicio.minute,
      );
      final fechaFinCompleta = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        horaFin.hour,
        horaFin.minute,
      );

      // Verificar si ya existe disponibilidad para esta fecha
      final existe = _disponibilidades.any((disp) {
        final dispFecha = (disp['fecha'] as Timestamp).toDate();
        return dispFecha.year == fechaSolo.year &&
            dispFecha.month == fechaSolo.month &&
            dispFecha.day == fechaSolo.day;
      });

      if (existe) {
        _mostrarSnackbar(
          'Ya existe disponibilidad para esta fecha',
          Colors.orange,
        );
        setState(() => _isLoading = false);
        return;
      }

      await _firestore.collection('disponibilidad_medico').add({
        'medico_id': _medicoId,
        'esta_disponible': true,
        'fecha': Timestamp.fromDate(fechaSolo),
        'fecha_inicio': Timestamp.fromDate(fechaInicioCompleta),
        'hora_fin': Timestamp.fromDate(fechaFinCompleta),
        'fecha_creacion': Timestamp.now(),
      });

      _mostrarSnackbar('Disponibilidad agregada exitosamente', Colors.green);
      await _cargarDisponibilidad();
    } catch (e) {
      _mostrarSnackbar('Error agregando disponibilidad: $e', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  Future<DateTime?> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    return picked;
  }

  Future<(TimeOfDay, TimeOfDay)?> _seleccionarHorarios() async {
    final horaInicio = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (horaInicio == null) return null;

    final horaFin = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: horaInicio.hour + 1,
        minute: horaInicio.minute,
      ),
    );
    if (horaFin == null) return null;

    // Validar que la hora fin sea después de la hora inicio
    final inicioMinutes = horaInicio.hour * 60 + horaInicio.minute;
    final finMinutes = horaFin.hour * 60 + horaFin.minute;

    if (finMinutes <= inicioMinutes) {
      _mostrarSnackbar(
        'La hora fin debe ser después de la hora inicio',
        Colors.red,
      );
      return null;
    }

    return (horaInicio, horaFin);
  }

  Future<void> _eliminarDisponibilidad(String disponibilidadId) async {
    final confirmado = await _mostrarConfirmacion(
      '¿Está seguro de que desea eliminar esta disponibilidad?',
    );

    if (!confirmado) return;

    setState(() => _isLoading = true);

    try {
      await _firestore
          .collection('disponibilidad_medico')
          .doc(disponibilidadId)
          .delete();
      _mostrarSnackbar('Disponibilidad eliminada', Colors.green);
      await _cargarDisponibilidad();
    } catch (e) {
      _mostrarSnackbar('Error eliminando disponibilidad: $e', Colors.red);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Disponibilidad'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _disponibilidades.isEmpty
          ? _buildEmptyState()
          : _buildListaDisponibilidad(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No hay disponibilidad configurada',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega tus horarios disponibles para que los pacientes puedan agendar citas',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _agregarDisponibilidad,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Disponibilidad'),
          ),
        ],
      ),
    );
  }

  Widget _buildListaDisponibilidad() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Horarios Disponibles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _disponibilidades.length,
              itemBuilder: (context, index) {
                final disp = _disponibilidades[index];
                return _buildTarjetaDisponibilidad(disp);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaDisponibilidad(Map<String, dynamic> disponibilidad) {
    final fecha = (disponibilidad['fecha'] as Timestamp).toDate();
    final horaInicio = (disponibilidad['fecha_inicio'] as Timestamp).toDate();
    final horaFin = (disponibilidad['hora_fin'] as Timestamp).toDate();

    // ✅ CORREGIDO: Usar DateFormat correctamente
    final fechaFormateada = DateFormat('EEEE, d MMMM y', 'es_ES').format(fecha);
    final horarioFormateado =
        '${DateFormat('HH:mm').format(horaInicio)} - ${DateFormat('HH:mm').format(horaFin)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
        title: Text(
          fechaFormateada,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(horarioFormateado),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _eliminarDisponibilidad(disponibilidad['id']),
        ),
      ),
    );
  }
}
