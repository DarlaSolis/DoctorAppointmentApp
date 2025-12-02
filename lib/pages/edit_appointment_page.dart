import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_colors.dart';
import '../firebase_service.dart';

class EditCitaPage extends StatefulWidget {
  final String citaId;
  final Map<String, dynamic> citaData;

  const EditCitaPage({super.key, required this.citaId, required this.citaData});

  @override
  State<EditCitaPage> createState() => _EditCitaPageState();
}

class _EditCitaPageState extends State<EditCitaPage> {
  final _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _motivoController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedEspecialidad;
  String? _medicoSeleccionadoId;
  String? _medicoSeleccionadoNombre;

  List<Map<String, dynamic>> _horariosDisponibles = [];
  bool _isSaving = false;
  bool _isLoadingHorarios = false;

  final List<String> _especialidades = [
    'Cardiólogo',
    'Pediatra',
    'Dermatólogo',
    'Ortopedista',
    'Ginecólogo',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() {
    final fechaHora = (widget.citaData['fecha_hora'] as Timestamp).toDate();

    setState(() {
      _motivoController.text = widget.citaData['motivo'];
      _selectedEspecialidad = widget.citaData['especialidad'];
      _selectedDate = fechaHora;
      _selectedTime = TimeOfDay(hour: fechaHora.hour, minute: fechaHora.minute);
      _medicoSeleccionadoId = widget.citaData['medico_id'];
      _medicoSeleccionadoNombre = widget.citaData['medico_nombre'];
    });
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

        // Verificar que no sea un horario pasado (solo si es hoy)
        final horaInicio = (data['hora_inicio'] as Timestamp).toDate();
        final esHoy = fechaNormalizada == DateTime.now();
        if (esHoy && horaInicio.isBefore(ahora)) continue;

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

      // Si no hay horarios, mostrar advertencia
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

                        final horaInicioStr =
                            '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}';
                        final horaFinStr =
                            '${horaFin.hour.toString().padLeft(2, '0')}:${horaFin.minute.toString().padLeft(2, '0')}';

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
      // Forzar validación del formulario
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
      });
    }
  }

  Future<void> _actualizarCita() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar campos requeridos
    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedEspecialidad == null ||
        _medicoSeleccionadoId == null) {
      _mostrarError('Por favor complete todos los campos');
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
      _mostrarError('Por favor seleccione un horario disponible de la lista');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Combinar fecha y hora seleccionadas
      final nuevaFechaHora = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await _firebaseService.actualizarCita(
        citaId: widget.citaId,
        nuevaFechaHora: nuevaFechaHora,
        nuevoMotivo: _motivoController.text.trim(),
        nuevaEspecialidad: _selectedEspecialidad!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Cita actualizada exitosamente'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al actualizar cita: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (seleccionada != null && seleccionada != _selectedDate) {
      setState(() {
        _selectedDate = seleccionada;
        _selectedTime = null;
        _horariosDisponibles = [];
      });

      // Forzar validación del formulario
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
      });

      // Cargar horarios disponibles si hay médico seleccionado
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
        title: const Text('Editar Cita'),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildMedicoInfo(),
                const SizedBox(height: 20),
                _buildEspecialidadSelector(),
                const SizedBox(height: 20),
                _buildDateSelector(),
                const SizedBox(height: 20),
                if (_selectedDate != null && _medicoSeleccionadoId != null) ...[
                  _buildTimeSelector(),
                  const SizedBox(height: 20),
                ],
                _buildMotivoField(),
                const SizedBox(height: 30),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicoInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [AppShadows.softShadow],
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: AppColors.primaryBlue, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _medicoSeleccionadoNombre ?? 'Dr. No Especificado',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedEspecialidad ?? 'Especialidad no seleccionada',
                  style: TextStyle(fontSize: 14, color: AppColors.textLight),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${_medicoSeleccionadoId ?? 'No disponible'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildEspecialidadSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Especialidad *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
          onChanged: (value) async {
            setState(() {
              _selectedEspecialidad = value;
              _selectedTime = null; // resetear hora
              _horariosDisponibles = []; // limpiar horarios
            });

            // Forzar validación
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_formKey.currentState != null) {
                _formKey.currentState!.validate();
              }
            });

            // Recargar horarios si ya hay médico
            if (_medicoSeleccionadoId != null && _selectedDate != null) {
              await _cargarHorariosDisponibles();
            }
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
          'Nueva Fecha *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
            onTap: _seleccionarFecha,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          children: [
            const Icon(
              Icons.schedule,
              size: 22,
              color: AppColors.primaryPurple,
            ),
            const SizedBox(width: 8),
            const Text(
              'Nueva Hora *',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),

            // Chip con disponibilidad
            if (_horariosDisponibles.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_horariosDisponibles.length} disponible(s)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // 🌀 CARGANDO HORARIOS
        if (_isLoadingHorarios) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [AppShadows.softShadow],
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Cargando horarios disponibles...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]
        // ⚠️ SIN HORARIOS
        else if (_horariosDisponibles.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade300),
              boxShadow: [AppShadows.softShadow],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_rounded, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'No hay horarios disponibles',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Este médico no tiene horarios disponibles para la fecha seleccionada.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]
        // ✔️ HORARIOS DISPONIBLES
        else ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [AppShadows.softShadow],
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.access_time,
                  color: _selectedTime == null
                      ? Colors.grey
                      : AppColors.primaryBlue,
                ),
              ),
              title: Text(
                _selectedTime == null
                    ? 'Seleccionar horario'
                    : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _selectedTime == null
                      ? Colors.grey
                      : AppColors.textDark,
                ),
              ),
              subtitle: _selectedTime == null
                  ? const Text(
                      'Toque para ver horarios disponibles',
                      style: TextStyle(fontSize: 12),
                    )
                  : null,
              trailing: const Icon(Icons.arrow_drop_down, size: 28),
              onTap: _mostrarSelectorHorarios,
            ),
          ),

          const SizedBox(height: 8),

          if (_selectedTime == null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Seleccione un horario de la lista',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                ),
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
        const Text(
          'Nuevo Motivo *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _motivoController,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'Describa el nuevo motivo de su consulta...',
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
          onChanged: (value) {
            // Forzar validación
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_formKey.currentState != null) {
                _formKey.currentState!.validate();
              }
            });
          },
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

  Widget _buildActionButtons() {
    // Validación para habilitar el botón
    final bool fechaValida = _selectedDate != null;
    final bool horaValida = _selectedTime != null;
    final bool especialidadValida =
        _selectedEspecialidad != null && _selectedEspecialidad!.isNotEmpty;
    final bool medicoValido =
        _medicoSeleccionadoId != null && _medicoSeleccionadoId!.isNotEmpty;
    final bool motivoValido =
        _motivoController.text.isNotEmpty &&
        _motivoController.text.length >= 10;
    final bool hayHorarios = _horariosDisponibles.isNotEmpty;

    final bool puedeGuardar =
        fechaValida &&
        horaValida &&
        especialidadValida &&
        medicoValido &&
        motivoValido &&
        hayHorarios;

    return Row(
      children: [
        // Botón Cancelar
        Expanded(
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.textLight),
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textLight,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Botón Guardar
        Expanded(
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              gradient: (puedeGuardar && !_isSaving)
                  ? AppGradients.buttonGradient
                  : null,
              borderRadius: BorderRadius.circular(15),
              boxShadow: (puedeGuardar && !_isSaving)
                  ? [AppShadows.softShadow]
                  : null,
              color: (!puedeGuardar || _isSaving) ? Colors.grey[300] : null,
            ),
            child: ElevatedButton(
              onPressed: (!puedeGuardar || _isSaving) ? null : _actualizarCita,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: (!puedeGuardar || _isSaving)
                    ? Colors.grey[600]
                    : Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: _isSaving
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
                        Icon(Icons.save, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }
}
