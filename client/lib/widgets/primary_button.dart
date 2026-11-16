import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Botón interactivo principal para LeoPárvulos (Fase 14).
///
/// Diseñado con ergonomía infantil:
/// - Tamaño grande (altura mínima ≥ 56dp) para párvulos (3 a 6 años).
/// - Efecto 3D táctil suave (bisel inferior con compresión física al presionar).
/// - Color naranja de marca (`AppColors.brandOrange`) con contraste accesible
///   frente al texto `AppColors.navy` (5.0:1 WCAG AA).
/// - Tipografía amigable redondeada **Baloo 2**.
class PrimaryButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String? text;
  final Widget? child;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final Color backgroundColor;
  final Color bevelColor;
  final Color textColor;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final TextStyle? textStyle;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    this.text,
    this.child,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 58.0,
    this.backgroundColor = AppColors.brandOrange,
    this.bevelColor = const Color(0xFFD46B00), // Naranja oscuro para el bisel 3D
    this.textColor = AppColors.navy,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.elevation = 5.0,
    this.textStyle,
  }) : assert(text != null || child != null, 'Debe proveer `text` o `child`');

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _handleTapDown(TapDownDetails _) {
    if (_isEnabled) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isEnabled) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isEnabled) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = widget.height;
    final currentElevation = _isEnabled
        ? (_isPressed ? 1.5 : widget.elevation)
        : 1.0;
    final translationY = _isEnabled && _isPressed ? widget.elevation - 1.5 : 0.0;

    final bgColor = _isEnabled ? widget.backgroundColor : const Color(0xFFE2E8F0);
    final bevelColor = _isEnabled ? widget.bevelColor : const Color(0xFFCBD5E1);
    final fgColor = _isEnabled ? widget.textColor : const Color(0xFF94A3B8);

    final defaultTextStyle = GoogleFonts.baloo2(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: fgColor,
      height: 1.15,
    );

    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 3.0,
          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
        ),
      );
    } else if (widget.child != null) {
      content = widget.child!;
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 24, color: fgColor),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              widget.text!,
              style: widget.textStyle ?? defaultTextStyle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.text,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _isEnabled ? widget.onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          curve: Curves.easeOutQuad,
          transform: Matrix4.translationValues(0, translationY, 0),
          width: widget.width,
          height: effectiveHeight,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: widget.borderRadius,
            // Bisel inferior 3D y sombra ambiental difusa
            boxShadow: [
              // Sombra sólida del borde inferior (extrusión 3D)
              BoxShadow(
                color: bevelColor,
                offset: Offset(0, currentElevation),
                blurRadius: 0,
              ),
              // Sombra ambiental suave
              if (_isEnabled && !_isPressed)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  offset: Offset(0, currentElevation + 3),
                  blurRadius: 8,
                ),
            ],
          ),
          padding: widget.padding,
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}
