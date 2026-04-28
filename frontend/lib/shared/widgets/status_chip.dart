import 'package:flutter/material.dart';

/// Status chip with color coding (green/yellow/red)
class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipColor color;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isAnimated;

  const StatusChip({
    super.key,
    required this.label,
    this.color = StatusChipColor.neutral,
    this.icon,
    this.onTap,
    this.isAnimated = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorData = _getColorData(color);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            isAnimated ? const Duration(milliseconds: 300) : Duration.zero,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorData.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorData.borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: colorData.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: colorData.textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: colorData.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ColorData _getColorData(StatusChipColor color) {
    switch (color) {
      case StatusChipColor.success:
        return _ColorData(
          backgroundColor: const Color(0xFFD4EDDA),
          borderColor: const Color(0xFF6DD5B2),
          textColor: const Color(0xFF155724),
          shadowColor: const Color(0xFF6DD5B2).withOpacity(0.2),
        );
      case StatusChipColor.warning:
        return _ColorData(
          backgroundColor: const Color(0xFFFFF3CD),
          borderColor: const Color(0xFFFFB366),
          textColor: const Color(0xFF856404),
          shadowColor: const Color(0xFFFFB366).withOpacity(0.2),
        );
      case StatusChipColor.danger:
        return _ColorData(
          backgroundColor: const Color(0xFFF8D7DA),
          borderColor: const Color(0xFFFF6B6B),
          textColor: const Color(0xFF721C24),
          shadowColor: const Color(0xFFFF6B6B).withOpacity(0.2),
        );
      case StatusChipColor.info:
        return _ColorData(
          backgroundColor: const Color(0xFFD1ECF1),
          borderColor: const Color(0xFF87CEEB),
          textColor: const Color(0xFF0C5460),
          shadowColor: const Color(0xFF87CEEB).withOpacity(0.2),
        );
      case StatusChipColor.neutral:
        return _ColorData(
          backgroundColor: const Color(0xFFE9ECEF),
          borderColor: const Color(0xFFBEC3CB),
          textColor: const Color(0xFF495057),
          shadowColor: const Color(0xFF495057).withOpacity(0.1),
        );
    }
  }
}

class _ColorData {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color shadowColor;

  _ColorData({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.shadowColor,
  });
}

enum StatusChipColor {
  success,
  warning,
  danger,
  info,
  neutral,
}

/// Helper to get StatusChipColor from shipment status
StatusChipColor getStatusChipColor(String? status) {
  switch (status?.toUpperCase()) {
    case 'COMPLETED':
    case 'IN_TRANSIT':
    case 'ON_TIME':
      return StatusChipColor.success;
    case 'NEEDS_CONFIRMATION':
    case 'PENDING':
    case 'ASSIGNED':
      return StatusChipColor.warning;
    case 'DELAYED':
    case 'ESCALATED':
    case 'BLOCKED':
      return StatusChipColor.danger;
    case 'PLANNED':
      return StatusChipColor.info;
    default:
      return StatusChipColor.neutral;
  }
}

/// Helper to get icon for status
IconData? getStatusIcon(String? status) {
  switch (status?.toUpperCase()) {
    case 'COMPLETED':
      return Icons.check_circle;
    case 'IN_TRANSIT':
      return Icons.local_shipping;
    case 'DELAYED':
      return Icons.warning_amber;
    case 'ESCALATED':
      return Icons.priority_high;
    case 'PENDING':
      return Icons.hourglass_empty;
    default:
      return null;
  }
}
