import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status, Theme.of(context).colorScheme);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.11)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 11,
          vertical: compact ? 4 : 6,
        ),
        child: Text(
          titleCase(status),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  Color _colorFor(String status, ColorScheme scheme) {
    switch (status) {
      case 'COMPLETED':
      case 'JOINED':
        return const Color(0xFF15803D);
      case 'IN_TRANSIT':
      case 'IN_PROGRESS':
      case 'NOTIFIED':
        return const Color(0xFF0369A1);
      case 'NEEDS_CONFIRMATION':
      case 'ESCALATED':
      case 'BLOCKED':
      case 'DELAYED':
        return const Color(0xFFB45309);
      case 'CANCELLED':
      case 'EXPIRED':
      case 'REVOKED':
        return scheme.error;
      default:
        return scheme.primary;
    }
  }
}
