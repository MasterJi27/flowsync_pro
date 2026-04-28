import 'package:flutter/material.dart';
import '../../../shared/widgets/app_card.dart';

/// Flow timeline widget - shows shipment progress through steps
/// Replaces plain list with visual timeline and animations
class FlowTimelineWidget extends StatefulWidget {
  final List<StepItem> steps;
  final int? currentStepIndex;
  final VoidCallback? onStepTap;
  final bool isAnimated;

  const FlowTimelineWidget({
    Key? key,
    required this.steps,
    this.currentStepIndex,
    this.onStepTap,
    this.isAnimated = true,
  }) : super(key: key);

  @override
  State<FlowTimelineWidget> createState() => _FlowTimelineWidgetState();
}

class _FlowTimelineWidgetState extends State<FlowTimelineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    if (widget.isAnimated) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    if (widget.isAnimated) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Shipment Flow',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTimelineCompact(),
        const SizedBox(height: 16),
        _buildTimelineDetailed(),
      ],
    );
  }

  /// Compact horizontal timeline (quick overview)
  Widget _buildTimelineCompact() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            ...widget.steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCurrentStep = index == widget.currentStepIndex;
              final isCompleted = widget.currentStepIndex != null && index < widget.currentStepIndex!;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: widget.onStepTap,
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isCurrentStep
                              ? const Color(0xFF6DD5B2)
                              : (isCompleted
                                  ? const Color(0xFF6DD5B2)
                                  : Colors.grey[300]),
                          border: Border.all(
                            color: isCurrentStep
                                ? const Color(0xFF4A90E2)
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: isCurrentStep
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4A90E2).withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            (index + 1).toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isCurrentStep || isCompleted
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 50,
                        child: Text(
                          step.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Detailed vertical timeline
  Widget _buildTimelineDetailed() {
    if (widget.steps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ...widget.steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCurrentStep = index == widget.currentStepIndex;
            final isCompleted = widget.currentStepIndex != null && index < widget.currentStepIndex!;
            final isNext = widget.currentStepIndex != null && index == widget.currentStepIndex! + 1;

            return Column(
              children: [
                // Timeline item
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline dot and line
                    SizedBox(
                      width: 40,
                      height: isCurrentStep ? 100 : 80,
                      child: Column(
                        children: [
                          // Dot
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isCurrentStep
                                  ? const Color(0xFF6DD5B2)
                                  : (isCompleted
                                      ? const Color(0xFF6DD5B2)
                                      : const Color(0xFFE0E0E0)),
                              border: Border.all(
                                color: isCurrentStep
                                    ? const Color(0xFF4A90E2)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: isCurrentStep
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4A90E2).withOpacity(0.3),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Icon(
                                isCompleted
                                    ? Icons.check
                                    : (isCurrentStep ? Icons.circle : Icons.circle_outlined),
                                color: isCurrentStep || isCompleted
                                    ? Colors.white
                                    : Colors.grey,
                                size: 20,
                              ),
                            ),
                          ),

                          // Line to next step
                          if (index < widget.steps.length - 1)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: isCompleted
                                    ? const Color(0xFF6DD5B2)
                                    : const Color(0xFFE0E0E0),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Step card
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: GestureDetector(
                          onTap: widget.onStepTap,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCurrentStep
                                  ? const Color(0xFF6DD5B2).withOpacity(0.15)
                                  : (isCompleted
                                      ? const Color(0xFF6DD5B2).withOpacity(0.08)
                                      : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrentStep
                                    ? const Color(0xFF6DD5B2)
                                    : (isCompleted
                                        ? const Color(0xFF6DD5B2).withOpacity(0.3)
                                        : Colors.transparent),
                                width: isCurrentStep ? 2 : 1,
                              ),
                              boxShadow: isCurrentStep
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF6DD5B2).withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Step name and status
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        step.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isCurrentStep
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    _buildStatusBadge(
                                      isCurrentStep,
                                      isCompleted,
                                      isNext,
                                    ),
                                  ],
                                ),

                                // Expected time
                                if (step.expectedTime != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 12, color: Color(0xFF999)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Expected: ${step.expectedTime}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF999),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                // Actual time
                                if (step.actualTime != null && isCompleted) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.done_all, size: 12, color: Color(0xFF6DD5B2)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Completed: ${step.actualTime}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6DD5B2),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                // Confidence score
                                if (step.confidenceScore != null) ...[
                                  const SizedBox(height: 8),
                                  _buildConfidenceIndicator(step.confidenceScore!),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isCurrentStep, bool isCompleted, bool isNext) {
    if (isCurrentStep) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF6DD5B2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '🔵 Current',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    } else if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF6DD5B2).withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '✅ Done',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF228844),
          ),
        ),
      );
    } else if (isNext) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF4A90E2).withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '⏭️ Next',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0C5460),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '⏳ Pending',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF666),
          ),
        ),
      );
    }
  }

  Widget _buildConfidenceIndicator(int score) {
    final percentage = (score / 100.0).clamp(0.0, 1.0);
    final color = score >= 75
        ? const Color(0xFF6DD5B2)
        : (score >= 50 ? const Color(0xFFFFB366) : const Color(0xFFFF6B6B));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Confidence',
              style: TextStyle(fontSize: 10, color: Color(0xFF999)),
            ),
            Text(
              '$score%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF666),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 4,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Step item model
class StepItem {
  final String name;
  final String? expectedTime;
  final String? actualTime;
  final String status;
  final int? confidenceScore;

  StepItem({
    required this.name,
    this.expectedTime,
    this.actualTime,
    this.status = 'PENDING',
    this.confidenceScore,
  });
}
