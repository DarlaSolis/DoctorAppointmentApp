import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/**
 * Servicio Firebase - Capa de acceso a datos para Firebase Firestore y Auth
 * 
 * Esta clase proporciona todos los métodos necesarios para interactuar con:
 * - Firebase Authentication (usuarios)
 * - Cloud Firestore (datos de la aplicación)
 * - Gestión de citas médicas y disponibilidad
 * - Sistema de roles (Paciente/Médico)
 * 
 * Implementa el patrón Repository para separar la lógica de datos de la UI
 */
class FirebaseService {
  // Instancias de Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========== SISTEMA DE ROLES - NUEVOS MÉTODOS ==========

  /**
   * Obtiene el rol de un usuario específico
   * @param uid ID único del usuario
   * @return String con el rol ('paciente' o 'medico')
   */
  Future<String> obtenerRolUsuario(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['rol'] ?? 'paciente'; // Default a paciente
      }
      return 'paciente'; // Si no existe, retornar paciente por defecto
    } catch (e) {
      print('Error obteniendo rol: $e');
      return 'paciente'; // En caso de error, retornar paciente
    }
  }

  /**
   * Verifica si un usuario tiene rol de médico
   * @param uid ID único del usuario
   * @return true si es médico, false si es paciente
   */
  Future<bool> esMedico(String uid) async {
    try {
      final rol = await obtenerRolUsuario(uid);
      return rol == 'medico';
    } catch (e) {
      print('Error verificando rol médico: $e');
      return false;
    }
  }

  // ========== MÉTODOS PARA DASHBOARD MÉDICO ==========

  /**
   * Obtiene el total de citas de un médico específico
   * @param medicoId ID del médico
   * @return Stream con el número total de citas
   */
  Stream<int> obtenerTotalCitasMedico(String medicoId) {
    return _firestore
        .collection('citas')
        .where('medico_id', isEqualTo: medicoId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /**
   * Obtiene las citas pendientes de un médico específico
   * @param medicoId ID del médico
   * @return Stream con el número de citas pendientes
   */
  Stream<int> obtenerCitasPendientesMedico(String medicoId) {
    return _firestore
        .collection('citas')
        .where('medico_id', isEqualTo: medicoId)
        .where('estado', isEqualTo: 'pendiente')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /**
   * Obtiene el total de pacientes únicos de un médico
   * @param medicoId ID del médico
   * @return Stream con el número de pacientes únicos
   */
  Stream<int> obtenerTotalPacientesMedico(String medicoId) {
    return _firestore
        .collection('citas')
        .where('medico_id', isEqualTo: medicoId)
        .snapshots()
        .map((snapshot) {
          final pacientesIds = <String>{};
          for (final doc in snapshot.docs) {
            pacientesIds.add(doc['paciente_id'] as String);
          }
          return pacientesIds.length;
        });
  }

  // ========== COLECCIÓN USUARIOS - CRUD OPERATIONS ==========

  /**
   * Guarda o actualiza la información de un usuario en Firestore
   * @param uid ID único del usuario desde Firebase Auth
   * @param nombre Nombre completo del usuario
   * @param email Correo electrónico del usuario
   * @param rol Rol del usuario ('paciente' o 'medico')
   * @param telefono Número telefónico (opcional)
   * @param edad Edad del usuario (opcional)
   * @param lugarNacimiento Lugar de nacimiento (opcional)
   * @param padecimientos Condiciones médicas (opcional)
   * 
   * Usa SetOptions(merge: true) para actualizar sin sobrescribir campos existentes
   */
  Future<void> guardarUsuario({
    required String uid,
    required String nombre,
    required String email,
    required String rol,
    String? telefono,
    int? edad,
    String? lugarNacimiento,
    String? padecimientos,
  }) async {
    try {
      await _firestore.collection('usuarios').doc(uid).set({
        'nombre': nombre,
        'email': email,
        'rol': rol,
        'telefono':
            telefono ?? '', // Valores por defecto para campos opcionales
        'edad': edad ?? 0,
        'lugar_nacimiento': lugarNacimiento ?? '',
        'padecimientos': padecimientos ?? '',
        'fecha_creacion':
            FieldValue.serverTimestamp(), // Timestamp automático del servidor
        'ultima_actualizacion': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge evita sobrescribir datos existentes
    } catch (e) {
      print('Error guardando usuario: $e');
      rethrow; // Propaga el error para manejo en la UI
    }
  }

  /**
   * Obtiene los datos de un usuario específico por su UID
   * @param uid ID único del usuario
   * @return Map con datos del usuario o null si no existe
   */
  Future<Map<String, dynamic>?> obtenerUsuario(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null; // Usuario no encontrado
    } catch (e) {
      print('Error obteniendo usuario: $e');
      return null; // Retorna null en caso de error
    }
  }

  /**
   * Actualiza el timestamp de la última sesión del usuario
   * @param uid ID único del usuario
   */
  Future<void> actualizarUltimaSesion(String uid) async {
    try {
      await _firestore.collection('usuarios').doc(uid).update({
        'ultima_sesion': FieldValue.serverTimestamp(),
        'ultima_actualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al actualizar última sesión: $e');
      // No rethrow - error no crítico
    }
  }

  // ========== COLECCIÓN CITAS - CRUD COMPLETO ==========

  /**
   * CREATE - Agenda una nueva cita médica automáticamente con médico disponible
   * @param pacienteId ID del paciente que agenda la cita
   * @param fechaHora Fecha y hora seleccionada para la cita
   * @param motivo Razón de la consulta médica
   * @param especialidad Especialidad médica requerida
   * 
   * Flujo: Busca médico disponible → Crea cita → Marca horario como ocupado
   */
  Future<void> agendarCita({
    required String pacienteId,
    required DateTime fechaHora,
    required String motivo,
    required String especialidad,
    required String medicoId,
    required String medicoNombre,
  }) async {
    final citaData = {
      'paciente_id': pacienteId,
      'medico_id': medicoId,
      'medico_nombre': medicoNombre,
      'especialidad': especialidad,
      'fecha_hora': Timestamp.fromDate(fechaHora),
      'motivo': motivo,
      'estado': 'pendiente',
      'fecha_creacion': Timestamp.now(),
      'ultima_actualizacion': Timestamp.now(),
    };

    await _firestore.collection('citas').add(citaData);
  }

  /**
   * Método privado para encontrar un médico disponible
   * @param fechaHora Fecha y hora deseada para la cita
   * @param especialidad Especialidad médica requerida
   * @return ID del médico disponible encontrado
   * 
   * Estrategia: Busca en disponibilidad → Fallback por especialidad
   */
  Future<String> _obtenerMedicoDisponible(
    DateTime fechaHora,
    String especialidad,
  ) async {
    try {
      // Buscar médicos disponibles en este horario específico
      final horariosDisponibles = await _firestore
          .collection('disponibilidad_medicos')
          .where('hora_inicio', isEqualTo: Timestamp.fromDate(fechaHora))
          .where('esta_disponible', isEqualTo: true)
          .get();

      // Si hay horarios disponibles, usar el primer médico encontrado
      if (horariosDisponibles.docs.isNotEmpty) {
        final medicoId = horariosDisponibles.docs.first['medico_id'] as String;
        print('✅ Médico disponible encontrado: $medicoId');
        return medicoId;
      }

      // Si no hay disponibles, usar fallback por especialidad
      print(
        '⚠️ No hay horarios disponibles, buscando por especialidad: $especialidad',
      );
      return await _obtenerMedicoPorEspecialidad(especialidad);
    } catch (e) {
      print('Error obteniendo médico disponible: $e');
      return await _obtenerMedicoPorEspecialidad(
        especialidad,
      ); // Fallback seguro
    }
  }

  /**
   * Fallback: Asigna médico basado en especialidad (para desarrollo/demo)
   * @param especialidad Especialidad médica requerida
   * @return ID del médico asignado por especialidad
   */
  Future<String> _obtenerMedicoPorEspecialidad(String especialidad) async {
    // Mapeo de especialidades a médicos específicos
    final medicosPorEspecialidad = {
      'Cardiólogo': 'medico_001',
      'Pediatra': 'medico_002',
      'Dermatólogo': 'medico_003',
      'Ortopedista':
          'medico_001', // Algunos médicos tienen múltiples especialidades
      'Ginecólogo': 'medico_002',
    };

    // Obtener médico o usar médico general por defecto
    final medicoId = medicosPorEspecialidad[especialidad] ?? 'medico_general';
    print('✅ Usando médico por especialidad: $medicoId');
    return medicoId;
  }

  /**
   * READ - Obtener citas de un usuario específico con ordenamiento personalizado
   * @param usuarioId ID del usuario cuyas citas se quieren obtener
   * @return Stream de listas de DocumentSnapshot con citas ordenadas
   * 
   * Ordenamiento: Pendientes primero → Mismo estado por fecha → Canceladas al final
   */
  Stream<List<DocumentSnapshot>> obtenerCitasUsuario(String usuarioId) {
    try {
      print('🔍 INICIANDO STREAM para usuario: $usuarioId');
      return _firestore
          .collection('citas')
          .where('paciente_id', isEqualTo: usuarioId)
          // SIN orderBy para evitar problemas de índice temporalmente
          .snapshots()
          .map((snapshot) {
            final citas = snapshot.docs.toList();

            if (citas.isEmpty) {
              print('📭 No hay citas para el usuario');
              return citas;
            }

            print('📄 CITAS RECIBIDAS: ${citas.length}');

            // ORDENAR POR ESTADO: Pendientes primero, Canceladas al final
            citas.sort((a, b) {
              final estadoA = a['estado'] as String? ?? 'pendiente';
              final estadoB = b['estado'] as String? ?? 'pendiente';

              // PENDIENTES primero (valor más bajo = primero)
              if (estadoA == 'pendiente' && estadoB != 'pendiente') return -1;
              if (estadoA != 'pendiente' && estadoB == 'pendiente') return 1;

              // CANCELADAS al final (valor más alto = último)
              if (estadoA == 'cancelada' && estadoB != 'cancelada') return 1;
              if (estadoA != 'cancelada' && estadoB == 'cancelada') return -1;

              // Si tienen el mismo estado, ordenar por fecha (ascendente)
              try {
                final fechaA = (a['fecha_hora'] as Timestamp).toDate();
                final fechaB = (b['fecha_hora'] as Timestamp).toDate();
                return fechaA.compareTo(
                  fechaB,
                ); // Ascendente: más antigua primero
              } catch (e) {
                return 0; // En caso de error, mantener orden original
              }
            });

            // DEBUG: Mostrar orden final en consola
            for (int i = 0; i < citas.length; i++) {
              final doc = citas[i];
              final estado = doc['estado'] as String? ?? 'pendiente';
              final fecha = (doc['fecha_hora'] as Timestamp).toDate();
              final motivo = doc['motivo'] as String? ?? 'Sin motivo';
              print(
                '${i + 1}. Estado: $estado, Fecha: ${fecha.day}/${fecha.month}, Motivo: $motivo',
              );
            }

            return citas;
          })
          .handleError((error) {
            print('❌ ERROR en stream: $error');
            throw error; // Propagar error para manejo en UI
          });
    } catch (e) {
      print('Error obteniendo citas usuario: $e');
      rethrow;
    }
  }

  /**
   * READ - Obtener una cita específica por su ID
   * @param citaId ID único de la cita
   * @return Map con datos de la cita o null si no existe
   */
  Future<Map<String, dynamic>?> obtenerCitaPorId(String citaId) async {
    try {
      final doc = await _firestore.collection('citas').doc(citaId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null; // Cita no encontrada
    } catch (e) {
      print('Error obteniendo cita: $e');
      return null;
    }
  }

  /**
   * READ - Obtener todas las citas (para administradores)
   * @return Stream de todas las citas ordenadas por fecha
   */
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

  /**
   * READ - Obtener citas filtradas por estado
   * @param estado Estado de las citas a filtrar
   * @return Stream de citas con el estado especificado
   */
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

  /**
   * UPDATE - Actualizar una cita existente con nuevo médico disponible
   * @param citaId ID de la cita a actualizar
   * @param nuevaFechaHora Nueva fecha y hora para la cita
   * @param nuevoMotivo Nuevo motivo de la consulta
   * @param nuevaEspecialidad Nueva especialidad requerida
   * 
   * Flujo: Liberar horario anterior → Buscar nuevo médico → Ocupar nuevo horario
   */
  Future<void> actualizarCita({
    required String citaId,
    required DateTime nuevaFechaHora,
    required String nuevoMotivo,
    required String nuevaEspecialidad,
  }) async {
    try {
      // Obtener la cita actual para datos anteriores
      final citaActual = await obtenerCitaPorId(citaId);
      if (citaActual != null) {
        final medicoIdAnterior = citaActual['medico_id'] as String;
        final fechaHoraTimestamp = citaActual['fecha_hora'] as Timestamp;
        final fechaHoraAnterior = fechaHoraTimestamp.toDate();

        // BUSCAR NUEVO MÉDICO DISPONIBLE para el nuevo horario
        final nuevoMedicoId = await _obtenerMedicoDisponible(
          nuevaFechaHora,
          nuevaEspecialidad,
        );

        // Liberar horario anterior solo si cambió médico o fecha
        if (medicoIdAnterior != nuevoMedicoId ||
            fechaHoraAnterior != nuevaFechaHora) {
          await _liberarHorario(medicoIdAnterior, fechaHoraAnterior);
        }

        // Ocupar nuevo horario con el nuevo médico
        await marcarHorarioOcupado(nuevoMedicoId, nuevaFechaHora);

        // Actualizar la cita con los nuevos datos
        await _firestore.collection('citas').doc(citaId).update({
          'medico_id': nuevoMedicoId,
          'fecha_hora': Timestamp.fromDate(nuevaFechaHora),
          'motivo': nuevoMotivo,
          'especialidad': nuevaEspecialidad,
          'ultima_actualizacion': FieldValue.serverTimestamp(),
        });

        print('✅ Cita actualizada con nuevo médico: $nuevoMedicoId');
      }
    } catch (e) {
      print('Error actualizando cita: $e');
      rethrow;
    }
  }

  /**
   * DELETE - Cancelar una cita (soft delete)
   * @param citaId ID de la cita a cancelar
   * 
   * Flujo: Liberar horario → Cambiar estado a "cancelada" → Mantener historial
   */
  Future<void> eliminarCita(String citaId) async {
    try {
      // Obtener datos de la cita antes de cancelar para liberar horario
      final cita = await obtenerCitaPorId(citaId);
      if (cita != null) {
        final medicoId = cita['medico_id'] as String;
        final fechaHoraTimestamp = cita['fecha_hora'] as Timestamp;
        final fechaHora = fechaHoraTimestamp.toDate();

        // Liberar horario para que esté disponible nuevamente
        await _liberarHorario(medicoId, fechaHora);
      }

      // Soft delete: Cambiar estado en lugar de eliminar (para mantener historial)
      await _firestore.collection('citas').doc(citaId).update({
        'estado': 'cancelada',
        'fecha_cancelacion': FieldValue.serverTimestamp(),
      });

      print('✅ Cita cancelada y horario liberado');
    } catch (e) {
      print('Error eliminando cita: $e');
      rethrow;
    }
  }

  // ========== COLECCIÓN DISPONIBILIDAD MÉDICOS ==========

  /**
   * Agregar un nuevo horario disponible para un médico
   * @param medicoId ID del médico
   * @param fecha Fecha del horario
   * @param horaInicio Hora de inicio del horario
   * @param horaFin Hora de fin del horario
   */
  Future<void> agregarHorarioDisponible({
    required String medicoId,
    required DateTime fecha,
    required DateTime horaInicio,
    required DateTime horaFin,
  }) async {
    try {
      // ID único para el horario (medicoId + timestamp)
      final horarioId = '${medicoId}_${fecha.millisecondsSinceEpoch}';

      await _firestore.collection('disponibilidad_medicos').doc(horarioId).set({
        'id': horarioId,
        'medico_id': medicoId,
        'fecha': Timestamp.fromDate(fecha),
        'hora_inicio': Timestamp.fromDate(horaInicio),
        'hora_fin': Timestamp.fromDate(horaFin),
        'esta_disponible': true, // Inicialmente disponible
        'fecha_creacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error agregando horario disponible: $e');
      rethrow;
    }
  }

  /**
   * Marcar un horario específico como ocupado
   * @param medicoId ID del médico
   * @param fechaHora Fecha y hora a marcar como ocupada
   */
  Future<void> marcarHorarioOcupado(String medicoId, DateTime fechaHora) async {
    try {
      final horarios = await _firestore
          .collection('disponibilidad_medicos')
          .where('medico_id', isEqualTo: medicoId)
          .where('hora_inicio', isEqualTo: Timestamp.fromDate(fechaHora))
          .get();

      // Marcar todos los horarios coincidentes como no disponibles
      for (final doc in horarios.docs) {
        await doc.reference.update({'esta_disponible': false});
      }
      print('✅ Horario ocupado para médico: $medicoId');
    } catch (e) {
      print('Error marcando horario ocupado: $e');
      // No rethrow - error no crítico para flujo principal
    }
  }

  /**
   * Método privado para liberar un horario (marcar como disponible)
   * @param medicoId ID del médico
   * @param fechaHora Fecha y hora a liberar
   */
  Future<void> _liberarHorario(String medicoId, DateTime fechaHora) async {
    try {
      final horarios = await _firestore
          .collection('disponibilidad_medicos')
          .where('medico_id', isEqualTo: medicoId)
          .where('hora_inicio', isEqualTo: Timestamp.fromDate(fechaHora))
          .get();

      // Marcar todos los horarios coincidentes como disponibles
      for (final doc in horarios.docs) {
        await doc.reference.update({'esta_disponible': true});
      }
      print('✅ Horario liberado para médico: $medicoId');
    } catch (e) {
      print('Error liberando horario: $e');
      // No rethrow - error no crítico
    }
  }

  // ========== MÉTODOS ADICIONALES ÚTILES ==========

  /**
   * Verificar si un usuario existe en Firestore
   * @param uid ID único del usuario
   * @return true si el usuario existe, false si no
   */
  Future<bool> usuarioExiste(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error verificando usuario: $e');
      return false; // En caso de error, asumir que no existe
    }
  }

  /**
   * Verificar si un usuario tiene privilegios de administrador
   * @param uid ID único del usuario
   * @return true si es admin, false si no
   */
  Future<bool> esUsuarioAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      return doc.data()?['es_admin'] == true; // Verificar campo booleano
    } catch (e) {
      return false; // En caso de error, asumir que no es admin
    }
  }

  /**
   * Obtener horarios disponibles de un médico en una fecha específica
   * @param medicoId ID del médico
   * @param fecha Fecha para consultar disponibilidad
   * @return Stream de horarios disponibles ordenados por hora
   */
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
              DateTime(fecha.year, fecha.month, fecha.day), // Normalizar fecha
            ),
          )
          .where('esta_disponible', isEqualTo: true)
          .orderBy('hora_inicio')
          .snapshots();
    } catch (e) {
      print('❌ Error obteniendo horarios disponibles: $e');
      rethrow;
    }
  }

  // ========== MÉTODOS DE DATOS DE EJEMPLO ==========

  /**
   * Poblar la base de datos con médicos de ejemplo
   * Útil para desarrollo y demostración
   */
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

      print('✅ Médicos de ejemplo creados exitosamente');
    } catch (e) {
      print('Error poblando médicos ejemplo: $e');
    }
  }

  /**
   * Poblar horarios de ejemplo para desarrollo
   */
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

      print('✅ Horarios de ejemplo creados exitosamente');
    } catch (e) {
      print('Error poblando horarios ejemplo: $e');
    }
  }
}
