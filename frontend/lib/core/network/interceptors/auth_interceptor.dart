import 'package:dio/dio.dart';
import '../../utils/storage_helper.dart';
import '../api_endpoints.dart';
import '../../config/app_config.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;

  AuthInterceptor(this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await StorageHelper.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final requestOptions = err.requestOptions;
      
      // Prevent infinite loops if refreshing token fails
      if (requestOptions.path == ApiEndpoints.refreshToken) {
        await StorageHelper.clearTokens();
        return super.onError(err, handler);
      }

      final refreshToken = await StorageHelper.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Perform silent token refresh
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: AppConfig.instance.baseUrl,
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
            ),
          );
          
          final response = await refreshDio.post(
            ApiEndpoints.refreshToken,
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final newAccessToken = response.data['access_token'];
            final newRefreshToken = response.data['refresh_token'];
            
            if (newAccessToken != null) {
              await StorageHelper.saveAccessToken(newAccessToken);
            }
            if (newRefreshToken != null) {
              await StorageHelper.saveRefreshToken(newRefreshToken);
            }

            // Retry request
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final clonedRequest = await _dio.request(
              requestOptions.path,
              options: Options(
                method: requestOptions.method,
                headers: requestOptions.headers,
              ),
              data: requestOptions.data,
              queryParameters: requestOptions.queryParameters,
            );
            return handler.resolve(clonedRequest);
          }
        } catch (e) {
          // Refresh failed, logout/clear tokens
          await StorageHelper.clearTokens();
        }
      }
    }
    super.onError(err, handler);
  }
}
