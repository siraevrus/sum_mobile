import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/core/error/app_exceptions.dart';
import 'package:sum_warehouse/core/error/error_handler.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';
import 'package:sum_warehouse/features/sales/data/models/sale_model.dart';

part 'sales_remote_datasource.g.dart';

/// Абстрактный класс для работы с API продаж
abstract class SalesRemoteDataSource {
  /// Получить список продаж с фильтрацией
  Future<PaginatedResponse<SaleModel>> getSales({
    int page = 1,
    int perPage = 15,
    SaleFilters? filters,
  });

  /// Получить продажу по ID
  Future<SaleModel> getSale(int id);

  /// Создать новую продажу
  Future<SaleModel> createSale(CreateSaleRequest request);

  /// Обновить продажу
  Future<SaleModel> updateSale(int id, UpdateSaleRequest request);

  /// Удалить продажу
  Future<void> deleteSale(int id);

  /// Обработать продажу (списание товара)
  Future<void> processSale(int id);

  /// Отменить продажу
  Future<void> cancelSale(int id);
}

/// Реализация remote data source для продаж
class SalesRemoteDataSourceImpl implements SalesRemoteDataSource {
  final Dio _dio;

  SalesRemoteDataSourceImpl(this._dio);

  @override
  Future<PaginatedResponse<SaleModel>> getSales({
    int page = 1,
    int perPage = 15,
    SaleFilters? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      // Добавляем параметры фильтрации
      if (filters != null) {
        if (filters.search != null && filters.search!.isNotEmpty) {
          queryParams['search'] = filters.search;
        }
        if (filters.warehouseId != null) {
          queryParams['warehouse_id'] = filters.warehouseId;
        }
        if (filters.paymentStatus != null) {
          queryParams['payment_status'] = filters.paymentStatus;
        }
        if (filters.dateFrom != null) {
          queryParams['date_from'] = filters.dateFrom;
        }
        if (filters.dateTo != null) {
          queryParams['date_to'] = filters.dateTo;
        }
      }

      final response = await _dio.get('/sales', queryParameters: queryParams);

      return PaginatedResponse<SaleModel>.fromJson(
        response.data,
        (json) => SaleModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<SaleModel> getSale(int id) async {
    try {
      final response = await _dio.get('/sales/$id');

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        // Если ответ обернут в data структуру
        if (responseData.containsKey('data')) {
          return SaleModel.fromJson(responseData['data'] as Map<String, dynamic>);
        } else {
          return SaleModel.fromJson(responseData);
        }
      }

      throw Exception('Неожиданный формат ответа для getSale');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<SaleModel> createSale(CreateSaleRequest request) async {
    try {
      final requestData = request.toJson();
      

      final response = await _dio.post('/sales', data: requestData);
      

      final responseData = response.data;
      
      if (responseData is Map<String, dynamic>) {
        Map<String, dynamic> saleData;
        
        if (responseData.containsKey('sale')) {
          saleData = responseData['sale'] as Map<String, dynamic>;
        } else if (responseData.containsKey('data')) {
          saleData = responseData['data'] as Map<String, dynamic>;
        } else {
          saleData = responseData;
        }
        
        
        try {
          final sale = SaleModel.fromJson(saleData);
          return sale;
        } catch (e) {
          rethrow;
        }
      } else {
        throw Exception('Неожиданный формат ответа: ${responseData.runtimeType}');
      }
    } catch (e) {
      
      if (e is DioException) {
      }
      
      throw _handleError(e);
    }
  }

  @override
  Future<SaleModel> updateSale(int id, UpdateSaleRequest request) async {
    try {
      
      final response = await _dio.put('/sales/$id', data: request.toJson());
      

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data')) {
          return SaleModel.fromJson(responseData['data'] as Map<String, dynamic>);
        } else {
          return SaleModel.fromJson(responseData);
        }
      } else {
        throw Exception('Неожиданный формат ответа: ${responseData.runtimeType}');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteSale(int id) async {
    try {
      await _dio.delete('/sales/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> processSale(int id) async {
    try {
      await _dio.post('/sales/$id/process');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> cancelSale(int id) async {
    try {
      final response = await _dio.post('/sales/$id/cancel');


      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
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
SalesRemoteDataSource salesRemoteDataSource(SalesRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return SalesRemoteDataSourceImpl(dio);
}
