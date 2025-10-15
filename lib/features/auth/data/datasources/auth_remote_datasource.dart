import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/core/error/error_handler.dart';
import 'package:sum_warehouse/features/auth/data/models/user_model.dart';

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
      
      final response = await _dio.post(
        '/auth/login',
        data: LoginRequestModel(
          email: email,
          password: password,
        ).toJson(),
      );
      
      
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      
      await _dio.post('/auth/logout');
      
    } on DioException catch (e) {
      // Не выбрасываем исключение для logout, так как локальные данные все равно нужно очистить
    } catch (e) {
    }
  }
  
  @override
  Future<UserModel> getCurrentUser() async {
    try {
      
      final response = await _dio.get('/auth/me');
      
      
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handleError(e);
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
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
}

/// Provider для remote data source
@riverpod
AuthRemoteDataSource authRemoteDataSource(AuthRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return AuthRemoteDataSourceImpl(dio);
}
