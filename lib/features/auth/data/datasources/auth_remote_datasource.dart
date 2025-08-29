import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/features/auth/data/models/user_model.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';

part 'auth_remote_datasource.g.dart';

/// Remote data source для аутентификации
abstract class AuthRemoteDataSource {
  /// Вход в систему
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });
  
  /// Выход из системы
  Future<void> logout();
  
  /// Получение текущего пользователя
  Future<UserModel> getCurrentUser();
  
  /// Обновление профиля
  Future<UserModel> updateProfile({
    String? name,
    String? username,
    String? email,
    String? phone,
    String? currentPassword,
    String? newPassword,
  });
}

/// Реализация remote data source
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;
  
  AuthRemoteDataSourceImpl(this._dio);
  
  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 AuthRemoteDataSource: Отправляем запрос логина для $email');
      
      final response = await _dio.post(
        '/auth/login',
        data: LoginRequestModel(
          email: email,
          password: password,
        ).toJson(),
      );
      
      print('🟢 AuthRemoteDataSource: Получен ответ от API: ${response.statusCode}');
      
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('🔴 AuthRemoteDataSource: Ошибка DIO: ${e.response?.statusCode} - ${e.message}');
      
      if (e.response?.statusCode == 401) {
        final errorMessage = e.response?.data['message'] ?? 'Неверные учетные данные';
        throw AuthException(errorMessage);
      }
      
      if (e.response?.statusCode == 422) {
        final errorData = e.response?.data;
        if (errorData != null) {
          final apiError = ApiErrorModel.fromJson(errorData);
          throw ValidationException(
            apiError.message,
            apiError.errors ?? {},
          );
        }
      }
      
      throw NetworkException(
        'Ошибка сети: ${e.message}',
      );
    } catch (e) {
      print('🔴 AuthRemoteDataSource: Неожиданная ошибка: $e');
      throw NetworkException('Неожиданная ошибка: $e');
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      print('🔵 AuthRemoteDataSource: Отправляем запрос logout');
      
      await _dio.post('/auth/logout');
      
      print('🟢 AuthRemoteDataSource: Logout успешен');
    } on DioException catch (e) {
      print('🔴 AuthRemoteDataSource: Ошибка logout: ${e.message}');
      // Не выбрасываем исключение для logout, так как локальные данные все равно нужно очистить
    } catch (e) {
      print('🔴 AuthRemoteDataSource: Неожиданная ошибка logout: $e');
    }
  }
  
  @override
  Future<UserModel> getCurrentUser() async {
    try {
      print('🔵 AuthRemoteDataSource: Получаем текущего пользователя');
      
      final response = await _dio.get('/auth/me');
      
      print('🟢 AuthRemoteDataSource: Получены данные пользователя');
      
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('🔴 AuthRemoteDataSource: Ошибка получения пользователя: ${e.response?.statusCode} - ${e.message}');
      
      if (e.response?.statusCode == 401) {
        throw AuthException('Токен недействителен');
      }
      
      throw NetworkException('Ошибка получения пользователя: ${e.message}');
    } catch (e) {
      print('🔴 AuthRemoteDataSource: Неожиданная ошибка получения пользователя: $e');
      throw NetworkException('Неожиданная ошибка: $e');
    }
  }
  
  @override
  Future<UserModel> updateProfile({
    String? name,
    String? username,  
    String? email,
    String? phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final request = UpdateProfileRequest(
        name: name,
        username: username,
        email: email,
        phone: phone,
        currentPassword: currentPassword,
        newPassword: newPassword,
        passwordConfirmation: newPassword,
      );
      
      final response = await _dio.put('/auth/profile', data: request.toJson());
      
      // API возвращает объект с message и user
      final responseData = response.data as Map<String, dynamic>;
      return UserModel.fromJson(responseData['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errorData = e.response?.data;
        if (errorData != null) {
          final apiError = ApiErrorModel.fromJson(errorData);
          throw ValidationException(
            apiError.message,
            apiError.errors ?? {},
          );
        }
      }
      throw NetworkException('Ошибка обновления профиля: ${e.message}');
    }
  }
}

/// Provider для remote data source
@riverpod
AuthRemoteDataSource authRemoteDataSource(AuthRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return AuthRemoteDataSourceImpl(dio);
}

/// Кастомные исключения
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>> errors;
  const ValidationException(this.message, this.errors);
  
  @override
  String toString() => 'ValidationException: $message';
}


