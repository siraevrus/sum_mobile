import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/core/error/app_exceptions.dart';
import 'package:sum_warehouse/core/error/error_handler.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';
import 'package:sum_warehouse/shared/models/common_references.dart';

part 'warehouses_remote_datasource.g.dart';

/// Абстрактный класс для работы с API складов
abstract class WarehousesRemoteDataSource {
  Future<PaginatedResponse<WarehouseModel>> getWarehouses({
    int page = 1,
    int perPage = 15,
    int? companyId,
    bool? isActive,
    String? search,
  });

  Future<WarehouseModel> getWarehouse(int id);
  Future<WarehouseModel> createWarehouse(CreateWarehouseRequest request);
  Future<WarehouseModel> updateWarehouse(int id, UpdateWarehouseRequest request);
  Future<void> deleteWarehouse(int id);
  Future<WarehouseStats> getWarehouseStats(int id);
  Future<List<Map<String, dynamic>>> getWarehouseProducts(int id);
  Future<List<Map<String, dynamic>>> getWarehouseEmployees(int id);
  Future<void> activateWarehouse(int id);
  Future<void> deactivateWarehouse(int id);
  Future<WarehousesStatsResponse> getAllWarehousesStats();
}

/// Реализация remote data source для складов
class WarehousesRemoteDataSourceImpl implements WarehousesRemoteDataSource {
  final Dio _dio;
  
  WarehousesRemoteDataSourceImpl(this._dio);

  @override
  Future<PaginatedResponse<WarehouseModel>> getWarehouses({
    int page = 1,
    int perPage = 15,
    int? companyId,
    bool? isActive,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      
      if (companyId != null) queryParams['company_id'] = companyId;
      if (isActive != null) queryParams['is_active'] = isActive;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get('/warehouses', queryParameters: queryParams);
      
      return PaginatedResponse<WarehouseModel>.fromJson(
        response.data,
        (json) => WarehouseModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  @override
  Future<WarehouseModel> getWarehouse(int id) async {
    try {
      final response = await _dio.get('/warehouses/$id');
      return WarehouseModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<WarehouseModel> createWarehouse(CreateWarehouseRequest request) async {
    try {
      final response = await _dio.post('/warehouses', data: request.toJson());
      
      // API может вернуть { "message": "...", "warehouse": { ... } } или напрямую данные
      final responseData = response.data as Map<String, dynamic>;
      if (responseData.containsKey('warehouse')) {
        return WarehouseModel.fromJson(responseData['warehouse']);
      } else if (responseData.containsKey('data')) {
        return WarehouseModel.fromJson(responseData['data']);
      } else {
        return WarehouseModel.fromJson(responseData);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<WarehouseModel> updateWarehouse(int id, UpdateWarehouseRequest request) async {
    try {
      final response = await _dio.put('/warehouses/$id', data: request.toJson());
      
      final responseData = response.data as Map<String, dynamic>;
      if (responseData.containsKey('warehouse')) {
        return WarehouseModel.fromJson(responseData['warehouse']);
      } else if (responseData.containsKey('data')) {
        return WarehouseModel.fromJson(responseData['data']);
      } else {
        return WarehouseModel.fromJson(responseData);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteWarehouse(int id) async {
    try {
      await _dio.delete('/warehouses/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<WarehouseStats> getWarehouseStats(int id) async {
    try {
      final response = await _dio.get('/warehouses/$id/stats');
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('success') && data.containsKey('data')) {
          return WarehouseStats.fromJson(data['data']);
        } else {
          return WarehouseStats.fromJson(data);
        }
      }
      
      throw Exception('Неверный формат ответа API');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getWarehouseProducts(int id, {
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'per_page': perPage,
      };
      
      final response = await _dio.get('/warehouses/$id/products', 
        queryParameters: queryParams);
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getWarehouseEmployees(int id) async {
    try {
      final response = await _dio.get('/warehouses/$id/employees');
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> activateWarehouse(int id) async {
    try {
      await _dio.post('/warehouses/$id/activate');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deactivateWarehouse(int id) async {
    try {
      await _dio.post('/warehouses/$id/deactivate');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<WarehousesStatsResponse> getAllWarehousesStats() async {
    try {
      final response = await _dio.get('/warehouses/stats');
      
      // Проверяем формат ответа
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('success') && data.containsKey('data')) {
          return WarehousesStatsResponse.fromJson(data);
        } else {
          // API возвращает данные напрямую
          return WarehousesStatsResponse(
            success: true,
            data: WarehousesStatsModel.fromJson(data),
          );
        }
      }
      
      throw Exception('Неверный формат ответа API');
    } catch (e) {
      throw _handleError(e);
    }
  }


  /// Обработка ошибок
  AppException _handleError(dynamic error) {
    return ErrorHandler.handleError(error);
  }
}

@riverpod
WarehousesRemoteDataSource warehousesRemoteDataSource(WarehousesRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return WarehousesRemoteDataSourceImpl(dio);
}



