import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'analytics_models.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(dioProvider));
});

final delayAnalyticsProvider = FutureProvider.autoDispose<DelayAnalytics>((ref) async {
  return ref.watch(analyticsRepositoryProvider).delays();
});

final performanceAnalyticsProvider = FutureProvider.autoDispose<PerformanceAnalytics>((ref) async {
  return ref.watch(analyticsRepositoryProvider).performance();
});

final reliabilityAnalyticsProvider = FutureProvider.autoDispose<ReliabilityAnalytics>((ref) async {
  return ref.watch(analyticsRepositoryProvider).reliability();
});

class AnalyticsRepository {
  const AnalyticsRepository(this._dio);

  final Dio _dio;

  Future<DelayAnalytics> delays() async {
    final response = await _dio.get<Map<String, dynamic>>('/analytics/delays');
    return DelayAnalytics.fromJson(response.data!);
  }

  Future<PerformanceAnalytics> performance() async {
    final response = await _dio.get<Map<String, dynamic>>('/analytics/performance');
    return PerformanceAnalytics.fromJson(response.data!);
  }

  Future<ReliabilityAnalytics> reliability() async {
    final response = await _dio.get<Map<String, dynamic>>('/analytics/reliability');
    return ReliabilityAnalytics.fromJson(response.data!);
  }
}
