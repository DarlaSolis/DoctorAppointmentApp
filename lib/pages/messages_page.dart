import 'package:flutter/material.dart';
import '../app_colors.dart';

/**
 * Página de Mensajes - Pantalla funcional de mensajería
 * 
 * Esta página muestra una lista de mensajes entre pacientes y profesionales de la salud
 * con funcionalidad completa para ver y agregar mensajes.
 */
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  // Lista local de mensajes (placeholders)
  final List<Map<String, String>> mensajes = [
    {
      "remitente": "Dr. Ramírez",
      "hora": "10:45 AM",
      "mensaje": "Hola, recuerda tu cita mañana temprano.",
    },
    {
      "remitente": "Clínica Central",
      "hora": "9:12 AM",
      "mensaje": "Tus resultados están disponibles.",
    },
    {
      "remitente": "Nutrióloga Pérez",
      "hora": "Ayer",
      "mensaje": "No olvides enviar tu registro semanal.",
    },
    {
      "remitente": "Dr. González",
      "hora": "Lunes",
      "mensaje": "Tu tratamiento está dando buenos resultados.",
    },
    {
      "remitente": "Administración",
      "hora": "28 Oct",
      "mensaje": "Confirmación de pago recibido.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo consistente con el resto de la aplicación
      backgroundColor: AppColors.background,

      // Barra de aplicación con título
      appBar: AppBar(
        title: const Text('Mensajes'),
        backgroundColor: Colors.transparent,
        elevation: 0, // Sin sombra para diseño plano
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryPurple,
        ),
      ),

      // Lista de mensajes con diseño adaptado a los colores de la app
      body: mensajes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 80,
                    color: AppColors.textLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No hay mensajes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Los mensajes aparecerán aquí',
                    style: TextStyle(fontSize: 16, color: AppColors.textLight),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: mensajes.length,
              itemBuilder: (context, index) {
                final mensaje = mensajes[index];

                return Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                      child: Icon(Icons.person, color: AppColors.primaryBlue),
                    ),
                    title: Text(
                      mensaje["remitente"]!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      mensaje["mensaje"]!,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      mensaje["hora"]!,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),

                    // Gestor para abrir detalles del mensaje
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: Text(
                            mensaje["remitente"]!,
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          content: Text(
                            mensaje["mensaje"]!,
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 16,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Cerrar",
                                style: TextStyle(color: AppColors.primaryBlue),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),

      // Botón para simular agregar un mensaje nuevo
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () {
          setState(() {
            mensajes.insert(0, {
              "remitente": "Sistema Médico",
              "hora": "Ahora",
              "mensaje":
                  "Nuevo mensaje automático de prueba. Esta es una simulación de la funcionalidad de mensajería en desarrollo.",
            });
          });

          // Mostrar snackbar de confirmación
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text(
                'Nuevo mensaje recibido',
                style: TextStyle(color: Colors.white),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
