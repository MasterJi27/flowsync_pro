import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/local_store.dart';

final dioProvider = Provider<Dio>((ref) {
  final store = ref.watch(localStoreProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 25),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = store.token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Transform connection errors into user-friendly messages
        if (_isConnectionError(error)) {
          error = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error:
                'Cannot connect to server. Please make sure the backend is running at ${AppConfig.apiBaseUrl}',
          );
        }

        final shouldRetry = _isRetryable(error) &&
            error.requestOptions.extra['retried'] != true;
        if (!shouldRetry) {
          handler.next(error);
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 700));
        error.requestOptions.extra['retried'] = true;
        try {
          handler.resolve(await dio.fetch(error.requestOptions));
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
      },
    ),
  );

  return dio;
});

bool _isConnectionError(DioException error) {
  return error.type == DioExceptionType.connectionError ||
      (error.type == DioExceptionType.unknown &&
          error.error != null &&
          error.error.toString().contains('Connection refused'));
}

bool _isRetryable(DioException error) {
  return error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.unknown;
}
