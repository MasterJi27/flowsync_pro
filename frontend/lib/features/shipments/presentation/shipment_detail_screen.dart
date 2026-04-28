import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/section_panel.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/shipment_models.dart';
import 'shipment_controllers.dart';

class ShipmentDetailScreen extends ConsumerWidget {
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(shipmentDetailControllerProvider(shipmentId));
    final role = ref.watch(authControllerProvider).activeRole ?? 'CLIENT';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipment Detail'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref
                .read(shipmentDetailControllerProvider(shipmentId).notifier)
                .load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 34),
                  const SizedBox(height: 8),
                  Text(error.toString(), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          data: (bundle) {
            final shipment = bundle.shipment;
            final content = [
              _ShipmentHeader(shipment: shipment),
              _TimelinePanel(shipment: shipment),
              _ParticipantsPanel(participants: shipment.participants),
              _ActionPanel(shipment: shipment, role: role),
              _ContactsPanel(contacts: shipment.contacts),
              _EscalationPanel(attempts: bundle.escalations),
              _AuditPanel(logs: bundle.logs),
            ];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (var i = 0; i < content.length; i++) ...[
                  content[i],
                  if (i != content.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShipmentHeader extends StatelessWidget {
  const _ShipmentHeader({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.08),
            ],
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    shipment.referenceNumber,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                StatusBadge(shipment.currentStatus),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${shipment.origin} -> ${shipment.destination}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _HeaderChip(
                  icon: Icons.flight_takeoff_rounded,
                  label: shipment.transportType,
                ),
                _HeaderChip(
                  icon: Icons.priority_high_rounded,
                  label: shipment.priorityLevel,
                ),
                _HeaderChip(
                  icon: Icons.schedule_rounded,
                  label: 'ETA ${fmtDate(shipment.eta)}',
                ),
                if (shipment.currentStep != null)
                  _HeaderChip(
                    icon: Icons.flag_rounded,
                    label: shipment.currentStep!.stepName,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(titleCase(label)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Live Timeline',
      child: Column(
        children: [
          for (final step in shipment.steps)
            _TimelineStep(
              step: step,
              isCurrent: step.id == shipment.currentStepId,
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step, required this.isCurrent});

  final ShipmentStep step;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = step.status == 'COMPLETED'
        ? const Color(0xFF15803D)
        : step.status == 'NEEDS_CONFIRMATION' || step.status == 'ESCALATED'
        ? const Color(0xFFB45309)
        : scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: activeColor,
                child: Icon(
                  step.status == 'COMPLETED'
                      ? Icons.check_rounded
                      : Icons.circle_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              Container(width: 2, height: 58, color: scheme.outlineVariant),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isCurrent
                    ? scheme.primaryContainer.withValues(alpha: 0.32)
                    : scheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.stepName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        StatusBadge(step.status, compact: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text('Expected ${fmtDate(step.expectedTime)}'),
                        Text('Actual ${fmtDate(step.actualTime)}'),
                        Text('Source ${titleCase(step.updateSource)}'),
                        if (step.updatedByName != null)
                          Text('By ${step.updatedByName}'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: step.confidenceScore / 100,
                            minHeight: 7,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${step.confidenceScore}%'),
                        if (step.escalationStatus != 'NONE') ...[
                          const SizedBox(width: 8),
                          StatusBadge(step.escalationStatus, compact: true),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantsPanel extends StatelessWidget {
  const _ParticipantsPanel({required this.participants});

  final List<ShipmentParticipant> participants;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Participants',
      child: Column(
        children: [
          for (final participant in participants) ...[
            Row(
              children: [
                CircleAvatar(child: Text(participant.role.substring(0, 1))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participant.name ?? 'External participant',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${titleCase(participant.role)} · ${titleCase(participant.inviteStatus)}',
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: participant.reliabilityScore / 100,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text('${participant.reliabilityScore.round()}%'),
              ],
            ),
            const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _ActionPanel extends ConsumerWidget {
  const _ActionPanel({required this.shipment, required this.role});

  final Shipment shipment;
  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      shipmentDetailControllerProvider(shipment.id).notifier,
    );
    final actionable =
        shipment.currentStep ??
        shipment.steps.where((step) => step.status != 'COMPLETED').firstOrNull;
    final canConfirm =
        role == 'BROKER' || role == 'TRANSPORTER' || role == 'AUTHORITY';
    final canEscalate =
        role == 'BROKER' &&
        actionable != null &&
        actionable.status != 'COMPLETED';

    return SectionPanel(
      title: 'Action Panel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: canConfirm && actionable != null
                ? () async {
                    try {
                      await controller.confirmStep(
                        actionable,
                        notes:
                            '${titleCase(role)} confirmation from Android app',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Step confirmation sent'),
                          ),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saved offline and queued for retry'),
                          ),
                        );
                      }
                    }
                  }
                : null,
            icon: const Icon(Icons.task_alt_rounded),
            label: const Text('Confirm Step'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: canEscalate
                ? () => controller.triggerEscalation(actionable)
                : null,
            icon: const Icon(Icons.notification_important_rounded),
            label: const Text('Escalate'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: role == 'BROKER'
                ? () => _inviteDialog(context, controller)
                : null,
            icon: const Icon(Icons.person_add_alt_rounded),
            label: const Text('Invite Transporter'),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteDialog(
    BuildContext context,
    ShipmentDetailController controller,
  ) async {
    final phone = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Transporter'),
        content: TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, phone.text.trim()),
            child: const Text('Invite'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    final token = await controller.inviteTransporter(result);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invite token: $token')));
    }
  }
}

class _ContactsPanel extends StatelessWidget {
  const _ContactsPanel({required this.contacts});

  final List<ShipmentContact> contacts;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Contacts',
      child: contacts.isEmpty
          ? const Text('No escalation contacts')
          : Column(
              children: [
                for (final contact in contacts)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${contact.priority}')),
                    title: Text(contact.name),
                    subtitle: Text(
                      'Trust ${contact.trustScore.round()}% · Avg ${contact.responseTimeAvg} min',
                    ),
                    trailing: Text('#${contact.escalationOrder}'),
                  ),
              ],
            ),
    );
  }
}

class _EscalationPanel extends StatelessWidget {
  const _EscalationPanel({required this.attempts});

  final List<EscalationAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Escalations',
      child: attempts.isEmpty
          ? const Text('No active escalation attempts')
          : Column(
              children: [
                for (final attempt in attempts.take(5))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_active_rounded),
                    title: Text(attempt.contactName ?? 'Escalation target'),
                    subtitle: Text(
                      'Sequence ${attempt.sequenceRank} · ${fmtDate(attempt.notifiedAt)}',
                    ),
                    trailing: StatusBadge(attempt.status, compact: true),
                  ),
              ],
            ),
    );
  }
}

class _AuditPanel extends StatelessWidget {
  const _AuditPanel({required this.logs});

  final List<ShipmentLog> logs;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Immutable Audit Trail',
      child: logs.isEmpty
          ? const Text('Audit trail unavailable while offline')
          : Column(
              children: [
                for (final log in logs.take(10))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      log.isFirstConfirmation
                          ? Icons.verified_rounded
                          : Icons.history_rounded,
                    ),
                    title: Text(titleCase(log.action)),
                    subtitle: Text(
                      [
                        if (log.performerName != null) log.performerName!,
                        fmtDate(log.timestamp),
                        if (log.notes != null) log.notes!,
                      ].join(' · '),
                    ),
                    trailing: Text('${log.confidenceScore}%'),
                  ),
              ],
            ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
