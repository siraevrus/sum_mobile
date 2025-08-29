import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';

/// Абстрактный репозиторий для аутентификации
abstract class AuthRepository {
  /// Вход пользователя в систему
  Future<(UserEntity user, String token)> login({
    required String email,
    required String password,
  });
  
  /// Выход из системы
  Future<void> logout();
  
  /// Получение текущего пользователя
  Future<UserEntity?> getCurrentUser();
  
  /// Проверка валидности токена
  Future<bool> isTokenValid();
  
  /// Обновление профиля пользователя  
  Future<UserEntity> updateProfile({
    String? name,
    String? username,
    String? email,
    String? phone,
    String? currentPassword,
    String? newPassword,
  });
}
