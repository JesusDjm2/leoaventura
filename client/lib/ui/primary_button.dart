import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tamaños del botón principal. Ambos superan el mínimo táctil de 48 dp.
enum PrimaryButtonSize {
  /// 56 dp: acciones de adultos y formularios.
  regular(56, 20),

  /// 72 dp: acciones del niño (empezar, seguir, repetir).
  large(72, 26);

  const PrimaryButtonSize(this.height, this.fontSize);
  final double height;
  final double fontSize;
}

/// Botón principal de LeoAventura.
///
/// Relleno naranja de marca con texto azul marino (5.0:1, AA) y un "canto"
/// inferior en naranja oscuro que da sensación de botón de juego; al
/// presionarlo se hunde. Usa solo tokens de `app_theme.dart`.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.size = PrimaryButtonSize.regular,
    this.semanticLabel,
  });

  final String label;

  /// `null` deshabilita el botón.
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Muestra un indicador y bloquea nuevas pulsaciones.
  final bool isLoading;

  /// Ocupa todo el ancho disponible.
  final bool expand;
  final PrimaryButtonSize size;
  final String? semanticLabel;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  static const double _edge = 5; // alto del canto inferior
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _setPressed(bool v) {
    if (_enabled && v != _pressed) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fill = _enabled
        ? AppColors.brandOrange
        : AppColors.surfaceContainerHighest;
    final edge = _enabled ? AppColors.primary : AppColors.outlineVariant;
    final fg = _enabled ? AppColors.navy : AppColors.textMuted;
    final radius = BorderRadius.circular(widget.size.height / 3);
    final labelStyle = text.labelLarge!.copyWith(
      color: fg,
      fontSize: widget.size.fontSize,
    );
    final offset = _pressed ? _edge : 0.0;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox.square(
            dimension: widget.size.fontSize,
            child: CircularProgressIndicator(strokeWidth: 3, color: fg),
          )
        else if (widget.icon != null)
          Icon(widget.icon, color: fg, size: widget.size.fontSize + 6),
        if (widget.isLoading || widget.icon != null) const SizedBox(width: 12),
        Flexible(
          child: Text(
            widget.label,
            style: labelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      onTap: _enabled ? widget.onPressed : null,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _enabled ? widget.onPressed : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: widget.size.height + _edge,
            minWidth: widget.size.height * 2,
          ),
          child: Container(
            // El canto (sombra sólida) queda debajo; la cara se desplaza al pulsar.
            decoration: BoxDecoration(color: edge, borderRadius: radius),
            padding: const EdgeInsets.only(bottom: _edge),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              transform: Matrix4.translationValues(0, offset, 0),
              constraints: BoxConstraints(minHeight: widget.size.height),
              padding: EdgeInsets.symmetric(
                horizontal: widget.size.height / 2.2,
              ),
              alignment: widget.expand ? Alignment.center : null,
              decoration: BoxDecoration(color: fill, borderRadius: radius),
              child: Center(widthFactor: 1, heightFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}
