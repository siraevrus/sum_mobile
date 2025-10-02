import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/constants/app_constants.dart';
import 'package:sum_warehouse/core/error/error_handler.dart';
import 'package:sum_warehouse/features/auth/data/datasources/auth_local_datasource.dart';

part 'dio_client.g.dart';

@riverpod
Dio dioClient(DioClientRef ref) {
  final dio = Dio();
  
  dio.options.baseUrl = AppConstants.baseUrl;
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  dio.options.headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Interceptors
  dio.interceptors.addAll([
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
    ),
    AuthInterceptor(ref),
    ErrorHandlerInterceptor(),
  ]);
  
  return dio;
}

  /// Interceptor для автоматического добавления токена авторизации
class AuthInterceptor extends Interceptor {
  final DioClientRef ref;
  
  AuthInterceptor(this.ref);
  
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Добавляем токен только если это не запрос на логин/регистрацию
    if (!options.path.contains('/auth/login') && 
        !options.path.contains('/auth/register')) {
      try {
        final localDataSource = await ref.read(authLocalDataSourceProvider.future);
        final token = await localDataSource.getToken();
        
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        // Игнорируем ошибки получения токена для не-авторизованных запросов
      }
    }
    
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Обрабатываем ошибки авторизации
    if (err.response?.statusCode == 401) {
      // Токен истек или невалиден - очищаем локальные данные
      _clearAuthData();
    }
    
    super.onError(err, handler);
  }
  
  /// Очистка данных аутентификации при ошибке 401
  Future<void> _clearAuthData() async {
    try {
      final localDataSource = await ref.read(authLocalDataSourceProvider.future);
      await localDataSource.removeToken();
      await localDataSource.removeUserData();
    } catch (e) {
      // Игнорируем ошибки очистки
    }
  }
}

/// Interceptor для обработки сетевых ошибок
class ErrorHandlerInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Логируем ошибку для отладки
    print('🔴 Network Error: ${err.type} - ${err.message}');
    
    // Преобразуем DioException в AppException через ErrorHandler
    final appException = ErrorHandler.handleError(err);
    
    // Создаем новую DioException с понятным сообщением
    final newError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: appException,
      message: appException.message,
    );
    
    handler.next(newError);
  }
}
