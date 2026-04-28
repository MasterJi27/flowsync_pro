import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A glassmorphism card with 3D depth effects.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 24,
    this.elevation = 12,
    this.blur = 16,
    this.opacity = 0.12,
    this.borderColor,
    this.onTap,
    this.animated = true,
    this.duration,
    this.delay,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;
  final double elevation;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool animated;
  final Duration? duration;
  final Duration? delay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: elevation,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: elevation * 0.5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: brightness == Brightness.light
                  ? Colors.white.withValues(alpha: opacity)
                  : scheme.surface.withValues(alpha: opacity + 0.1),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color:
                    borderColor ??
                    scheme.outlineVariant.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    if (animated) {
      card = card
          .animate()
          .fadeIn(
            duration: duration ?? const Duration(milliseconds: 500),
            delay: delay ?? Duration.zero,
          )
          .slideY(
            begin: 0.15,
            end: 0,
            duration: duration ?? const Duration(milliseconds: 500),
            delay: delay ?? Duration.zero,
            curve: Curves.easeOut,
          );
    }

    return card;
  }
}

/// A 3D-styled action button with depth and glow.
class DepthButton extends StatefulWidget {
  const DepthButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.isLoading = false,
    this.height = 52,
    this.borderRadius = 16,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isLoading;
  final double height;
  final double borderRadius;

  @override
  State<DepthButton> createState() => _DepthButtonState();
}

class _DepthButtonState extends State<DepthButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = widget.color ?? scheme.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        height: widget.height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: _pressed ? 0.15 : 0.35),
              blurRadius: _pressed ? 6 : 18,
              offset: Offset(0, _pressed ? 2 : 6),
            ),
          ],
        ),
        transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
        alignment: Alignment.center,
        child: widget.isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: scheme.onPrimary, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// A floating 3D avatar with ring glow.
class Avatar3D extends StatelessWidget {
  const Avatar3D({
    super.key,
    this.name,
    this.size = 48,
    this.color,
    this.ringColor,
  });

  final String? name;
  final double size;
  final Color? color;
  final Color? ringColor;

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.primary;
    final ring = ringColor ?? scheme.secondary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg, bg.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: ring.withValues(alpha: 0.6), width: 2.5),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: scheme.onPrimary,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
