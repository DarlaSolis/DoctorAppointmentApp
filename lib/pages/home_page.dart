import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_colors.dart';
import 'messages_page.dart';
import 'settings_page.dart';
import 'medical_tips_page.dart';
import 'appointment_booking_page.dart';
import '../firebase_service.dart';
import 'edit_appointment_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final _firebaseService = FirebaseService();

  String? userName;
  String? userEmail;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userData = await _firebaseService.obtenerUsuario(user.uid);
        setState(() {
          userName =
              userData?['nombre'] ??
              user.displayName ??
              user.email?.split('@').first ??
              'Usuario';
          userEmail = user.email;
        });

        // Actualizar última sesión
        await _firebaseService.actualizarUltimaSesion(user.uid);
      } catch (e) {
        print('Error cargando datos usuario: $e');
        setState(() {
          userName = user.email?.split('@').first ?? 'Usuario';
          userEmail = user.email;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _getCurrentPage(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const MessagesPage();
      case 2:
        return const SettingsPage();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 30),
                _buildMainActions(),
                const SizedBox(height: 30),
                _buildSpecialistsSection(),
                const SizedBox(height: 30),
                _buildNextAppointments(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        boxShadow: [AppShadows.mediumShadow],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [AppShadows.mediumShadow],
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://cdn-icons-png.flaticon.com/512/3844/3844988.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.medical_services,
                        size: 20,
                        color: Colors.white,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Citas Médicas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.cardGradient,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [AppShadows.softShadow],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [AppShadows.mediumShadow],
              ),
              child: ClipOval(
                child: Image.network(
                  'https://cdn-icons-png.flaticon.com/512/3844/3844988.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.medical_services,
                      size: 40,
                      color: Colors.white,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '¡Hola, $userName! ¿En qué podemos ayudarte?',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              userEmail ?? '',
              style: TextStyle(fontSize: 16, color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.calendar_today,
            title: 'Agendar Cita',
            color: AppColors.primaryBlue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppointmentBookingPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            icon: Icons.medical_information,
            title: 'Consejos Médicos',
            color: AppColors.primaryPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicalTipsPage(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialistsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Especialistas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildSpecialistCard(
                'Cardiólogo',
                Icons.favorite,
                AppColors.primaryBlue,
              ),
              const SizedBox(width: 12),
              _buildSpecialistCard(
                'Pediatra',
                Icons.child_care,
                AppColors.primaryPurple,
              ),
              const SizedBox(width: 12),
              _buildSpecialistCard(
                'Dermatólogo',
                Icons.face,
                AppColors.accentBlue,
              ),
              const SizedBox(width: 12),
              _buildSpecialistCard(
                'Ortopedista',
                Icons.accessible,
                AppColors.accentPurple,
              ),
              const SizedBox(width: 12),
              _buildSpecialistCard(
                'Ginecólogo',
                Icons.female,
                Color(0xFFFF6B6B),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialistCard(String title, IconData icon, Color color) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppShadows.softShadow],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // === SECCIÓN CORREGIDA - PRÓXIMAS CITAS ===
  Widget _buildNextAppointments() {
    final user = _auth.currentUser;
    if (user == null) {
      return _buildMessageCard('Usuario no autenticado');
    }

    print('🔄 CONSTRUYENDO _buildNextAppointments para: ${user.uid}'); // DEBUG

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
        StreamBuilder<QuerySnapshot>(
          stream: _firebaseService.obtenerCitasUsuario(user.uid),
          builder: (context, snapshot) {
            // DEBUG MEJORADO
            print(' STREAMBUILDER - Estado: ${snapshot.connectionState}');
            print(' STREAMBUILDER - Tiene error: ${snapshot.hasError}');
            print(' STREAMBUILDER - Tiene datos: ${snapshot.hasData}');
            if (snapshot.hasData) {
              print(
                ' STREAMBUILDER - Número de documentos: ${snapshot.data!.docs.length}',
              );
              // Mostrar IDs de las citas para verificar
              for (final doc in snapshot.data!.docs) {
                print('📄 Cita ID: ${doc.id} - Estado: ${doc['estado']}');
              }
            }

            if (snapshot.hasError) {
              return _buildErrorCard('Error: ${snapshot.error}');
            }

            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return _buildLoadingCard();
              case ConnectionState.active:
              case ConnectionState.done:
                if (!snapshot.hasData) {
                  return _buildMessageCard('No hay datos disponibles');
                }

                final citas = snapshot.data!.docs;

                if (citas.isEmpty) {
                  return _buildEmptyCard();
                }

                return Column(
                  children: [
                    // Indicador de última actualización
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 181, 224, 254),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Última actualización: ${DateTime.now().toString()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: citas.length,
                      itemBuilder: (context, index) {
                        try {
                          final citaDoc = citas[index];
                          final citaData =
                              citaDoc.data() as Map<String, dynamic>;
                          final citaId = citaDoc.id;
                          final citaConId = {...citaData, 'id': citaId};
                          return _buildCitaCard(citaConId);
                        } catch (e) {
                          print('Error construyendo cita card: $e');
                          return _buildErrorCard('Error mostrando cita: $e');
                        }
                      },
                    ),
                  ],
                );
              default:
                return _buildLoadingCard();
            }
          },
        ),
      ],
    );
  }

  // Widgets auxiliares para diferentes estados
  Widget _buildLoadingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Cargando citas...'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.calendar_today, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No tienes citas programadas',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Agenda tu primera cita médica',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            const Text(
              'Error al cargar citas',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              message.length > 100
                  ? '${message.substring(0, 100)}...'
                  : message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Forzar rebuild
                setState(() {});
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(String message) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }

  // === MÉTODO _buildCitaCard CORREGIDO ===
  Widget _buildCitaCard(Map<String, dynamic> cita) {
    try {
      // Manejo seguro de la fecha
      final fechaHora = cita['fecha_hora'];
      DateTime fecha;

      if (fechaHora is Timestamp) {
        fecha = fechaHora.toDate();
      } else if (fechaHora is DateTime) {
        fecha = fechaHora;
      } else {
        fecha = DateTime.now();
      }

      final citaId = cita['id'] ?? 'unknown';
      final estado = cita['estado'] ?? 'pendiente';
      final especialidad = cita['especialidad'] ?? 'Sin especialidad';
      final motivo = cita['motivo'] ?? 'Sin motivo especificado';

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    especialidad,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getColorEstado(estado),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estado.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}'),
              Text(
                'Hora: ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
              ),
              Text('Motivo: $motivo'),
              const SizedBox(height: 12),

              if (estado == 'pendiente')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Editar'),
                        onPressed: () => _editarCita(citaId, cita),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: BorderSide(color: AppColors.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Cancelar'),
                        onPressed: () => _cancelarCita(citaId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error en _buildCitaCard: $e');
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Error mostrando cita'),
        ),
      );
    }
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _editarCita(String citaId, Map<String, dynamic> citaData) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCitaPage(citaId: citaId, citaData: citaData),
      ),
    );
  }

  Future<void> _cancelarCita(String citaId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Cita'),
        content: const Text('¿Estás seguro de que quieres cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _firebaseService.eliminarCita(citaId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita cancelada exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar cita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [AppShadows.mediumShadow],
        color: Colors.white,
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mensajes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}
