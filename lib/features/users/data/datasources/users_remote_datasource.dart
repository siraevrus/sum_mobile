import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/core/error/app_exceptions.dart';
import 'package:sum_warehouse/core/error/error_handler.dart';
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
      } catch (_) {}
      final response = await _dio.get(
        '/users',
        queryParameters: queryParams,
        options: Options(headers: {'Cache-Control': 'no-cache'}),
      );
      try {
      } catch (_) {}
      
      return PaginatedResponse<UserManagementModel>.fromJson(
        response.data,
        (json) => UserManagementModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw ErrorHandler.handleError(e);
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
      final response = await _dio.get('/auth/profile');
      return UserManagementModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<UserManagementModel> updateUserProfile(UpdateUserRequest request) async {
    try {
      final response = await _dio.put('/auth/profile', data: request.toJson());
      
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
      throw ErrorHandler.handleError(e);
    }
  }


  /// Обработка ошибок
  AppException _handleError(dynamic error) {
    return ErrorHandler.handleError(error);
  }
}

@riverpod
UsersRemoteDataSource usersRemoteDataSource(UsersRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return UsersRemoteDataSourceImpl(dio);
}







