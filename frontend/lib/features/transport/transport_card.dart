import 'package:flutter/material.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/gradient_button.dart';

/// Transport status card showing driver and vehicle info
class TransportCard extends StatelessWidget {
  final String? driverName;
  final String? driverPhone;
  final String? truckId;
  final String? status;
  final String? recommendedDispatchTime;
  final String? riskLevel;
  final VoidCallback? onCallDriver;
  final VoidCallback? onDelayDispatch;

  const TransportCard({
    super.key,
    this.driverName,
    this.driverPhone,
    this.truckId,
    this.status = 'ASSIGNED',
    this.recommendedDispatchTime,
    this.riskLevel,
    this.onCallDriver,
    this.onDelayDispatch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GradientCardBlue(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with truck icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Color(0xFF4A90E2),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚚 Transport Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (status != null)
                      StatusChip(
                        label: status!.replaceAll('_', ' '),
                        color: getStatusChipColor(status),
                        icon: getStatusIcon(status),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Driver and truck info
          if (driverName != null || driverPhone != null) ...[
            _InfoRow(
              icon: Icons.person,
              label: 'Driver',
              value: driverName ?? 'Unassigned',
              isDark: isDark,
            ),
            const SizedBox(height: 8),
          ],
          if (truckId != null)
            _InfoRow(
              icon: Icons.directions_car,
              label: 'Vehicle',
              value: truckId!,
              isDark: isDark,
            ),
          if (driverPhone != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.phone,
              label: 'Phone',
              value: driverPhone!,
              isDark: isDark,
            ),
          ],

          // Recommended dispatch and risk
          if (recommendedDispatchTime != null || riskLevel != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (recommendedDispatchTime != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recommended Dispatch',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0x000ff666),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recommendedDispatchTime!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (riskLevel != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Risk Level',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0x000ff666),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _RiskBadge(riskLevel: riskLevel!),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Action buttons
          if (onCallDriver != null || onDelayDispatch != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (onCallDriver != null)
                  Expanded(
                    child: GradientButton(
                      label: 'Call Driver',
                      icon: Icons.phone,
                      onPressed: onCallDriver!,
                    ),
                  ),
                if (onDelayDispatch != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Delay Dispatch',
                      icon: Icons.schedule,
                      onPressed: onDelayDispatch!,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4A90E2)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0x000ff666),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final String riskLevel;

  const _RiskBadge({required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = _getRiskColors(riskLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        riskLevel.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  (Color, Color) _getRiskColors(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return (const Color(0xFF155724), const Color(0xFFD4EDDA));
      case 'high':
        return (const Color(0xFF721C24), const Color(0xFFF8D7DA));
      case 'medium':
      default:
        return (const Color(0xFF856404), const Color(0xFFFFF3CD));
    }
  }
}
