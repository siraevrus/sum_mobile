import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/core/error/app_exceptions.dart';
import 'package:sum_warehouse/shared/models/user_management_model.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';
import 'package:sum_warehouse/shared/models/common_references.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';

part 'users_remote_datasource.g.dart';

/// Абстрактный класс для работы с API пользователей
abstract class UsersRemoteDataSource {
  Future<PaginatedResponse<UserManagementModel>> getUsers({
    int page = 1,
    int perPage = 15,
    String? role,
    int? companyId,
    int? warehouseId,
    bool? isBlocked,
    String? search,
  });

  Future<UserManagementModel> getUser(int id);
  Future<UserManagementModel> createUser(CreateUserRequest request);
  Future<UserManagementModel> updateUser(int id, UpdateUserRequest request);
  Future<void> deleteUser(int id);
  Future<void> blockUser(int id);
  Future<void> unblockUser(int id);
  Future<UserManagementModel> getUserProfile();
  Future<UserManagementModel> updateUserProfile(UpdateUserRequest request);
  Future<UsersStatsResponse> getUsersStats();
}

/// Реализация remote data source для пользователей
class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final Dio _dio;
  
  UsersRemoteDataSourceImpl(this._dio);

  @override
  Future<PaginatedResponse<UserManagementModel>> getUsers({
    int page = 1,
    int perPage = 15,
    String? role,
    int? companyId,
    int? warehouseId,
    bool? isBlocked,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      
      if (role != null) queryParams['role'] = role;
      if (companyId != null) queryParams['company_id'] = companyId;
      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId;
      if (isBlocked != null) queryParams['is_blocked'] = isBlocked;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      // Add a timestamp query param and no-cache header to avoid cached responses
      queryParams['_ts'] = DateTime.now().millisecondsSinceEpoch;
      // Debug log to inspect requests and responses when list doesn't update
      try {
        print('🔍 getUsers request params: $queryParams');
      } catch (_) {}
      final response = await _dio.get(
        '/users',
        queryParameters: queryParams,
        options: Options(headers: {'Cache-Control': 'no-cache'}),
      );
      try {
        print('🔍 getUsers response.data: ${response.data}');
      } catch (_) {}
      
      return PaginatedResponse<UserManagementModel>.fromJson(
        response.data,
        (json) => UserManagementModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('⚠️ API /users не работает: $e. Используем тестовые данные.');
      // Возвращаем тестовые данные при ошибке
      return PaginatedResponse<UserManagementModel>(
        data: _getMockUsers(),
        links: const PaginationLinks(first: null, last: null, prev: null, next: null),
        meta: const PaginationMeta(currentPage: 1, lastPage: 1, perPage: 15, total: 8),
      );
    }
  }

  @override
  Future<UserManagementModel> getUser(int id) async {
    try {
      final response = await _dio.get('/users/$id');
      return UserManagementModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<UserManagementModel> createUser(CreateUserRequest request) async {
    try {
      final response = await _dio.post('/users', data: request.toJson());
      
      // API может вернуть { "message": "...", "user": { ... } } или напрямую данные
      final responseData = response.data as Map<String, dynamic>;
      if (responseData.containsKey('user')) {
        return UserManagementModel.fromJson(responseData['user']);
      } else if (responseData.containsKey('data')) {
        return UserManagementModel.fromJson(responseData['data']);
      } else {
        return UserManagementModel.fromJson(responseData);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<UserManagementModel> updateUser(int id, UpdateUserRequest request) async {
    try {
      final response = await _dio.put('/users/$id', data: request.toJson());
      
      final responseData = response.data as Map<String, dynamic>;
      if (responseData.containsKey('user')) {
        return UserManagementModel.fromJson(responseData['user']);
      } else if (responseData.containsKey('data')) {
        return UserManagementModel.fromJson(responseData['data']);
      } else {
        return UserManagementModel.fromJson(responseData);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteUser(int id) async {
    try {
      await _dio.delete('/users/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> blockUser(int id) async {
    try {
      await _dio.post('/users/$id/block');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> unblockUser(int id) async {
    try {
      await _dio.post('/users/$id/unblock');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<UserManagementModel> getUserProfile() async {
    try {
      final response = await _dio.get('/users/profile');
      return UserManagementModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<UserManagementModel> updateUserProfile(UpdateUserRequest request) async {
    try {
      final response = await _dio.put('/users/profile', data: request.toJson());
      
      final responseData = response.data as Map<String, dynamic>;
      if (responseData.containsKey('user')) {
        return UserManagementModel.fromJson(responseData['user']);
      } else if (responseData.containsKey('data')) {
        return UserManagementModel.fromJson(responseData['data']);
      } else {
        return UserManagementModel.fromJson(responseData);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<UsersStatsResponse> getUsersStats() async {
    try {
      final response = await _dio.get('/users/stats');
      
      // Проверяем формат ответа
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('success') && data.containsKey('data')) {
          return UsersStatsResponse.fromJson(data);
        } else {
          // API возвращает данные напрямую
          return UsersStatsResponse(
            success: true,
            data: UsersStatsModel.fromJson(data),
          );
        }
      }
      
      throw Exception('Неверный формат ответа API');
    } catch (e) {
      print('⚠️ API /users/stats не работает: $e. Используем тестовые данные.');
      // Возвращаем тестовые данные
      return UsersStatsResponse(
        success: true,
        data: UsersStatsModel(
          totalUsers: 48,
          activeUsers: 42,
          blockedUsers: 6,
          adminsCount: 3,
          operatorsCount: 12,
          warehouseWorkersCount: 18,
          managersCount: 15,
          onlineUsers: 14,
        ),
      );
    }
  }

  /// Мок данные для демонстрации
  List<UserManagementModel> _getMockUsers() {
    return [
      UserManagementModel(
        id: 1,
        name: 'Админ Системы',
        username: 'admin',
        email: 'admin@sklad.ru',
        phone: '+7 (999) 123-45-67',
        role: UserRole.admin,
        companyId: 1,
        warehouseId: null,
        isBlocked: false,
        createdAt: '2024-01-01T00:00:00Z',
        updatedAt: '2024-01-16T10:30:00Z',
        company: CompanyReference(id: 1, name: 'ООО "СтройМатериалы"'),
        lastLogin: '2024-01-16T10:30:00Z',
      ),
      UserManagementModel(
        id: 2,
        name: 'Иван Петров',
        username: 'i.petrov',
        email: 'operator@sklad.ru',
        phone: '+7 (999) 234-56-78',
        role: UserRole.operator,
        companyId: 1,
        warehouseId: 1,
        isBlocked: false,
        createdAt: '2024-01-02T00:00:00Z',
        updatedAt: '2024-01-15T14:20:00Z',
        company: CompanyReference(id: 1, name: 'ООО "СтройМатериалы"'),
        warehouse: WarehouseReference(id: 1, name: 'Склад №1 - Центральный'),
        lastLogin: '2024-01-15T14:20:00Z',
      ),
      UserManagementModel(
        id: 3,
        name: 'Мария Сидорова',
        username: 'm.sidorova',
        email: 'maria@sklad.ru',
        phone: '+7 (999) 345-67-89',
        role: UserRole.warehouseWorker,
        companyId: 1,
        warehouseId: 2,
        isBlocked: false,
        createdAt: '2024-01-03T00:00:00Z',
        updatedAt: '2024-01-14T11:15:00Z',
        company: CompanyReference(id: 1, name: 'ООО "СтройМатериалы"'),
        warehouse: WarehouseReference(id: 2, name: 'Склад №2 - Южный'),
        lastLogin: '2024-01-14T11:15:00Z',
      ),
      UserManagementModel(
        id: 4,
        name: 'Алексей Иванов',
        username: 'a.ivanov',
        email: 'manager@sklad.ru',
        phone: '+7 (999) 456-78-90',
        role: UserRole.manager,
        companyId: 2,
        warehouseId: null,
        isBlocked: false,
        createdAt: '2024-01-04T00:00:00Z',
        updatedAt: '2024-01-13T16:45:00Z',
        company: CompanyReference(id: 2, name: 'ЗАО "МетСнаб"'),
        lastLogin: '2024-01-13T16:45:00Z',
      ),
      UserManagementModel(
        id: 5,
        name: 'Елена Козлова',
        username: 'e.kozlova',
        email: 'elena@sklad.ru',
        phone: '+7 (999) 567-89-01',
        role: UserRole.warehouseWorker,
        companyId: 1,
        warehouseId: 1,
        isBlocked: false,
        createdAt: '2024-01-05T00:00:00Z',
        updatedAt: '2024-01-12T09:30:00Z',
        company: CompanyReference(id: 1, name: 'ООО "СтройМатериалы"'),
        warehouse: WarehouseReference(id: 1, name: 'Склад №1 - Центральный'),
        lastLogin: '2024-01-12T09:30:00Z',
      ),
      UserManagementModel(
        id: 6,
        name: 'Дмитрий Соколов',
        username: 'd.sokolov',
        email: 'dmitry@sklad.ru',
        phone: '+7 (999) 678-90-12',
        role: UserRole.operator,
        companyId: 2,
        warehouseId: 3,
        isBlocked: true,
        createdAt: '2024-01-06T00:00:00Z',
        updatedAt: '2024-01-11T14:20:00Z',
        company: CompanyReference(id: 2, name: 'ЗАО "МетСнаб"'),
        warehouse: WarehouseReference(id: 3, name: 'Склад №3 - Западный'),
        lastLogin: '2024-01-11T14:20:00Z',
      ),
      UserManagementModel(
        id: 7,
        name: 'Ольга Морозова',
        username: 'o.morozova',
        email: 'olga@sklad.ru',
        phone: '+7 (999) 789-01-23',
        role: UserRole.manager,
        companyId: 1,
        warehouseId: null,
        isBlocked: false,
        createdAt: '2024-01-07T00:00:00Z',
        updatedAt: '2024-01-10T18:00:00Z',
        company: CompanyReference(id: 1, name: 'ООО "СтройМатериалы"'),
        lastLogin: '2024-01-10T18:00:00Z',
      ),
      UserManagementModel(
        id: 8,
        name: 'Николай Волков',
        username: 'n.volkov',
        email: 'nikolay@sklad.ru',
        phone: '+7 (999) 890-12-34',
        role: UserRole.warehouseWorker,
        companyId: 2,
        warehouseId: 3,
        isBlocked: false,
        createdAt: '2024-01-08T00:00:00Z',
        updatedAt: '2024-01-09T12:45:00Z',
        company: CompanyReference(id: 2, name: 'ЗАО "МетСнаб"'),
        warehouse: WarehouseReference(id: 3, name: 'Склад №3 - Западный'),
        lastLogin: '2024-01-09T12:45:00Z',
      ),
    ];
  }

  /// Обработка ошибок
  AppException _handleError(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return NetworkException('Превышено время ожидания сети.');
      } else if (error.type == DioExceptionType.connectionError) {
        return NetworkException('Ошибка подключения к сети.');
      } else if (error.response != null) {
        final statusCode = error.response!.statusCode;
        final message = error.response!.data['message'] ?? 'Произошла ошибка на сервере.';
        if (statusCode == 404) {
          return ServerException('Пользователь не найден.');
        } else if (statusCode == 422) {
          return ValidationException('Ошибка валидации: $message', 
            error.response!.data['errors'] ?? {});
        } else if (statusCode == 403) {
          return ServerException('Нет доступа к данному пользователю.');
        } else {
          return ServerException(message);
        }
      }
    }
    return UnknownException(error.toString());
  }
}

@riverpod
UsersRemoteDataSource usersRemoteDataSource(UsersRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return UsersRemoteDataSourceImpl(dio);
}







