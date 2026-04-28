import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/animated_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../shipments/presentation/shipment_controllers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final role = auth.activeRole ?? auth.user?.globalRole ?? 'CLIENT';
    final shipments = ref.watch(shipmentListControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: ParticleBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              floating: true,
              backgroundColor: scheme.surface.withValues(alpha: 0.85),
              surfaceTintColor: Colors.transparent,
              leading: context.canPop()
                  ? IconButton(
                      tooltip: 'Back',
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  _roleTitle(role),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary.withValues(alpha: 0.15),
                        scheme.secondary.withValues(alpha: 0.08),
                        scheme.surface.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 390;
                          final header = compact
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Avatar3D(
                                          name: auth.user?.name ?? 'User',
                                          size: 48,
                                          color: _roleColor(scheme, role),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Welcome back,',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                auth.user?.name ?? 'User',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _RoleBadge(role: role, compact: true),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Avatar3D(
                                      name: auth.user?.name ?? 'User',
                                      size: 48,
                                      color: _roleColor(scheme, role),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome back,',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: scheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            auth.user?.name ?? 'User',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    _RoleBadge(role: role),
                                  ],
                                );

                          return header;
                        },
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  tooltip: 'More',
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    switch (value) {
                      case 'analytics':
                        if (role == 'BROKER') {
                          context.push('/analytics');
                        }
                        break;
                      case 'profile':
                        context.push('/profile');
                        break;
                      case 'refresh':
                        ref
                            .read(shipmentListControllerProvider.notifier)
                            .load();
                        break;
                      case 'logout':
                        HapticFeedback.mediumImpact();
                        ref.read(authControllerProvider.notifier).logout();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (role == 'BROKER')
                      const PopupMenuItem(
                        value: 'analytics',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.insights_rounded),
                          title: Text('Analytics'),
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'profile',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.person_outline_rounded),
                        title: Text('Profile'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.refresh_rounded),
                        title: Text('Refresh'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.logout_rounded),
                        title: Text('Sign out'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _QuickActions(role: role, ref: ref),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: shipments.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: _RetryPanel(
                    message: error.toString(),
                    onRetry: () => ref
                        .read(shipmentListControllerProvider.notifier)
                        .load(),
                  ),
                ),
                data: (items) => SliverToBoxAdapter(
                  child: _MetricsGrid(role: role, shipments: items),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent Shipments',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text('View All')),
                  ],
                ),
              ),
            ),
            shipments.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('No shipments match the current view'),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ShipmentCard(
                      shipment: items[index],
                      onTap: () =>
                          context.push('/shipments/${items[index].id}'),
                      delay: Duration(milliseconds: index * 80),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _roleTitle(String role) {
    return switch (role) {
      'BROKER' => 'Broker Control Tower',
      'CLIENT' => 'Client Visibility',
      'TRANSPORTER' => 'Transporter Desk',
      'AUTHORITY' => 'Authority Queue',
      _ => 'Dashboard',
    };
  }

  Color _roleColor(ColorScheme scheme, String role) {
    return switch (role) {
      'BROKER' => scheme.primary,
      'CLIENT' => scheme.secondary,
      'TRANSPORTER' => scheme.tertiary,
      'AUTHORITY' => scheme.error,
      _ => scheme.primary,
    };
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, this.compact = false});

  final String role;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (role) {
      'BROKER' => scheme.primary,
      'CLIENT' => scheme.secondary,
      'TRANSPORTER' => scheme.tertiary,
      'AUTHORITY' => scheme.error,
      _ => scheme.primary,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.role, required this.ref});

  final String role;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final actions = [
      if (role == 'BROKER')
        _ActionItem(
          icon: Icons.add_rounded,
          label: 'New Shipment',
          color: scheme.primary,
          onTap: () {},
        ),
      _ActionItem(
        icon: Icons.search_rounded,
        label: 'Search',
        color: scheme.secondary,
        onTap: () => _openSearch(context),
      ),
      _ActionItem(
        icon: Icons.filter_list_rounded,
        label: 'Filter',
        color: scheme.tertiary,
        onTap: () => _openFilter(context),
      ),
      _ActionItem(
        icon: Icons.people_outline_rounded,
        label: 'Team',
        color: scheme.error,
        onTap: () => context.push('/profile'),
      ),
    ];

    if (actions.length <= 3) {
      return Row(
        children: actions
            .map(
              (a) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ActionChip(action: a),
                ),
              ),
            )
            .toList(),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions
          .map(
            (a) => SizedBox(
              width: (MediaQuery.of(context).size.width - 56) / 2,
              child: _ActionChip(action: a),
            ),
          )
          .toList(),
    );
  }

  Future<void> _openSearch(BuildContext context) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Search shipments',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  ref
                      .read(shipmentListControllerProvider.notifier)
                      .search(value);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
  }

  Future<void> _openFilter(BuildContext context) async {
    const statuses = <String?>[
      null,
      'PLANNED',
      'IN_TRANSIT',
      'NEEDS_CONFIRMATION',
      'ESCALATED',
      'DELAYED',
      'COMPLETED',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter shipments',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...statuses.map(
                (status) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () {
                      ref
                          .read(shipmentListControllerProvider.notifier)
                          .filterStatus(status);
                      Navigator.of(context).pop();
                    },
                    child: Text(status ?? 'All statuses'),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FilledButton.tonal(
                onPressed: () {
                  ref
                      .read(shipmentListControllerProvider.notifier)
                      .filterStatus(null);
                  Navigator.of(context).pop();
                },
                child: const Text('Clear filter'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _ActionChip extends StatefulWidget {
  const _ActionChip({required this.action});

  final _ActionItem action;

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.action.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: widget.action.color.withValues(alpha: _pressed ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.action.color.withValues(alpha: _pressed ? 0.4 : 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.action.color.withValues(
                alpha: _pressed ? 0.08 : 0.16,
              ),
              blurRadius: _pressed ? 8 : 18,
              offset: Offset(0, _pressed ? 2 : 6),
            ),
          ],
        ),
        transform: Matrix4.identity()..scale(_pressed ? 0.96 : 1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.action.icon, size: 22, color: widget.action.color),
            const SizedBox(height: 6),
            Text(
              widget.action.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.action.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap to open',
              style: TextStyle(
                fontSize: 9,
                color: widget.action.color.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.role, required this.shipments});

  final String role;
  final List shipments;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = shipments.length;
    final active =
        shipments.where((s) => s.currentStatus == 'IN_TRANSIT').length;
    final pending =
        shipments.where((s) => s.currentStatus == 'NEEDS_CONFIRMATION').length;
    final completed =
        shipments.where((s) => s.currentStatus == 'COMPLETED').length;

    final metrics = [
      _Metric(
        label: 'Total',
        value: total.toString(),
        icon: Icons.inventory_2_outlined,
        color: scheme.primary,
      ),
      _Metric(
        label: 'Active',
        value: active.toString(),
        icon: Icons.local_shipping_outlined,
        color: scheme.tertiary,
      ),
      _Metric(
        label: 'Pending',
        value: pending.toString(),
        icon: Icons.pending_actions_outlined,
        color: scheme.secondary,
      ),
      _Metric(
        label: 'Done',
        value: completed.toString(),
        icon: Icons.check_circle_outline,
        color: scheme.primary,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: metrics
          .map(
            (m) => GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: m.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(m.icon, size: 16, color: m.color),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.trending_up_rounded,
                        size: 14,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    m.value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({
    required this.shipment,
    required this.onTap,
    this.delay,
  });

  final dynamic shipment;
  final VoidCallback onTap;
  final Duration? delay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = shipment.currentStatus ?? 'UNKNOWN';
    final statusColor = _statusColor(scheme, status);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      onTap: onTap,
      delay: delay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '#${shipment.referenceNumber ?? shipment.id.substring(0, 6)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LocationLabel(
                  icon: Icons.trip_origin_rounded,
                  label: shipment.origin ?? 'Origin',
                  color: scheme.primary,
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              Expanded(
                child: _LocationLabel(
                  icon: Icons.location_on_rounded,
                  label: shipment.destination ?? 'Destination',
                  color: scheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _progressValue(status),
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(statusColor),
            borderRadius: BorderRadius.circular(4),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Color _statusColor(ColorScheme scheme, String? status) {
    return switch (status) {
      'IN_TRANSIT' => scheme.tertiary,
      'COMPLETED' => scheme.primary,
      'NEEDS_CONFIRMATION' => scheme.secondary,
      'ESCALATED' => scheme.error,
      'DELAYED' => scheme.error,
      _ => scheme.onSurfaceVariant,
    };
  }

  double _progressValue(String? status) {
    return switch (status) {
      'PLANNED' => 0.1,
      'IN_TRANSIT' => 0.5,
      'NEEDS_CONFIRMATION' => 0.75,
      'COMPLETED' => 1.0,
      _ => 0.3,
    };
  }
}

class _LocationLabel extends StatelessWidget {
  const _LocationLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RetryPanel extends StatelessWidget {
  const _RetryPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: scheme.error),
          const SizedBox(height: 12),
          Text(
            'Something went wrong',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          DepthButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
