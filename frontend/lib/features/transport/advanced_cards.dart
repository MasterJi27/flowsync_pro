import 'package:flutter/material.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/gradient_button.dart';

/// Risk card - shows no update for X minutes and risk level
class RiskCard extends StatelessWidget {
  final int delayMinutes;
  final String riskColor; // 'red', 'yellow', 'green'
  final String? message;
  final VoidCallback? onAction;

  const RiskCard({
    Key? key,
    required this.delayMinutes,
    this.riskColor = 'yellow',
    this.message,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isHigh = riskColor == 'red';
    final isMedium = riskColor == 'yellow';

    return GradientCardRed(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHigh ? Icons.error_outline : Icons.warning_amber,
                color: isHigh ? const Color(0xFFFF6B6B) : const Color(0xFFFFB366),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ No Update Alert',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No update for $delayMinutes minutes',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Risk Level:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRiskBgColor(riskColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    riskColor.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _getRiskTextColor(riskColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
          if (onAction != null) ...[
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Send Update Request',
              icon: Icons.send,
              onPressed: onAction!,
              height: 40,
            ),
          ],
        ],
      ),
    );
  }

  Color _getRiskBgColor(String color) {
    switch (color) {
      case 'red':
        return const Color(0xFFFF6B6B).withOpacity(0.2);
      case 'yellow':
        return const Color(0xFFFFB366).withOpacity(0.2);
      case 'green':
        return const Color(0xFF6DD5B2).withOpacity(0.2);
      default:
        return const Color(0xFF87CEEB).withOpacity(0.2);
    }
  }

  Color _getRiskTextColor(String color) {
    switch (color) {
      case 'red':
        return const Color(0xFFCC5555);
      case 'yellow':
        return const Color(0xFFCC8833);
      case 'green':
        return const Color(0xFF228844);
      default:
        return const Color(0xFF0066BB);
    }
  }
}

/// Impact card - shows estimated delay and potential cost impact
class ImpactCard extends StatelessWidget {
  final int estimatedDelayHours;
  final int potentialCostImpact;
  final String currencySymbol;

  const ImpactCard({
    Key? key,
    required this.estimatedDelayHours,
    required this.potentialCostImpact,
    this.currencySymbol = '₹',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientCardWarm(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB366).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_down,
                  color: Color(0xFFFFB366),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: const Text(
                  '📊 Impact Assessment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Delay impact
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Delay',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 18, color: Color(0xFFFFB366)),
                    const SizedBox(width: 8),
                    Text(
                      '+$estimatedDelayHours hours',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Cost impact
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Potential Cost Impact',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 18, color: Color(0xFFFF6B6B)),
                    const SizedBox(width: 8),
                    Text(
                      '$currencySymbol$potentialCostImpact',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Info text
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF87CEEB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF87CEEB).withOpacity(0.5),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Color(0xFF0C5460)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Timely dispatch can help recover this impact',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF0C5460),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Best contact card - shows who to reach out to
class BestContactCard extends StatelessWidget {
  final String contactName;
  final String? phone;
  final String? role;
  final String trustLevel; // 'high', 'medium', 'low'
  final int? avgResponseTimeSeconds;
  final VoidCallback? onCallContact;

  const BestContactCard({
    Key? key,
    required this.contactName,
    this.phone,
    this.role,
    this.trustLevel = 'medium',
    this.avgResponseTimeSeconds,
    this.onCallContact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientCardBlue(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_pin,
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
                      '👤 Best Contact',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contactName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Trust level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _getTrustBgColor(trustLevel),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trust Level',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trustLevel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Contact info
          if (role != null || phone != null) ...[
            Row(
              children: [
                if (role != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Role',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          role!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (avgResponseTimeSeconds != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Avg Response',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(avgResponseTimeSeconds! / 60).toStringAsFixed(0)} min',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Call button
          if (onCallContact != null)
            GradientButton(
              label: 'Call Now',
              icon: Icons.phone,
              onPressed: onCallContact!,
              width: double.infinity,
            ),
        ],
      ),
    );
  }

  Color _getTrustBgColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return const Color(0xFF6DD5B2);
      case 'low':
        return const Color(0xFFFF6B6B);
      case 'medium':
      default:
        return const Color(0xFFFFB366);
    }
  }
}
