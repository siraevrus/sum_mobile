import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/core/error/app_exceptions.dart';
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

  /// Мок данные для демонстрации
  List<RequestModel> _getMockRequests() {
    return [
      RequestModel(
        id: 1,
        title: 'Запрос кирпича керамического',
        description: 'Срочно требуется пополнение кирпича для склада №1',
        quantity: 500.0,
        priority: RequestPriority.high,
        status: 'pending',
        warehouse: WarehouseReference(id: 1, name: 'Склад №1'),
        productTemplate: ProductTemplateReference(id: 1, name: 'Кирпич керамический'),
        user: UserReference(id: 1, name: 'Иван Петров'),
        createdAt: '2024-01-15T10:00:00Z',
        updatedAt: '2024-01-15T10:00:00Z',
      ),
      RequestModel(
        id: 2,
        title: 'Цемент М400',
        description: 'Плановое пополнение цемента',
        quantity: 200.0,
        priority: RequestPriority.normal,
        status: 'in_progress',
        warehouse: WarehouseReference(id: 2, name: 'Склад №2'),
        productTemplate: ProductTemplateReference(id: 2, name: 'Цемент'),
        user: UserReference(id: 2, name: 'Мария Сидорова'),
        createdAt: '2024-01-14T14:30:00Z',
        updatedAt: '2024-01-14T15:45:00Z',
      ),
      RequestModel(
        id: 3,
        title: 'Песок речной',
        description: 'Заканчивается песок на складе, нужно пополнение',
        quantity: 50.0,
        priority: RequestPriority.urgent,
        status: 'completed',
        warehouse: WarehouseReference(id: 1, name: 'Склад №1'),
        productTemplate: ProductTemplateReference(id: 3, name: 'Песок речной'),
        user: UserReference(id: 1, name: 'Иван Петров'),
        createdAt: '2024-01-13T08:20:00Z',
        updatedAt: '2024-01-13T16:30:00Z',
      ),
      RequestModel(
        id: 4,
        title: 'Щебень фр. 5-20',
        description: 'Для строительных работ',
        quantity: 100.0,
        priority: RequestPriority.normal,
        status: 'rejected',
        warehouse: WarehouseReference(id: 3, name: 'Склад №3'),
        productTemplate: ProductTemplateReference(id: 4, name: 'Щебень фракционный'),
        user: UserReference(id: 3, name: 'Алексей Иванов'),
        createdAt: '2024-01-12T11:15:00Z',
        updatedAt: '2024-01-12T14:20:00Z',
      ),
      RequestModel(
        id: 5,
        title: 'Арматура 12мм',
        description: 'Низкие остатки на складе',
        quantity: 300.0,
        priority: RequestPriority.low,
        status: 'pending',
        warehouse: WarehouseReference(id: 2, name: 'Склад №2'),
        productTemplate: ProductTemplateReference(id: 5, name: 'Арматура стальная'),
        user: UserReference(id: 2, name: 'Мария Сидорова'),
        createdAt: '2024-01-09T10:30:00Z',
        updatedAt: '2024-01-09T10:30:00Z',
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
          return ServerException('Запрос не найден.');
        } else if (statusCode == 422) {
          return ValidationException('Ошибка валидации: $message', 
            error.response!.data['errors'] ?? {});
        } else if (statusCode == 403) {
          return ServerException('Нет доступа к данному запросу.');
        } else {
          return ServerException(message);
        }
      }
    }
    return UnknownException(error.toString());
  }
}

@riverpod
RequestsRemoteDataSource requestsRemoteDataSource(RequestsRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return RequestsRemoteDataSourceImpl(dio);
}







