import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../firebase_service.dart';

class AppointmentBookingPage extends StatefulWidget {
  const AppointmentBookingPage({super.key});

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  final _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _motivoController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedEspecialidad;
  String? _medicoSeleccionadoId;
  String? _medicoSeleccionadoNombre;
  bool _isLoading = false;
  bool _isLoadingMedicos = false;
  bool _isLoadingHorarios = false;

  // Lista de horarios disponibles para el día seleccionado
  List<Map<String, dynamic>> _horariosDisponibles = [];

  final List<String> _especialidades = [
    'Cardiólogo',
    'Pediatra',
    'Dermatólogo',
    'Ortopedista',
    'Ginecólogo',
  ];

  List<QueryDocumentSnapshot> _medicos = [];

  @override
  void initState() {
    super.initState();
    _cargarMedicos();
  }

  Future<void> _cargarMedicos() async {
    setState(() => _isLoadingMedicos = true);
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('rol', isEqualTo: 'medico')
          .get();

      setState(() {
        _medicos = snapshot.docs;
        _isLoadingMedicos = false;
      });
    } catch (e) {
      print('Error cargando médicos: $e');
      setState(() => _isLoadingMedicos = false);
    }
  }

  // Método para cargar horarios disponibles del médico seleccionado
  Future<void> _cargarHorariosDisponibles() async {
    if (_selectedDate == null || _medicoSeleccionadoId == null) {
      return;
    }

    setState(() => _isLoadingHorarios = true);
    _selectedTime = null; // Resetear hora al cargar nuevos horarios

    try {
      final fechaNormalizada = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );

      print(
        '🔄 Cargando horarios para médico $_medicoSeleccionadoId en fecha $fechaNormalizada',
      );

      // Obtener todos los horarios del médico para esa fecha
      final snapshot = await _firestore
          .collection('disponibilidad_medicos')
          .where('medico_id', isEqualTo: _medicoSeleccionadoId)
          .get();

      final ahora = DateTime.now();
      final horariosFiltrados = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Solo horarios disponibles
        if (data['esta_disponible'] != true) continue;

        // Verificar fecha
        final fechaHorario = (data['fecha'] as Timestamp).toDate();
        final fechaHorarioNormalizada = DateTime(
          fechaHorario.year,
          fechaHorario.month,
          fechaHorario.day,
        );

        if (fechaHorarioNormalizada != fechaNormalizada) continue;

        // Verificar que no sea un horario pasado
        final horaInicio = (data['hora_inicio'] as Timestamp).toDate();
        if (horaInicio.isBefore(ahora)) continue;

        horariosFiltrados.add({
          'id': doc.id,
          ...data,
          'hora_inicio_obj': horaInicio,
          'hora_fin_obj': (data['hora_fin'] as Timestamp).toDate(),
        });
      }

      // Ordenar por hora
      horariosFiltrados.sort((a, b) {
        final horaA = a['hora_inicio_obj'] as DateTime;
        final horaB = b['hora_inicio_obj'] as DateTime;
        return horaA.compareTo(horaB);
      });

      setState(() {
        _horariosDisponibles = horariosFiltrados;
        _isLoadingHorarios = false;
      });

      print('✅ Horarios disponibles encontrados: ${horariosFiltrados.length}');

      if (horariosFiltrados.isEmpty) {
        _mostrarSnackbar(
          'El médico no tiene horarios disponibles para esta fecha',
          Colors.orange,
        );
      }
    } catch (e) {
      print('❌ Error cargando horarios: $e');
      setState(() {
        _horariosDisponibles = [];
        _isLoadingHorarios = false;
      });
      _mostrarSnackbar('Error cargando horarios disponibles', Colors.red);
    }
  }

  // Método para seleccionar hora desde los horarios disponibles
  Future<void> _mostrarSelectorHorarios() async {
    if (_horariosDisponibles.isEmpty) {
      _mostrarSnackbar('No hay horarios disponibles', Colors.orange);
      return;
    }

    final TimeOfDay? selected = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Seleccionar Horario',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 400,
              width: 350,
              child: _horariosDisponibles.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, size: 50, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No hay horarios disponibles',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _horariosDisponibles.length,
                      itemBuilder: (context, index) {
                        final horario = _horariosDisponibles[index];
                        final horaInicio =
                            horario['hora_inicio_obj'] as DateTime;
                        final horaFin = horario['hora_fin_obj'] as DateTime;

                        final formatoHora = DateFormat('hh:mm a');
                        final horaInicioStr = formatoHora.format(horaInicio);
                        final horaFinStr = formatoHora.format(horaFin);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.access_time,
                              color: AppColors.primaryBlue,
                            ),
                            title: Text(
                              '$horaInicioStr - $horaFinStr',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: const Text('Duración: 1.5 horas'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.of(context).pop(
                                TimeOfDay(
                                  hour: horaInicio.hour,
                                  minute: horaInicio.minute,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedTime = selected;
      });
    }
  }

  Future<void> _agendarCita() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar campos requeridos
    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedEspecialidad == null ||
        _medicoSeleccionadoId == null) {
      _mostrarSnackbar('Por favor complete todos los campos', Colors.red);
      return;
    }

    // Validar que el horario seleccionado está en la lista de disponibles
    final horaSeleccionada = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    bool horarioValido = false;
    for (final horario in _horariosDisponibles) {
      final horaInicio = horario['hora_inicio_obj'] as DateTime;
      if (horaInicio.hour == horaSeleccionada.hour &&
          horaInicio.minute == horaSeleccionada.minute) {
        horarioValido = true;
        break;
      }
    }

    if (!horarioValido) {
      _mostrarSnackbar(
        'Por favor seleccione un horario disponible',
        Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _mostrarSnackbar('Usuario no autenticado', Colors.red);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final fechaHora = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
        0, // Segundos
        0, // Milisegundos
      );

      // Agendar cita
      await _firebaseService.agendarCita(
        pacienteId: user.uid,
        fechaHora: fechaHora,
        motivo: _motivoController.text.trim(),
        especialidad: _selectedEspecialidad!,
        medicoId: _medicoSeleccionadoId!,
        medicoNombre: _medicoSeleccionadoNombre!,
      );

      // Marcar horario como ocupado
      await _firebaseService.marcarHorarioOcupado(
        _medicoSeleccionadoId!,
        fechaHora,
      );

      _mostrarSnackbar('✅ Cita agendada exitosamente', Colors.green);

      // Limpiar formulario
      _formKey.currentState?.reset();
      setState(() {
        _selectedDate = null;
        _selectedTime = null;
        _selectedEspecialidad = null;
        _medicoSeleccionadoId = null;
        _medicoSeleccionadoNombre = null;
        _horariosDisponibles = [];
        _motivoController.clear();
      });
    } catch (e) {
      print('Error agendando cita: $e');
      _mostrarSnackbar('Error al agendar cita', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarSnackbar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      // No uses locale aquí - se mostrará en inglés
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _selectedDate = fechaSeleccionada;
        _selectedTime = null;
        _horariosDisponibles = [];
      });

      if (_medicoSeleccionadoId != null) {
        await _cargarHorariosDisponibles();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agendar Cita'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryPurple,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color.fromARGB(255, 200, 162, 200),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildEspecialidadSelector(),
                const SizedBox(height: 20),
                _buildMedicoSelector(),
                const SizedBox(height: 20),
                _buildDateSelector(),
                const SizedBox(height: 20),
                if (_selectedDate != null && _medicoSeleccionadoId != null) ...[
                  _buildHorariosDisponibles(),
                  const SizedBox(height: 20),
                ],
                _buildMotivoField(),
                const SizedBox(height: 30),
                _buildAgendarButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorariosDisponibles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.schedule,
              size: 20,
              color: AppColors.primaryPurple,
            ),
            const SizedBox(width: 8),
            const Text(
              'Horarios Disponibles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            if (_horariosDisponibles.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_horariosDisponibles.length} disponible(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (_isLoadingHorarios) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Cargando horarios disponibles...'),
              ],
            ),
          ),
        ] else if (_horariosDisponibles.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No hay horarios disponibles',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Este médico no tiene horarios disponibles para la fecha seleccionada.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListTile(
              leading: Icon(
                Icons.access_time,
                color: _selectedTime == null
                    ? Colors.grey
                    : AppColors.primaryBlue,
              ),
              title: Text(
                _selectedTime == null
                    ? 'Seleccionar horario'
                    : '${DateFormat('hh:mm a').format(DateTime(2023, 1, 1, _selectedTime!.hour, _selectedTime!.minute))}',
                style: TextStyle(
                  color: _selectedTime == null
                      ? Colors.grey
                      : AppColors.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: _selectedTime == null
                  ? const Text('Toque para ver horarios disponibles')
                  : null,
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _mostrarSelectorHorarios,
            ),
          ),
          const SizedBox(height: 8),
          if (_horariosDisponibles.isNotEmpty && _selectedTime == null) ...[
            Text(
              'Seleccione un horario de la lista disponible',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildMedicoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person, size: 20, color: AppColors.primaryPurple),
            const SizedBox(width: 8),
            const Text(
              'Seleccionar Médico *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            if (_medicos.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_medicos.length} disponible(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingMedicos) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Cargando médicos...'),
              ],
            ),
          ),
        ] else if (_medicos.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay médicos disponibles en este momento.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          DropdownButtonFormField<String>(
            value: _medicoSeleccionadoId,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(color: AppColors.textDark, fontSize: 14),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.primaryPurple,
            ),
            items: _medicos.map((medicoDoc) {
              final data = medicoDoc.data() as Map<String, dynamic>;
              final nombre = data['nombre'] ?? 'Médico';
              final especialidad = data['especialidad'] ?? 'General';

              return DropdownMenuItem<String>(
                value: medicoDoc.id,
                // SOLUCIÓN: Texto en una línea con formato compacto
                child: Text(
                  'Dr. $nombre - $especialidad',
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (String? newValue) async {
              setState(() {
                _medicoSeleccionadoId = newValue;
                if (newValue != null) {
                  final medico = _medicos.firstWhere(
                    (doc) => doc.id == newValue,
                  );
                  final data = medico.data() as Map<String, dynamic>;
                  _medicoSeleccionadoNombre = data['nombre'] ?? 'Médico';
                }
                _horariosDisponibles = [];
                _selectedTime = null;
              });

              // Si ya hay fecha seleccionada, cargar horarios del nuevo médico
              if (newValue != null && _selectedDate != null) {
                await _cargarHorariosDisponibles();
              }
            },
            validator: (value) => value == null ? 'Seleccione un médico' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildEspecialidadSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.medical_services,
              size: 20,
              color: AppColors.primaryPurple,
            ),
            const SizedBox(width: 8),
            const Text(
              'Especialidad *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedEspecialidad,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 14, // Asegurar tamaño consistente
          ),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.primaryPurple,
          ),
          items: _especialidades.map((esp) {
            return DropdownMenuItem(
              value: esp,
              child: Text(
                esp,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedEspecialidad = value;
            });
          },
          validator: (value) =>
              value == null ? 'Seleccione una especialidad' : null,
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 20,
              color: AppColors.primaryPurple,
            ),
            const SizedBox(width: 8),
            const Text(
              'Fecha de la cita *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ListTile(
            leading: Icon(
              Icons.calendar_today,
              color: _selectedDate == null
                  ? Colors.grey
                  : AppColors.primaryBlue,
            ),
            title: Text(
              _selectedDate == null
                  ? 'Seleccionar fecha'
                  : DateFormat(
                      'EEEE, d MMMM y',
                      'es_ES',
                    ).format(_selectedDate!),
              style: TextStyle(
                color: _selectedDate == null ? Colors.grey : AppColors.textDark,
              ),
            ),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: _seleccionarFecha,
          ),
        ),
        if (_selectedDate != null && _medicoSeleccionadoId == null) ...[
          const SizedBox(height: 8),
          Text(
            'Ahora seleccione un médico para ver sus horarios disponibles',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMotivoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.description,
              size: 20,
              color: AppColors.primaryPurple,
            ),
            const SizedBox(width: 8),
            const Text(
              'Motivo de la consulta *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _motivoController,
          maxLines: 4,
          style: const TextStyle(color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'Describa el motivo de su consulta...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor describa el motivo de la consulta';
            }
            if (value.length < 10) {
              return 'Describa el motivo con al menos 10 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAgendarButton() {
    // Validación mejorada con depuración
    final bool fechaValida = _selectedDate != null;
    final bool horaValida = _selectedTime != null;
    final bool especialidadValida =
        _selectedEspecialidad != null && _selectedEspecialidad!.isNotEmpty;
    final bool medicoValido =
        _medicoSeleccionadoId != null && _medicoSeleccionadoId!.isNotEmpty;
    final bool motivoValido =
        _motivoController.text.isNotEmpty &&
        _motivoController.text.length >= 10;

    final bool puedeAgendar =
        fechaValida &&
        horaValida &&
        especialidadValida &&
        medicoValido &&
        motivoValido;

    // Depuración
    print('=== VALIDACIÓN BOTÓN ===');
    print('Fecha: $fechaValida ($_selectedDate)');
    print('Hora: $horaValida ($_selectedTime)');
    print('Especialidad: $especialidadValida ($_selectedEspecialidad)');
    print('Médico: $medicoValido ($_medicoSeleccionadoId)');
    print('Motivo: $motivoValido (${_motivoController.text.length} chars)');
    print('Puede agendar: $puedeAgendar');

    // SOLUCIÓN 1: Botón con gradiente CORRECTO
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: (!puedeAgendar || _isLoading)
            ? null
            : AppGradients.buttonGradient,
        borderRadius: BorderRadius.circular(15),
        color: (!puedeAgendar || _isLoading) ? Colors.grey[300] : null,
        boxShadow: (!puedeAgendar || _isLoading)
            ? null
            : [AppShadows.softShadow],
      ),
      child: ElevatedButton(
        onPressed: (!puedeAgendar || _isLoading) ? null : _agendarCita,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // ¡IMPORTANTE: transparent!
          foregroundColor: (!puedeAgendar || _isLoading)
              ? Colors.grey[600]
              : Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: (!puedeAgendar || _isLoading)
                        ? Colors.grey[600]
                        : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Agendar Cita',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: (!puedeAgendar || _isLoading)
                          ? Colors.grey[600]
                          : Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }
}
