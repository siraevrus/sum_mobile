import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:sum_warehouse/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sum_warehouse/features/auth/data/models/user_model.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:sum_warehouse/features/auth/domain/usecases/login_usecase.dart';
import 'package:sum_warehouse/features/app/presentation/providers/app_counters_provider.dart';

part 'auth_provider.g.dart';

/// Провайдер для состояния аутентификации
@riverpod
class Auth extends _$Auth {
  bool _isProcessing = false; // Флаг предотвращения одновременных операций
  
  @override
  AuthState build() {
    // Просто возвращаем начальное состояние
    // Инициализация будет происходить из SplashPage
    return const AuthState.initial();
  }
  
  /// Публичный метод для проверки статуса аутентификации
  Future<void> checkAuthStatus() async {
    
    // Проверяем, не выполняется ли уже операция
    if (_isProcessing) {
      return;
    }
    
    if (state.maybeWhen(loading: () => true, orElse: () => false)) {
      return;
    }
    
    _isProcessing = true;
    state = const AuthState.loading();
    
    try {
      final localDataSource = await ref.read(authLocalDataSourceProvider.future);
      final token = await localDataSource.getToken();
      final userData = await localDataSource.getUserData();
      
      if (token != null && token.isNotEmpty && userData != null) {
        // Если есть сохраненный токен и данные пользователя - используем их
        try {
          final userModel = UserModel.fromJson(userData);
          
          // Конвертируем UserModel в UserEntity для domain слоя
          final userEntity = UserEntity(
            id: userModel.id,
            name: userModel.name,
            email: userModel.email,
            role: _parseUserRole(userModel.role),
            username: userModel.username,
            isBlocked: userModel.isBlocked,
          );
          
          if (!userEntity.isBlocked) {
          state = AuthState.authenticated(user: userEntity, token: token);
          // Предзагружаем счетчики для администратора сразу после авторизации
          if (userEntity.role == UserRole.admin) {
            ref.read(appCountersProvider.future).catchError((_) {});
          }
          _isProcessing = false;
          return;
          } else {
          }
        } catch (e) {
          // Если ошибка парсинга - очищаем данные
          await localDataSource.removeToken();
          await localDataSource.removeUserData();
        }
      }
      
      // Если нет сохраненных данных или они невалидны - пользователь не авторизован
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = const AuthState.unauthenticated();
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Вход в систему
  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      state = const AuthState.error('Введите логин и пароль');
      return;
    }
    

    
    // Проверяем, не выполняется ли уже операция
    if (_isProcessing) {
      return;
    }
    
    _isProcessing = true;
    state = const AuthState.loading();
    
    try {
      final loginUseCase = ref.read(loginUseCaseProvider);
      
      final (user, token) = await loginUseCase.call(
        email: email.trim(),
        password: password,
      );
      
      
      if (user.isBlocked) {
        state = const AuthState.error('Ваш аккаунт заблокирован');
        return;
      }
      
      
      // Сохраняем токен и данные пользователя
      final localDataSource = await ref.read(authLocalDataSourceProvider.future);
      
      await localDataSource.saveToken(token);
      
      // Преобразуем UserEntity в UserModel для сохранения
      final userModel = UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        role: _userRoleToString(user.role), // Конвертируем enum в string
        username: user.username,
        isBlocked: user.isBlocked,
      );
      
      await localDataSource.saveUserData(userModel.toJson());
      
      state = AuthState.authenticated(user: user, token: token);
      
      // Предзагружаем счетчики для администратора сразу после логина
      if (user.role == UserRole.admin) {
        ref.read(appCountersProvider.future).catchError((_) {});
      }
    } catch (e) {
      
      String errorMessage = 'Произошла ошибка при входе';
      
      if (e.toString().contains('Неверные учетные данные')) {
        errorMessage = 'Неверный email или пароль';
      } else if (e.toString().contains('заблокирован')) {
        errorMessage = 'Ваш аккаунт заблокирован';
      } else if (e.toString().contains('NetworkException')) {
        errorMessage = 'Проблемы с сетью. Проверьте подключение к интернету';
      }
      
      state = AuthState.error(errorMessage);
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Выход из системы
  Future<void> logout() async {
    // Проверяем, не выполняется ли уже операция
    if (_isProcessing) {
      return;
    }
    
    _isProcessing = true;
    state = const AuthState.loading();
    
    try {
      // Очищаем локальные данные
      final localDataSource = await ref.read(authLocalDataSourceProvider.future);
      await localDataSource.removeToken();
      await localDataSource.removeUserData();
      
      // Вызываем logout на сервере
      final logoutUseCase = ref.read(logoutUseCaseProvider);
      await logoutUseCase.call();
      
      state = const AuthState.unauthenticated();
    } catch (e) {
      // Даже если logout на сервере не удался, локально выходим
      state = const AuthState.unauthenticated();
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Очистить ошибку
  void clearError() {
    state.whenOrNull(
      error: (_) {
        state = const AuthState.unauthenticated();
      },
    );
  }
  
  /// Проверка email на валидность
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  /// Конвертация строки роли в UserRole enum
  UserRole _parseUserRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'operator':
        return UserRole.operator;
      case 'warehouse_worker':
        return UserRole.warehouseWorker;
      case 'manager': // Для совместимости со старыми данными
      case 'sales_manager':
        return UserRole.salesManager;
      default:
        return UserRole.warehouseWorker; // По умолчанию
    }
  }
  
  /// Конвертация UserRole enum в строку
  String _userRoleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.operator:
        return 'operator';
      case UserRole.warehouseWorker:
        return 'warehouse_worker';
      case UserRole.salesManager:
        return 'sales_manager';
    }
  }
}

