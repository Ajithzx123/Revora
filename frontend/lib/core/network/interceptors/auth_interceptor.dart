import 'package:dio/dio.dart';
import '../../supabase/supabase_service.dart';

/// Sends the current Supabase access token with every API call. Supabase refreshes
/// tokens itself; on a 401 we ask it for a fresh session once and retry.
class AuthInterceptor extends Interceptor {
  final Dio _dio;

  AuthInterceptor(this._dio);

  static const _retriedKey = 'auth_retried';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token =
        SupabaseService.instance.client?.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final client = SupabaseService.instance.client;
    if (err.response?.statusCode == 401 &&
        client != null &&
        request.extra[_retriedKey] != true) {
      try {
        final refreshed = await client.auth.refreshSession();
        final token = refreshed.session?.accessToken;
        if (token != null) {
          request.extra[_retriedKey] = true;
          request.headers['Authorization'] = 'Bearer $token';
          final response = await _dio.fetch(request);
          return handler.resolve(response);
        }
      } catch (_) {
        // fall through: the caller sees the original 401 and the app signs out
      }
    }
    handler.next(err);
  }
}
