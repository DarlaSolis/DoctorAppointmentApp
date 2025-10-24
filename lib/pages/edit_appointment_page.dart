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
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _motivoController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedEspecialidad;

  final List<String> _especialidades = [
    'Cardiólogo',
    'Pediatra',
    'Dermatólogo',
    'Ortopedista',
    'Ginecólogo',
  ];

  bool _isLoading = false;
  bool _isSaving = false;

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
    });
  }

  Future<void> _actualizarCita() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedEspecialidad == null) {
      _mostrarError('Por favor complete todos los campos');
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
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final TimeOfDay? seleccionada = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (seleccionada != null) {
      setState(() {
        _selectedTime = seleccionada;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Cita'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
                _buildInfoOriginal(),
                const SizedBox(height: 24),
                _buildEspecialidadSelector(),
                const SizedBox(height: 20),
                _buildDateSelector(),
                const SizedBox(height: 20),
                _buildTimeSelector(),
                const SizedBox(height: 20),
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

  Widget _buildInfoOriginal() {
    final fechaOriginal = (widget.citaData['fecha_hora'] as Timestamp).toDate();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Original:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fecha: ${fechaOriginal.day}/${fechaOriginal.month}/${fechaOriginal.year}',
            ),
            Text(
              'Hora: ${fechaOriginal.hour}:${fechaOriginal.minute.toString().padLeft(2, '0')}',
            ),
            Text('Motivo: ${widget.citaData['motivo']}'),
          ],
        ),
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
        const Text(
          'Nueva Hora *',
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
            onTap: _seleccionarHora,
          ),
        ),
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
              gradient: _isSaving ? null : AppGradients.buttonGradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: _isSaving ? null : [AppShadows.softShadow],
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _actualizarCita,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSaving ? Colors.grey : Colors.transparent,
                foregroundColor: Colors.white,
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