/// Провайдер для проверки роли текущего пользователя
@riverpod
UserRole? currentUserRole(CurrentUserRoleRef ref) {
  final authState = ref.watch(authProvider);
  
  return authState.maybeWhen(
    authenticated: (user, _) => user.role,
    orElse: () => null,
  );
}

/// Провайдер для проверки, авторизован ли пользователь
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  final authState = ref.watch(authProvider);
  
  return authState.maybeWhen(
    authenticated: (_, __) => true,
    orElse: () => false,
  );
}

/// Провайдер для получения текущего пользователя
@riverpod
UserEntity? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authProvider);
  
  return authState.maybeWhen(
    authenticated: (user, _) => user,
    orElse: () => null,
  );
}

/// Провайдер для проверки доступа к функциям по ролям
@riverpod
bool hasAccess(HasAccessRef ref, Set<UserRole> allowedRoles) {
  final currentRole = ref.watch(currentUserRoleProvider);
  
  if (currentRole == null) return false;
  
  return allowedRoles.contains(currentRole);
}

/// Удобные константы для проверки доступа
class AccessRoles {
  /// Полный доступ - только администратор
  static const fullAccess = {UserRole.admin};
  
  /// Доступ к товарам - админ, оператор, менеджер по продажам
  static const productsAccess = {UserRole.admin, UserRole.operator, UserRole.salesManager};
  
  /// Доступ к товарам в пути - админ, оператор, работник склада, менеджер по продажам
  static const goodsInTransitAccess = {
    UserRole.admin,
    UserRole.operator,
    UserRole.warehouseWorker,
    UserRole.salesManager,
  };
  
  /// Доступ к запросам - админ, работник склада, менеджер по продажам (БЕЗ оператора)
  static const requestsAccess = {
    UserRole.admin,
    UserRole.warehouseWorker,
    UserRole.salesManager,
  };
  
  /// Доступ к приемке - админ, работник склада
  static const receptionAccess = {UserRole.admin, UserRole.warehouseWorker};
  
  /// Доступ к продажам - админ, работник склада
  static const salesAccess = {UserRole.admin, UserRole.warehouseWorker};
  
  /// Доступ к остаткам - админ, оператор, работник склада, менеджер по продажам
  static const inventoryAccess = {
    UserRole.admin,
    UserRole.operator,
    UserRole.warehouseWorker,
    UserRole.salesManager,
  };
  
  /// Доступ к управлению компаниями - только админ
  static const companiesAccess = {UserRole.admin};
  
  /// Доступ к управлению пользователями - только админ
  static const usersAccess = {UserRole.admin};
  
  /// Доступ к управлению складами - только админ
  static const warehousesAccess = {UserRole.admin};
}
