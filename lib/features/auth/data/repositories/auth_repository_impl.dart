import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:sum_warehouse/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sum_warehouse/features/auth/data/models/user_model.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:sum_warehouse/features/auth/domain/repositories/auth_repository.dart';

part 'auth_repository_impl.g.dart';

/// Реализация репозитория аутентификации
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  
  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);
  
  @override
  Future<(UserEntity user, String token)> login({
    required String email,
    required String password,
  }) async {
    try {
      // Выполняем запрос к API
      final authResponse = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      
      // Сохраняем токен локально
      await _localDataSource.saveToken(authResponse.token);
      
      // Сохраняем данные пользователя
      await _localDataSource.saveUserData(authResponse.user.toJson());
      
      // Преобразуем модель в entity
      final userEntity = _mapUserModelToEntity(authResponse.user);
      
      return (userEntity, authResponse.token);
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      // Выполняем logout на сервере
      await _remoteDataSource.logout();
    } finally {
      // Всегда очищаем локальные данные
      await _localDataSource.removeToken();
      await _localDataSource.removeUserData();
    }
  }
  
  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final token = await _localDataSource.getToken();
      if (token == null) return null;
      
      final userModel = await _remoteDataSource.getCurrentUser();
      return _mapUserModelToEntity(userModel);
    } catch (e) {
      // В случае ошибки очищаем локальные данные
      await _localDataSource.removeToken();
      await _localDataSource.removeUserData();
      return null;
    }
  }
  
  @override
  Future<bool> isTokenValid() async {
    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<UserEntity> updateProfile({
    String? name,
    String? username,
    String? email, 
    String? phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final updatedUser = await _remoteDataSource.updateProfile(
        name: name,
        username: username,
        email: email,
        phone: phone,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      // Обновляем локальные данные
      await _localDataSource.saveUserData(updatedUser.toJson());
      
      return _mapUserModelToEntity(updatedUser);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Преобразование UserModel в UserEntity
  UserEntity _mapUserModelToEntity(UserModel model) {
    return UserEntity(
      id: model.id,
      name: model.name,
      email: model.email,
      role: _mapStringToUserRole(model.role),
      username: model.username,
      phone: model.phone,
      companyId: model.companyId,
      warehouseId: model.warehouseId,
      isBlocked: model.isBlocked ?? false,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
  
  /// Преобразование строки роли в enum
  UserRole _mapStringToUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'operator':
        return UserRole.operator;
      case 'warehouse_worker':
        return UserRole.warehouseWorker;
      case 'manager':
        return UserRole.manager;
      case 'sales_manager':
        return UserRole.salesManager;
      default:
        throw ArgumentError('Unknown role: $role');
    }
  }
}

/// Provider для репозитория аутентификации
@riverpod
Future<AuthRepository> authRepository(AuthRepositoryRef ref) async {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localDataSource = await ref.watch(authLocalDataSourceProvider.future);
  return AuthRepositoryImpl(remoteDataSource, localDataSource);
}
