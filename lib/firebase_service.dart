import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========== COLECCIÓN USUARIOS ==========
  Future<void> guardarUsuario({
    required String uid,
    required String nombre,
    required String email,
    String? telefono,
    int? edad,
    String? lugarNacimiento,
    String? padecimientos,
  }) async {
    try {
      await _firestore.collection('usuarios').doc(uid).set({
        'nombre': nombre,
        'email': email,
        'telefono': telefono ?? '',
        'edad': edad ?? 0,
        'lugar_nacimiento': lugarNacimiento ?? '',
        'padecimientos': padecimientos ?? '',
        'fecha_creacion': FieldValue.serverTimestamp(),
        'ultima_actualizacion': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error guardando usuario: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> obtenerUsuario(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error obteniendo usuario: $e');
      return null;
    }
  }

  Future<void> actualizarUltimaSesion(String uid) async {
    try {
      await _firestore.collection('usuarios').doc(uid).update({
        'ultima_sesion': FieldValue.serverTimestamp(),
        'ultima_actualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al actualizar última sesión: $e');
    }
  }

  // ========== COLECCIÓN CITAS - CRUD COMPLETO ==========

  // CREATE - Crear nueva cita SIEMPRE con médico disponible
  Future<void> agendarCita({
    required String pacienteId,
    required DateTime fechaHora,
    required String motivo,
    required String especialidad,
  }) async {
    try {
      // BUSCAR UN MÉDICO DISPONIBLE para esta fecha/hora
      final medicoId = await _obtenerMedicoDisponible(fechaHora, especialidad);

      final citaRef = _firestore.collection('citas').doc();

      await citaRef.set({
        'id': citaRef.id,
        'paciente_id': pacienteId,
        'medico_id': medicoId,
        'fecha_hora': Timestamp.fromDate(fechaHora),
        'motivo': motivo,
        'especialidad': especialidad,
        'estado': 'pendiente',
        'fecha_creacion': FieldValue.serverTimestamp(),
      });

      // Marcar horario como ocupado
      await marcarHorarioOcupado(medicoId, fechaHora);

      print(' Cita agendada con médico: $medicoId');
    } catch (e) {
      print('Error agendando cita: $e');
      rethrow;
    }
  }

  // Método para obtener un médico disponible
  Future<String> _obtenerMedicoDisponible(
    DateTime fechaHora,
    String especialidad,
  ) async {
    try {
      // Buscar médicos disponibles en este horario
      final horariosDisponibles = await _firestore
          .collection('disponibilidad_medicos')
          .where('hora_inicio', isEqualTo: Timestamp.fromDate(fechaHora))
          .where('esta_disponible', isEqualTo: true)
          .get();

      if (horariosDisponibles.docs.isNotEmpty) {
        // Usar el primer médico disponible
        final medicoId = horariosDisponibles.docs.first['medico_id'] as String;
        print('Médico disponible encontrado: $medicoId');
        return medicoId;
      }

      // Si no hay disponibles, buscar médico por especialidad
      print(
        'No hay horarios disponibles, buscando por especialidad: $especialidad',
      );
      return await _obtenerMedicoPorEspecialidad(especialidad);
    } catch (e) {
      print('Error obteniendo médico disponible: $e');
      return await _obtenerMedicoPorEspecialidad(especialidad); // Fallback
    }
  }

  // Asignar médico por especialidad como fallback
  Future<String> _obtenerMedicoPorEspecialidad(String especialidad) async {
    final medicosPorEspecialidad = {
      'Cardiólogo': 'medico_001',
      'Pediatra': 'medico_002',
      'Dermatólogo': 'medico_003',
      'Ortopedista': 'medico_001',
      'Ginecólogo': 'medico_002',
    };

    final medicoId = medicosPorEspecialidad[especialidad] ?? 'medico_general';
    print('Usando médico por especialidad: $medicoId');
    return medicoId;
  }

  // READ - Obtener citas del usuario
  Stream<QuerySnapshot> obtenerCitasUsuario(String usuarioId) {
    try {
      print('🔍 INICIANDO STREAM para usuario: $usuarioId');
      return _firestore
          .collection('citas')
          .where('paciente_id', isEqualTo: usuarioId)
          .orderBy('fecha_hora', descending: false)
          .snapshots()
          .handleError((error) {
            print('ERROR en stream: $error');
            throw error;
          });
    } catch (e) {
      print('Error obteniendo citas usuario: $e');
      rethrow;
    }
  }

  // READ - Obtener cita específica por ID
  Future<Map<String, dynamic>?> obtenerCitaPorId(String citaId) async {
    try {
      final doc = await _firestore.collection('citas').doc(citaId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error obteniendo cita: $e');
      return null;
    }
  }

  // READ - Obtener todas las citas (para admin)
  Stream<QuerySnapshot> obtenerTodasLasCitas() {
    try {
      return _firestore
          .collection('citas')
          .orderBy('fecha_hora', descending: false)
          .snapshots();
    } catch (e) {
      print('Error obteniendo todas las citas: $e');
      rethrow;
    }
  }

  // READ - Obtener citas por estado
  Stream<QuerySnapshot> obtenerCitasPorEstado(String estado) {
    try {
      return _firestore
          .collection('citas')
          .where('estado', isEqualTo: estado)
          .orderBy('fecha_hora', descending: false)
          .snapshots();
    } catch (e) {
      print('Error obteniendo citas por estado: $e');
      rethrow;
    }
  }

  // UPDATE - Actualizar cita con médico disponible
  Future<void> actualizarCita({
    required String citaId,
    required DateTime nuevaFechaHora,
    required String nuevoMotivo,
    required String nuevaEspecialidad,
  }) async {
    try {
      // Obtener la cita actual
      final citaActual = await obtenerCitaPorId(citaId);
      if (citaActual != null) {
        final medicoIdAnterior = citaActual['medico_id'] as String;
        final fechaHoraTimestamp = citaActual['fecha_hora'] as Timestamp;
        final fechaHoraAnterior = fechaHoraTimestamp.toDate();

        // BUSCAR MÉDICO DISPONIBLE para el nuevo horario
        final nuevoMedicoId = await _obtenerMedicoDisponible(
          nuevaFechaHora,
          nuevaEspecialidad,
        );

        // Liberar horario anterior si el médico cambió
        if (medicoIdAnterior != nuevoMedicoId ||
            fechaHoraAnterior != nuevaFechaHora) {
          await _liberarHorario(medicoIdAnterior, fechaHoraAnterior);
        }

        // Ocupar nuevo horario
        await marcarHorarioOcupado(nuevoMedicoId, nuevaFechaHora);

        // Actualizar la cita
        await _firestore.collection('citas').doc(citaId).update({
          'medico_id': nuevoMedicoId,
          'fecha_hora': Timestamp.fromDate(nuevaFechaHora),
          'motivo': nuevoMotivo,
          'especialidad': nuevaEspecialidad,
          'ultima_actualizacion': FieldValue.serverTimestamp(),
        });

        print('Cita actualizada con nuevo médico: $nuevoMedicoId');
      }
    } catch (e) {
      print('Error actualizando cita: $e');
      rethrow;
    }
  }

  // DELETE - Eliminar/Cancelar cita
  Future<void> eliminarCita(String citaId) async {
    try {
      // Obtener datos de la cita antes de cancelar
      final cita = await obtenerCitaPorId(citaId);
      if (cita != null) {
        final medicoId = cita['medico_id'] as String;
        final fechaHoraTimestamp = cita['fecha_hora'] as Timestamp;
        final fechaHora = fechaHoraTimestamp.toDate();

        // Liberar horario para que esté disponible nuevamente
        await _liberarHorario(medicoId, fechaHora);
      }

      // Actualizar estado en lugar de eliminar (para mantener historial)
      await _firestore.collection('citas').doc(citaId).update({
        'estado': 'cancelada',
        'fecha_cancelacion': FieldValue.serverTimestamp(),
      });

      print('Cita cancelada y horario liberado');
    } catch (e) {
      print('Error eliminando cita: $e');
      rethrow;
    }
  }

  // ========== COLECCIÓN DISPONIBILIDAD MÉDICOS ==========
  Future<void> agregarHorarioDisponible({
    required String medicoId,
    required DateTime fecha,
    required DateTime horaInicio,
    required DateTime horaFin,
  }) async {
    try {
      final horarioId = '${medicoId}_${fecha.millisecondsSinceEpoch}';

      await _firestore.collection('disponibilidad_medicos').doc(horarioId).set({
        'id': horarioId,
        'medico_id': medicoId,
        'fecha': Timestamp.fromDate(fecha),
        'hora_inicio': Timestamp.fromDate(horaInicio),
        'hora_fin': Timestamp.fromDate(horaFin),
        'esta_disponible': true,
        'fecha_creacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error agregando horario disponible: $e');
      rethrow;
    }
  }

  Future<void> marcarHorarioOcupado(String medicoId, DateTime fechaHora) async {
    try {
      final horarios = await _firestore
          .collection('disponibilidad_medicos')
          .where('medico_id', isEqualTo: medicoId)
          .where('hora_inicio', isEqualTo: Timestamp.fromDate(fechaHora))
          .get();

      for (final doc in horarios.docs) {
        await doc.reference.update({'esta_disponible': false});
      }
      print('Horario ocupado para médico: $medicoId');
    } catch (e) {
      print('Error marcando horario ocupado: $e');
    }
  }

  // Liberar horario cuando se cancela o actualiza una cita
  Future<void> _liberarHorario(String medicoId, DateTime fechaHora) async {
    try {
      final horarios = await _firestore
          .collection('disponibilidad_medicos')
          .where('medico_id', isEqualTo: medicoId)
          .where('hora_inicio', isEqualTo: Timestamp.fromDate(fechaHora))
          .get();

      for (final doc in horarios.docs) {
        await doc.reference.update({'esta_disponible': true});
      }
      print('Horario liberado para médico: $medicoId');
    } catch (e) {
      print('Error liberando horario: $e');
    }
  }

  // ========== MÉTODOS ADICIONALES ÚTILES ==========

  // Verificar si usuario existe
  Future<bool> usuarioExiste(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error verificando usuario: $e');
      return false;
    }
  }

  // Verificar si usuario es admin (opcional)
  Future<bool> esUsuarioAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      return doc.data()?['es_admin'] == true;
    } catch (e) {
      return false;
    }
  }

  // Obtener horarios disponibles de un médico
  Stream<QuerySnapshot> obtenerHorariosDisponibles(
    String medicoId,
    DateTime fecha,
  ) {
    try {
      return _firestore
          .collection('disponibilidad_medicos')
          .where('medico_id', isEqualTo: medicoId)
          .where(
            'fecha',
            isEqualTo: Timestamp.fromDate(
              DateTime(fecha.year, fecha.month, fecha.day),
            ),
          )
          .where('esta_disponible', isEqualTo: true)
          .orderBy('hora_inicio')
          .snapshots();
    } catch (e) {
      print('Error obteniendo horarios disponibles: $e');
      rethrow;
    }
  }

  // ========== MÉTODOS PARA DATOS DE EJEMPLO ==========

  // Poblar médicos de ejemplo
  Future<void> poblarMedicosEjemplo() async {
    try {
      final List<Map<String, dynamic>> medicos = [
        {
          'id': 'medico_001',
          'nombre': 'Dr. Carlos Rodríguez',
          'especialidad': 'Cardiólogo',
          'email': 'carlos.rodriguez@hospital.com',
          'telefono': '+1234567890',
          'experiencia': '10 años',
          'fecha_creacion': FieldValue.serverTimestamp(),
        },
        {
          'id': 'medico_002',
          'nombre': 'Dra. María González',
          'especialidad': 'Pediatra',
          'email': 'maria.gonzalez@hospital.com',
          'telefono': '+1234567891',
          'experiencia': '8 años',
          'fecha_creacion': FieldValue.serverTimestamp(),
        },
        {
          'id': 'medico_003',
          'nombre': 'Dr. Javier López',
          'especialidad': 'Dermatólogo',
          'email': 'javier.lopez@hospital.com',
          'telefono': '+1234567892',
          'experiencia': '12 años',
          'fecha_creacion': FieldValue.serverTimestamp(),
        },
      ];

      for (final medico in medicos) {
        final medicoId = medico['id'] as String;
        await _firestore.collection('medicos').doc(medicoId).set(medico);
      }

      print('Médicos de ejemplo creados exitosamente');
    } catch (e) {
      print('Error poblando médicos ejemplo: $e');
    }
  }

  // Poblar horarios de ejemplo
  Future<void> poblarHorariosEjemplo() async {
    try {
      final ahora = DateTime.now();

      for (int i = 0; i < 7; i++) {
        final fecha = ahora.add(Duration(days: i));

        // Horarios para cada médico
        for (int j = 1; j <= 3; j++) {
          final medicoId = 'medico_00$j';

          // Agregar varios horarios por día
          await agregarHorarioDisponible(
            medicoId: medicoId,
            fecha: fecha,
            horaInicio: DateTime(fecha.year, fecha.month, fecha.day, 9, 0),
            horaFin: DateTime(fecha.year, fecha.month, fecha.day, 10, 0),
          );

          await agregarHorarioDisponible(
            medicoId: medicoId,
            fecha: fecha,
            horaInicio: DateTime(fecha.year, fecha.month, fecha.day, 11, 0),
            horaFin: DateTime(fecha.year, fecha.month, fecha.day, 12, 0),
          );

          await agregarHorarioDisponible(
            medicoId: medicoId,
            fecha: fecha,
            horaInicio: DateTime(fecha.year, fecha.month, fecha.day, 15, 0),
            horaFin: DateTime(fecha.year, fecha.month, fecha.day, 16, 0),
          );
        }
      }

      print('Horarios de ejemplo creados exitosamente');
    } catch (e) {
      print('Error poblando horarios ejemplo: $e');
    }
  }

  // ========== MÉTODOS DE LIMPIEZA (para desarrollo) ==========

  // Limpiar todas las citas (solo para desarrollo)
  Future<void> limpiarTodasLasCitas() async {
    try {
      final citas = await _firestore.collection('citas').get();
      for (final doc in citas.docs) {
        await doc.reference.delete();
      }
      print('Todas las citas eliminadas');
    } catch (e) {
      print('Error limpiando citas: $e');
    }
  }

  // Restablecer horarios disponibles (solo para desarrollo)
  Future<void> restablecerHorariosDisponibles() async {
    try {
      final horarios = await _firestore
          .collection('disponibilidad_medicos')
          .get();
      for (final doc in horarios.docs) {
        await doc.reference.update({'esta_disponible': true});
      }
      print(' Horarios restablecidos a disponibles');
    } catch (e) {
      print('Error restableciendo horarios: $e');
    }
  }
}
