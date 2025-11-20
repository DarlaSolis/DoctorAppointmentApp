import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_colors.dart';
import '../widgets/gesture_wrapper.dart';

class GraphicsPage extends StatefulWidget {
  const GraphicsPage({super.key});

  @override
  State<GraphicsPage> createState() => _GraphicsPageState();
}

class _GraphicsPageState extends State<GraphicsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  String? _medicoId;

  // Datos para las gráficas
  List<Map<String, dynamic>> _citasPorMes = [];
  List<Map<String, dynamic>> _citasPorEstado = [];
  List<Map<String, dynamic>> _pacientesAtendidos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosGraficas();
  }

  Future<void> _cargarDatosGraficas() async {
    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    _medicoId = user.uid;

    try {
      // Cargar todas las citas del médico
      final citasSnapshot = await _firestore
          .collection('citas')
          .where('medico_id', isEqualTo: _medicoId)
          .get();

      final citas = citasSnapshot.docs;

      // Procesar datos para gráficas
      _procesarCitasPorMes(citas);
      _procesarCitasPorEstado(citas);
      _procesarPacientesAtendidos(citas);

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error cargando datos para gráficas: $e');
      setState(() => _isLoading = false);
    }
  }

  void _procesarCitasPorMes(List<QueryDocumentSnapshot> citas) {
    final ahora = DateTime.now();
    final Map<String, int> citasPorMes = {};

    // Inicializar últimos 6 meses
    for (int i = 5; i >= 0; i--) {
      final mes = DateTime(ahora.year, ahora.month - i);
      final clave = '${mes.month}/${mes.year}';
      citasPorMes[clave] = 0;
    }

    // Contar citas por mes
    for (final cita in citas) {
      final fechaCita = (cita['fecha_hora'] as Timestamp).toDate();
      final clave = '${fechaCita.month}/${fechaCita.year}';

      if (citasPorMes.containsKey(clave)) {
        citasPorMes[clave] = citasPorMes[clave]! + 1;
      }
    }

    _citasPorMes = citasPorMes.entries.map((entry) {
      return {'mes': entry.key, 'cantidad': entry.value};
    }).toList();
  }

  void _procesarCitasPorEstado(List<QueryDocumentSnapshot> citas) {
    final contadorEstados = {
      'pendiente': 0,
      'confirmada': 0,
      'completada': 0,
      'cancelada': 0,
    };

    for (final cita in citas) {
      final estado = cita['estado'] as String? ?? 'pendiente';
      if (contadorEstados.containsKey(estado)) {
        contadorEstados[estado] = contadorEstados[estado]! + 1;
      }
    }

    _citasPorEstado = contadorEstados.entries.map((entry) {
      return {'estado': entry.key, 'cantidad': entry.value};
    }).toList();
  }

  void _procesarPacientesAtendidos(List<QueryDocumentSnapshot> citas) {
    final pacientesUnicos = <String, int>{};

    for (final cita in citas) {
      final pacienteId = cita['paciente_id'] as String? ?? '';
      if (pacienteId.isNotEmpty) {
        pacientesUnicos[pacienteId] = (pacientesUnicos[pacienteId] ?? 0) + 1;
      }
    }

    _pacientesAtendidos = [
      {'tipo': 'Pacientes Únicos', 'cantidad': pacientesUnicos.length},
      {'tipo': 'Total Citas', 'cantidad': citas.length},
    ];
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmada':
        return Colors.blue;
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLabelEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendientes';
      case 'confirmada':
        return 'Confirmadas';
      case 'completada':
        return 'Completadas';
      case 'cancelada':
        return 'Canceladas';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Estadísticas Médicas'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatosGraficas,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: GestureWrapper(
        onRefresh: _cargarDatosGraficas, // ✅ Pull-to-refresh
        enableSwipeBack: true, // ✅ Swipe para regresar
        child: _isLoading ? _buildLoadingState() : _buildGraphicsContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryBlue),
          SizedBox(height: 16),
          Text(
            'Cargando estadísticas...',
            style: TextStyle(color: AppColors.textLight, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphicsContent() {
    return SingleChildScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(), // ✅ Importante para el RefreshIndicator
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildCitasPorMesChart(),
          const SizedBox(height: 20),
          _buildCitasPorEstadoChart(),
          const SizedBox(height: 20),
          _buildPacientesChart(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final totalCitas = _citasPorEstado.fold<int>(
      0,
      (sum, item) => sum + (item['cantidad'] as int),
    );
    final pacientesUnicos =
        _pacientesAtendidos.firstWhere(
              (item) => item['tipo'] == 'Pacientes Únicos',
              orElse: () => {'cantidad': 0},
            )['cantidad']
            as int;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Resumen General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  'Total Citas',
                  totalCitas.toString(),
                  Icons.calendar_today,
                ),
                _buildMetricItem(
                  'Pacientes Únicos',
                  pacientesUnicos.toString(),
                  Icons.people,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildCitasPorMesChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Citas por Mes (Últimos 6 meses)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _citasPorMes.isEmpty
                      ? 10
                      : _citasPorMes
                                .map((e) => e['cantidad'] as int)
                                .reduce((a, b) => a > b ? a : b)
                                .toDouble() +
                            2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${_citasPorMes[groupIndex]['mes']}\n',
                          const TextStyle(color: Colors.white),
                          children: [
                            TextSpan(
                              text: '${rod.toY.toInt()} citas',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _citasPorMes.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _citasPorMes[index]['mes'].toString().split(
                                  '/',
                                )[0],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _citasPorMes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (data['cantidad'] as int).toDouble(),
                          color: AppColors.primaryBlue,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitasPorEstadoChart() {
    final datosFiltrados = _citasPorEstado
        .where((item) => item['cantidad'] > 0)
        .toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Citas por Estado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: datosFiltrados.map((data) {
                    final estado = data['estado'] as String;
                    final cantidad = data['cantidad'] as int;
                    final total = datosFiltrados.fold<int>(
                      0,
                      (sum, item) => sum + (item['cantidad'] as int),
                    );
                    final porcentaje = total > 0
                        ? (cantidad / total * 100).toStringAsFixed(1)
                        : '0';

                    return PieChartSectionData(
                      color: _getColorEstado(estado),
                      value: cantidad.toDouble(),
                      title: '$cantidad\n($porcentaje%)',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLeyendaEstados(datosFiltrados),
          ],
        ),
      ),
    );
  }

  Widget _buildLeyendaEstados(List<Map<String, dynamic>> datos) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: datos.map((data) {
        final estado = data['estado'] as String;
        final cantidad = data['cantidad'] as int;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getColorEstado(estado),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${_getLabelEstado(estado)}: $cantidad',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPacientesChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Pacientes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _pacientesAtendidos.isEmpty
                      ? 10
                      : _pacientesAtendidos
                                .map((e) => e['cantidad'] as int)
                                .reduce((a, b) => a > b ? a : b)
                                .toDouble() +
                            2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${_pacientesAtendidos[groupIndex]['tipo']}\n',
                          const TextStyle(color: Colors.white),
                          children: [
                            TextSpan(
                              text: '${rod.toY.toInt()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 &&
                              index < _pacientesAtendidos.length) {
                            final tipo =
                                _pacientesAtendidos[index]['tipo'] as String;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                tipo.split(' ').first,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _pacientesAtendidos.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (data['cantidad'] as int).toDouble(),
                          color: index == 0
                              ? AppColors.primaryPurple
                              : AppColors.primaryBlue,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
