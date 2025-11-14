import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_colors.dart';
import '../firebase_service.dart';

class AppointmentBookingPage extends StatefulWidget {
  const AppointmentBookingPage({super.key});

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  final _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _motivoController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedEspecialidad;
  String? _medicoSeleccionadoId;
  String? _medicoSeleccionadoNombre;
  bool _isLoading = false;
  bool _isLoadingMedicos = false;

  final List<String> _especialidades = [
    'Cardiólogo',
    'Pediatra',
    'Dermatólogo',
    'Ortopedista',
    'Ginecólogo',
  ];

  // NUEVO: Lista de médicos
  List<QueryDocumentSnapshot> _medicos = [];

  @override
  void initState() {
    super.initState();
    _cargarMedicos();
  }

  // NUEVO: Cargar médicos desde Firestore
  Future<void> _cargarMedicos() async {
    setState(() => _isLoadingMedicos = true);
    try {
      final snapshot = await FirebaseFirestore.instance
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

  Future<void> _agendarCita() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedEspecialidad == null ||
        _medicoSeleccionadoId == null) {
      // ← NUEVA VALIDACIÓN
      _showErrorSnackbar('Por favor complete todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackbar('Usuario no autenticado');
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
      );

      // NUEVO: Agendar cita con médico seleccionado
      await _firebaseService.agendarCita(
        pacienteId: user.uid,
        fechaHora: fechaHora,
        motivo: _motivoController.text.trim(),
        especialidad: _selectedEspecialidad!,
        medicoId: _medicoSeleccionadoId!, // ← NUEVO PARÁMETRO
        medicoNombre: _medicoSeleccionadoNombre!, // ← NUEVO PARÁMETRO
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Cita agendada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        _formKey.currentState?.reset();
        setState(() {
          _selectedDate = null;
          _selectedTime = null;
          _selectedEspecialidad = null;
          _medicoSeleccionadoId = null; // ← LIMPIAR MÉDICO
          _medicoSeleccionadoNombre = null;
          _motivoController.clear();
        });
      }
    } catch (e) {
      print('Error agendando cita: $e');
      if (mounted) {
        _showErrorSnackbar('Error al agendar cita: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
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
                _buildMedicoSelector(), // ← NUEVO SELECTOR DE MÉDICO
                const SizedBox(height: 20),
                _buildDateSelector(),
                const SizedBox(height: 20),
                _buildTimeSelector(),
                const SizedBox(height: 20),
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

  // NUEVO: Selector de médico
  Widget _buildMedicoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seleccionar Médico *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
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
                CircularProgressIndicator(strokeWidth: 2),
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
                    'No hay médicos disponibles. Contacte al administrador.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          DropdownButtonFormField<String>(
            value: _medicoSeleccionadoId,
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
            ),
            items: _medicos.map((medicoDoc) {
              final data = medicoDoc.data() as Map<String, dynamic>;
              final nombre = data['nombre'] ?? 'Médico';
              final especialidad = data['especialidad'] ?? 'General';

              return DropdownMenuItem<String>(
                value: medicoDoc.id,
                child: Text(
                  'Dr. $nombre - $especialidad',
                  style: const TextStyle(color: AppColors.textDark),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _medicoSeleccionadoId = newValue;
                if (newValue != null) {
                  final medico = _medicos.firstWhere(
                    (doc) => doc.id == newValue,
                  );
                  final data = medico.data() as Map<String, dynamic>;
                  _medicoSeleccionadoNombre = data['nombre'] ?? 'Médico';
                }
              });
            },
            validator: (value) => value == null ? 'Seleccione un médico' : null,
          ),
        ],
      ],
    );
  }

  // Los demás métodos permanecen igual (_buildEspecialidadSelector, _buildDateSelector, etc.)
  Widget _buildEspecialidadSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Especialidad *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
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
          ),
          items: _especialidades.map((esp) {
            return DropdownMenuItem(
              value: esp,
              child: Text(
                esp,
                style: const TextStyle(color: AppColors.textDark),
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
        const Text(
          'Fecha de la cita *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
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
            leading: const Icon(
              Icons.calendar_today,
              color: AppColors.primaryBlue,
            ),
            title: Text(
              _selectedDate == null
                  ? 'Seleccionar fecha'
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: const TextStyle(color: AppColors.textDark),
            ),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: _selectDate,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hora de la cita *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
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
            leading: const Icon(
              Icons.access_time,
              color: AppColors.primaryBlue,
            ),
            title: Text(
              _selectedTime == null
                  ? 'Seleccionar hora'
                  : _selectedTime!.format(context),
              style: const TextStyle(color: AppColors.textDark),
            ),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: _selectedDate == null ? null : _selectTime,
          ),
        ),
        if (_selectedDate == null) ...[
          const SizedBox(height: 8),
          Text(
            'Primero selecciona una fecha',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ],
    );
  }

  Widget _buildMotivoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Motivo de la consulta *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _motivoController,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'Describa el motivo de su consulta...',
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
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: _isLoading ? null : AppGradients.buttonGradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: _isLoading ? null : [AppShadows.softShadow],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _agendarCita,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? Colors.grey : Colors.transparent,
          foregroundColor: Colors.white,
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
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Agendar Cita',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
