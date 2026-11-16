import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'leo_mascot.dart';
import 'primary_button.dart';

/// Diálogo modal de éxito para LeoPárvulos (Fase 14).
///
/// Utiliza:
/// - El verde del logo (`AppColors.brandGreen`) como acento celebratorio.
/// - La mascota León Leo en modo celebratorio (`MascotState.celebrating`).
/// - Tipografías del tema: **Baloo 2** para el título y **Andika** para el mensaje.
/// - Botón principal con sombra 3D (`PrimaryButton`).
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final VoidCallback? onConfirm;
  final String? dismissText;
  final VoidCallback? onDismiss;
  final Widget? customContent;
  final bool showMascot;
  final double mascotSize;

  const SuccessDialog({
    super.key,
    this.title = '¡Excelente trabajo!',
    this.message = '¡Has completado la actividad con éxito!',
    this.confirmText = '¡Continuar!',
    this.onConfirm,
    this.dismissText,
    this.onDismiss,
    this.customContent,
    this.showMascot = true,
    this.mascotSize = 120.0,
  });

  /// Muestra el diálogo con una animación fluida de escala y desvanecimiento.
  static Future<T?> show<T>({
    required BuildContext context,
    String title = '¡Excelente trabajo!',
    String message = '¡Has completado la actividad con éxito!',
    String confirmText = '¡Continuar!',
    VoidCallback? onConfirm,
    String? dismissText,
    VoidCallback? onDismiss,
    Widget? customContent,
    bool showMascot = true,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Cerrar diálogo',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim1, anim2) {
        return SuccessDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          onConfirm: onConfirm ?? () => Navigator.of(context).pop(),
          dismissText: dismissText,
          onDismiss: onDismiss ?? (dismissText != null ? () => Navigator.of(context).pop() : null),
          customContent: customContent,
          showMascot: showMascot,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Tarjeta contenedora principal
                Container(
                  margin: EdgeInsets.only(top: showMascot ? mascotSize * 0.45 : 0),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    showMascot ? (mascotSize * 0.55 + 12) : 28,
                    24,
                    24,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.brandGreen.withValues(alpha: 0.6),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: AppColors.brandGreen.withValues(alpha: 0.20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Corona / Insignia verde decorativa
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.brandGreen.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.brandGreen,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFF5D9A14), // Verde oscuro legible
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '¡META ALCANZADA!',
                                style: GoogleFonts.baloo2(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF335707),
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Título principal
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.baloo2(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Mensaje descriptivo con Andika
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.andika(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),

                      if (customContent != null) ...[
                        const SizedBox(height: 16),
                        customContent!,
                      ],

                      const SizedBox(height: 24),

                      // Botón de acción principal
                      PrimaryButton(
                        onPressed: onConfirm ?? () => Navigator.of(context).pop(),
                        text: confirmText,
                        icon: Icons.check_circle_rounded,
                        height: 56,
                      ),

                      if (dismissText != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: AppColors.textMuted,
                          ),
                          child: Text(
                            dismissText!,
                            style: GoogleFonts.baloo2(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Mascota León Leo en modo celebrando colocada en la cabecera
                if (showMascot)
                  Positioned(
                    top: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandGreen.withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: 4,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: LeoMascot(
                        state: MascotState.celebrating,
                        size: mascotSize,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
