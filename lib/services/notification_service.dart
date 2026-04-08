import 'package:flutter/material.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void showSuccess(String message) {
    if (!_showNotification(
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      duration: const Duration(seconds: 3),
    )) {
      _showSnackBarFallback(message, Colors.green);
    }
  }

  static void showError(String message) {
    if (!_showNotification(
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error,
      duration: const Duration(seconds: 5),
    )) {
      _showSnackBarFallback(message, Colors.red);
    }
  }

  static void showInfo(String message) {
    if (!_showNotification(
      message: message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
      duration: const Duration(seconds: 3),
    )) {
      _showSnackBarFallback(message, Colors.blue);
    }
  }

  static void showWarning(String message) {
    if (!_showNotification(
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
      duration: const Duration(seconds: 4),
    )) {
      _showSnackBarFallback(message, Colors.orange);
    }
  }

  static void _showSnackBarFallback(String message, Color color) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: color,
              duration: const Duration(seconds: 3),
            ),
          );
        } catch (e) {
          print('Erreur lors de l\'affichage du SnackBar: $e');
        }
      }
    });
  }

  static bool _showNotification({
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context == null) return;

        // Vérifier si le contexte est encore valide
        if (!context.mounted) return;

        try {
          final overlay = Overlay.of(context);
          if (overlay == null) return;
          
          late OverlayEntry overlayEntry;

          overlayEntry = OverlayEntry(
            builder: (context) => _NotificationWidget(
              message: message,
              backgroundColor: backgroundColor,
              icon: icon,
              onRemove: () => overlayEntry.remove(),
            ),
          );

          overlay.insert(overlayEntry);

          // Auto-remove after duration
          Future.delayed(duration, () {
            if (overlayEntry.mounted) {
              overlayEntry.remove();
            }
          });
        } catch (e) {
          // Silencieusement ignorer les erreurs d'overlay
          print('Erreur lors de l\'affichage de la notification: $e');
        }
      });
      return true; // Succès
    } catch (e) {
      print('Erreur critique dans _showNotification: $e');
      return false; // Échec
    }
  }
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onRemove;

  const _NotificationWidget({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onRemove,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onRemove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: widget.backgroundColor,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: widget.backgroundColor,
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismiss,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
