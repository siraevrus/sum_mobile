import 'package:dio/dio.dart';
import 'app_exceptions.dart';

/// Централизованный обработчик ошибок для всех HTTP-запросов
class ErrorHandler {
  /// Обрабатывает любую ошибку и возвращает понятное исключение для пользователя
  static AppException handleError(dynamic error) {
    if (error is AppException) {
      // Если это уже AppException, просто возвращаем его
      return error;
    }
    
    if (error is DioException) {
      return _handleDioError(error);
    }
    
    // Для всех остальных ошибок
    return UnknownException('Произошла неожиданная ошибка: ${error.toString()}');
  }
  
  /// Обрабатывает DioException
  static AppException _handleDioError(DioException error) {
    switch (error.type) {
      // Проблемы с сетью - таймауты
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          'Проблемы с сетью. Проверьте подключение к интернету',
        );
      
      // Проблемы с подключением - нет интернета или сервер недоступен
      case DioExceptionType.connectionError:
        return const NetworkException(
          'Проблемы с сетью. Проверьте подключение к интернету',
        );
      
      // Ошибка при получении ответа от сервера
      case DioExceptionType.badResponse:
        return _handleResponseError(error);
      
      // Запрос был отменен
      case DioExceptionType.cancel:
        return const NetworkException('Запрос был отменен');
      
      // Неизвестная ошибка Dio
      case DioExceptionType.badCertificate:
        return const NetworkException(
          'Проблемы с сетью. Проверьте подключение к интернету',
        );
      
      case DioExceptionType.unknown:
        // Проверяем, не является ли это проблемой с сетью
        if (error.message?.toLowerCase().contains('network') == true ||
            error.message?.toLowerCase().contains('connection') == true ||
            error.message?.toLowerCase().contains('socket') == true) {
          return const NetworkException(
            'Проблемы с сетью. Проверьте подключение к интернету',
          );
        }
        return const NetworkException(
          'Проблемы с сетью. Проверьте подключение к интернету',
        );
    }
  }
  
  /// Обрабатывает ошибки на основе статус-кода ответа
  static AppException _handleResponseError(DioException error) {
    final response = error.response;
    if (response == null) {
      return const NetworkException(
        'Проблемы с сетью. Проверьте подключение к интернету',
      );
    }
    
    final statusCode = response.statusCode;
    final responseData = response.data;
    
    // Получаем сообщение из ответа, если есть
    String message = 'Произошла ошибка на сервере';
    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] ?? message;
    }
    
    switch (statusCode) {
      case 400:
        // Плохой запрос
        return ServerException(message, statusCode);
      
      case 401:
        // Неавторизован
        return AuthException(message.isEmpty ? 'Требуется авторизация' : message);
      
      case 403:
        // Доступ запрещен
        return AuthException(message.isEmpty ? 'Доступ запрещен' : message);
      
      case 404:
        // Ресурс не найден
        return ServerException(
          message.isEmpty ? 'Ресурс не найден' : message,
          statusCode,
        );
      
      case 422:
        // Ошибка валидации
        final Map<String, List<String>> errors = {};
        if (responseData is Map<String, dynamic> && responseData['errors'] != null) {
          final rawErrors = responseData['errors'];
          if (rawErrors is Map) {
            rawErrors.forEach((key, value) {
              if (value is List) {
                errors[key.toString()] = value.map((e) => e.toString()).toList();
              } else if (value != null) {
                errors[key.toString()] = [value.toString()];
              } else {
                errors[key.toString()] = [];
              }
            });
          }
        }
        return ValidationException(
          'Ошибка валидации: $message',
          errors,
        );
      
      case 500:
      case 502:
      case 503:
      case 504:
        // Ошибки сервера
        return ServerException(
          'Ошибка сервера. Попробуйте позже',
          statusCode,
        );
      
      default:
        // Другие ошибки
        return ServerException(message, statusCode);
    }
  }
}

