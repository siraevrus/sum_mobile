import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:sum_warehouse/features/auth/data/repositories/auth_repository_impl.dart';

part 'login_usecase.g.dart';

// Простой провайдер для LoginUseCase без состояния
@riverpod
LoginUseCase loginUseCase(LoginUseCaseRef ref) {
  return LoginUseCase(ref);
}

/// Use case для входа в систему (без AsyncNotifier)
class LoginUseCase {
  final LoginUseCaseRef _ref;

  LoginUseCase(this._ref);
  
  /// Выполнить вход в систему
  Future<(UserEntity user, String token)> call({
    required String email,
    required String password,
  }) async {
    print('🔵 LoginUseCase: Начинаем логин для $email');
    
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);
      final result = await authRepository.login(
        email: email,
        password: password,
      );
      
      print('🟢 LoginUseCase: Логин успешен для $email');
      return result;
    } catch (error, stackTrace) {
      print('🔴 LoginUseCase: Ошибка логина: $error');
      rethrow;
    }
  }
}

// Простой провайдер для LogoutUseCase без состояния
@riverpod
LogoutUseCase logoutUseCase(LogoutUseCaseRef ref) {
  return LogoutUseCase(ref);
}

/// Use case для выхода из системы (без AsyncNotifier)
class LogoutUseCase {
  final LogoutUseCaseRef _ref;

  LogoutUseCase(this._ref);
  
  /// Выполнить выход из системы
  Future<void> call() async {
    print('🔵 LogoutUseCase: Начинаем выход из системы');
    
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);
      await authRepository.logout();
      
      print('🟢 LogoutUseCase: Выход успешен');
    } catch (error, stackTrace) {
      print('🔴 LogoutUseCase: Ошибка выхода: $error');
      rethrow;
    }
  }
}