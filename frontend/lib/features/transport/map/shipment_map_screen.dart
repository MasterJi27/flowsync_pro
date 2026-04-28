import 'package:flutter/material.dart';
import '../../../shared/widgets/app_card.dart';
import 'location_mapper.dart';

/// Shipment map screen - shows origin, destination, and current step
/// Gracefully falls back to text-based visualization if google_maps unavailable
class ShipmentMapScreen extends StatefulWidget {
  final String shipmentId;
  final String? origin;
  final String? destination;
  final List<String> stepNames;
  final int? currentStepIndex;

  const ShipmentMapScreen({
    Key? key,
    required this.shipmentId,
    this.origin,
    this.destination,
    this.stepNames = const [],
    this.currentStepIndex,
  }) : super(key: key);

  @override
  State<ShipmentMapScreen> createState() => _ShipmentMapScreenState();
}

class _ShipmentMapScreenState extends State<ShipmentMapScreen> {
  late List<LocationCoordinate> route;
  bool _hasGoogleMaps = true;

  @override
  void initState() {
    super.initState();
    _buildRoute();
  }

  void _buildRoute() {
    try {
      route = LocationMapper.createRoute(widget.stepNames);
      if (route.isEmpty) {
        _hasGoogleMaps = false;
      }
    } catch (e) {
      _hasGoogleMaps = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipment Route'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map or placeholder
            _hasGoogleMaps && route.isNotEmpty
                ? _buildMapVisualization()
                : _buildPlaceholderMap(),

            const SizedBox(height: 20),

            // Route timeline
            _buildRouteTimeline(),

            const SizedBox(height: 20),

            // Route details
            _buildRouteDetails(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Map visualization (placeholder - can be replaced with google_maps_flutter)
  Widget _buildMapVisualization() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF87CEEB).withOpacity(0.1),
                  const Color(0xFF4A90E2).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Custom map visualization using markers
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: Color(0xFF4A90E2),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Map Visualization',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${route.length} waypoints',
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
          ),

          // Route markers
          ..._buildMapMarkers(),
        ],
      ),
    );
  }

  List<Widget> _buildMapMarkers() {
    return route.asMap().entries.map((entry) {
      final index = entry.key;
      final coord = entry.value;
      final isCurrentStep = index == widget.currentStepIndex;
      final isStart = index == 0;
      final isEnd = index == route.length - 1;

      // Normalize coordinates to screen position (simplified)
      final double x = 50.0 + (index * 200.0 / (route.length.toDouble() - 1 + 0.1));
      final double y = isCurrentStep ? 100.0 : 120.0;

      return Positioned(
        left: x,
        top: y,
        child: _buildMarker(
          label: coord.label,
          isActive: isCurrentStep,
          isStart: isStart,
          isEnd: isEnd,
        ),
      );
    }).toList();
  }

  Widget _buildMarker({
    required String label,
    required bool isActive,
    required bool isStart,
    required bool isEnd,
  }) {
    return Column(
      children: [
        Container(
          width: isActive ? 40 : 30,
          height: isActive ? 40 : 30,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF6DD5B2)
                : (isStart || isEnd ? const Color(0xFF4A90E2) : const Color(0xFFBBBB)),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isActive ? Icons.location_on : Icons.circle,
              color: Colors.white,
              size: isActive ? 20 : 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6DD5B2) : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Placeholder map
  Widget _buildPlaceholderMap() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            const Text(
              'Map not available',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF999),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Route preview will show below',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFAA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Timeline visualization
  Widget _buildRouteTimeline() {
    if (widget.stepNames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Timeline',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.stepNames.asMap().entries.map((entry) {
            final index = entry.key;
            final stepName = entry.value;
            final isCurrentStep = index == widget.currentStepIndex;
            final isCompleted = widget.currentStepIndex != null && index < widget.currentStepIndex!;
            final isNext = widget.currentStepIndex != null && index == widget.currentStepIndex! + 1;

            return Column(
              children: [
                Row(
                  children: [
                    // Timeline dot
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCurrentStep
                            ? const Color(0xFF6DD5B2)
                            : (isCompleted ? const Color(0xFF6DD5B2) : const Color(0xFFE0E0E0)),
                        border: Border.all(
                          color: isCurrentStep
                              ? const Color(0xFF4A90E2)
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Icon(
                          isCompleted ? Icons.check : Icons.circle,
                          color: isCurrentStep || isCompleted ? Colors.white : Colors.grey,
                          size: isCurrentStep ? 20 : 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Step info
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(12),
                        backgroundColor: isCurrentStep
                            ? const Color(0xFF6DD5B2).withOpacity(0.1)
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stepName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrentStep ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isCurrentStep
                                  ? '🔵 Current Step'
                                  : (isCompleted
                                      ? '✅ Completed'
                                      : (isNext ? '⏭️ Next' : '⏳ Pending')),
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(
                                  isCurrentStep ? 0xFF6DD5B2 : (isCompleted ? 0xFF228844 : 0xFF666),
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Timeline connector
                if (index < widget.stepNames.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      width: 2,
                      height: 20,
                      color: isCompleted ? const Color(0xFF6DD5B2) : const Color(0xFFE0E0E0),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Route details
  Widget _buildRouteDetails() {
    if (route.isEmpty) {
      return const SizedBox.shrink();
    }

    final centerPoint = LocationMapper.getCenterPoint(route);
    var totalDistance = 0.0;
    var totalTime = 0;

    for (int i = 0; i < route.length - 1; i++) {
      final dist = LocationMapper.calculateDistance(route[i], route[i + 1]);
      final time = LocationMapper.estimateTravelTime(route[i], route[i + 1]);
      totalDistance += dist;
      totalTime += time;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DetailItem(
                      icon: Icons.route,
                      label: 'Total Distance',
                      value: '${totalDistance.toStringAsFixed(1)} km',
                    ),
                    _DetailItem(
                      icon: Icons.schedule,
                      label: 'Est. Time',
                      value: '${(totalTime / 60).toStringAsFixed(1)} hrs',
                    ),
                    _DetailItem(
                      icon: Icons.location_on,
                      label: 'Waypoints',
                      value: '${route.length}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF87CEEB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFF0C5460)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Center: ${centerPoint.latitude.toStringAsFixed(4)}°, ${centerPoint.longitude.toStringAsFixed(4)}°',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF0C5460),
                          ),
                        ),
                      ),
                    ],
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

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4A90E2), size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF999)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
