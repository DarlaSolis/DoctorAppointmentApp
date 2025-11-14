import 'package:flutter/material.dart';

/**
 * Widget que envuelve cualquier contenido con gestos de:
 * - Pull to refresh
 * - Swipe para regresar
 */
class GestureWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;
  final bool enableSwipeBack;

  const GestureWrapper({
    super.key,
    required this.child,
    this.onRefresh,
    this.enableSwipeBack = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Agregar gesto de swipe para regresar
    if (enableSwipeBack) {
      content = GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 100) {
            Navigator.pop(context);
          }
        },
        child: content,
      );
    }

    // Agregar pull to refresh si se proporciona una función
    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: Colors.blue,
        backgroundColor: Colors.white,
        displacement: 40,
        strokeWidth: 3,
        child: content,
      );
    }

    return content;
  }
}
