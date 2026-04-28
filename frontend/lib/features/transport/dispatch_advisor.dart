import 'package:flutter/material.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/status_chip.dart';

/// Dispatch advisor card - shows recommendations for dispatch timing
class DispatchAdvisorCard extends StatelessWidget {
  final String? message;
  final String? riskLevel;
  final String? currentStepName;
  final bool? isConfirmed;
  final bool? needsConfirmation;
  final int? recommendedDelayMinutes;
  final VoidCallback? onConfirmStep;

  const DispatchAdvisorCard({
    Key? key,
    this.message,
    this.riskLevel = 'medium',
    this.currentStepName,
    this.isConfirmed = false,
    this.needsConfirmation = false,
    this.recommendedDelayMinutes,
    this.onConfirmStep,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shouldShowWarning = needsConfirmation ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return shouldShowWarning
        ? GradientCardRed(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildContent(context, true),
          )
        : GradientCardWarm(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildContent(context, false),
          );
  }

  Widget _buildContent(BuildContext context, bool isWarning) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.lightbulb,
              color: isWarning ? const Color(0xFFFF6B6B) : const Color(0xFFFFB366),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isWarning ? '⚠️ Dispatch Caution' : '💡 Dispatch Recommendation',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Current step info
        if (currentStepName != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14),
                const SizedBox(width: 8),
                Text(
                  'Current: $currentStepName',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Message
        if (message != null) ...[
          Text(
            message!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Status indicators
        Row(
          children: [
            if (riskLevel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRiskColor(riskLevel!).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getRiskColor(riskLevel!),
                  ),
                ),
                child: Text(
                  'Risk: ${riskLevel!.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getRiskColor(riskLevel!),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (recommendedDelayMinutes != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF87CEEB).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF87CEEB),
                  ),
                ),
                child: Text(
                  'Wait: ${recommendedDelayMinutes}m',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0C5460),
                  ),
                ),
              ),
          ],
        ),

        // Confirmation button if needed
        if (needsConfirmation == true && onConfirmStep != null) ...[
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onConfirmStep,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6DD5B2).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6DD5B2),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Confirm Step to Proceed',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return const Color(0xFF6DD5B2);
      case 'high':
        return const Color(0xFFFF6B6B);
      case 'medium':
      default:
        return const Color(0xFFFFB366);
    }
  }
}

/// Card to show if step doesn't need confirmation (all good)
class DispatchReadyCard extends StatelessWidget {
  final String message;
  final VoidCallback? onDispatch;

  const DispatchReadyCard({
    Key? key,
    this.message = '✅ Safe to dispatch - step confirmed',
    this.onDispatch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GradientCardGreen(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6DD5B2).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF6DD5B2),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (onDispatch != null) ...[
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDispatch,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6DD5B2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Dispatch Now',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
