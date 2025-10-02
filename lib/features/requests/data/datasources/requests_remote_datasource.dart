import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/core/error/app_exceptions.dart';
import 'package:sum_warehouse/core/error/error_handler.dart';
import 'package:sum_warehouse/shared/models/request_model.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';
import 'package:sum_warehouse/shared/models/common_references.dart';

part 'requests_remote_datasource.g.dart';

/// Абстрактный класс для работы с API запросов
abstract class RequestsRemoteDataSource {
  Future<PaginatedResponse<RequestModel>> getRequests({
    int page = 1,
    int perPage = 15,
    String? status,
    RequestPriority? priority,
    int? userId,
    int? warehouseId,
    int? productTemplateId,
  });

  Future<RequestModel> getRequest(int id);
  Future<RequestModel> createRequest(CreateRequestRequest request);
  Future<RequestModel> updateRequest(int id, UpdateRequestRequest request);
  Future<void> deleteRequest(int id);
  Future<void> processRequest(int id);
  Future<void> rejectRequest(int id);
}

/// Реализация remote data source для запросов
class RequestsRemoteDataSourceImpl implements RequestsRemoteDataSource {
  final Dio _dio;
  
  RequestsRemoteDataSourceImpl(this._dio);

  @override
  Future<PaginatedResponse<RequestModel>> getRequests({
    int page = 1,
    int perPage = 15,
    String? status,
    RequestPriority? priority,
    int? userId,
    int? warehouseId,
    int? productTemplateId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      
      if (status != null) queryParams['status'] = status;
      if (priority != null) queryParams['priority'] = priority.name;
      if (userId != null) queryParams['user_id'] = userId;
      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId;
      if (productTemplateId != null) queryParams['product_template_id'] = productTemplateId;

      final response = await _dio.get('/requests', queryParameters: queryParams);
      
      return PaginatedResponse<RequestModel>.fromJson(
        response.data,
        (json) => RequestModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('⚠️ API /requests не работает: $e.');
      rethrow;
    }
  }

  @override
  Future<RequestModel> getRequest(int id) async {
    try {
      final response = await _dio.get('/requests/$id');
      return RequestModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<RequestModel> createRequest(CreateRequestRequest request) async {
    try {
      final response = await _dio.post('/requests', data: request.toJson());
      
      // API может вернуть { "message": "...", "request": { ... } } или напрямую данные
      final responseData = response.data as Map<String, dynamic>;
      if (responseData.containsKey('request')) {
        return RequestModel.fromJson(responseData['request']);
      } else if (responseData.containsKey('data')) {
        return RequestModel.fromJson(responseData['data']);
      } else {
        return RequestModel.fromJson(responseData);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<RequestModel> updateRequest(int id, UpdateRequestRequest request) async {
    try {
      final response = await _dio.put('/requests/$id', data: request.toJson());
      
      final responseData = response.data as Map<String, dynamic>;
      if (responseData.containsKey('request')) {
        return RequestModel.fromJson(responseData['request']);
      } else if (responseData.containsKey('data')) {
        return RequestModel.fromJson(responseData['data']);
      } else {
        return RequestModel.fromJson(responseData);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteRequest(int id) async {
    try {
      await _dio.delete('/requests/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> processRequest(int id) async {
    try {
      await _dio.post('/requests/$id/process');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> rejectRequest(int id) async {
    try {
      await _dio.post('/requests/$id/reject');
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
RequestsRemoteDataSource requestsRemoteDataSource(RequestsRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return RequestsRemoteDataSourceImpl(dio);
}







