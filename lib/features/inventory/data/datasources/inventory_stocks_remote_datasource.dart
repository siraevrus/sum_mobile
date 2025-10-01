import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/app_exceptions.dart';
import '../../../../shared/models/inventory_models.dart';
import '../../../../shared/models/product_model.dart';

part 'inventory_stocks_remote_datasource.g.dart';

/// Abstract interface for inventory stocks remote data source
abstract class InventoryStocksRemoteDataSource {
  /// Получить остатки на складах (товары со статусом in_stock)
  Future<List<ProductModel>> getStocks({
    int page = 1,
    int perPage = 15,
    int? warehouseId,
    String? status,
    int? companyId,
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  /// Получить список производителей
  Future<List<InventoryProducerModel>> getProducers();

  /// Получить список складов
  Future<InventoryWarehousesResponse> getWarehouses({
    int page = 1,
    int perPage = 50,
  });

  /// Получить список компаний
  Future<InventoryCompaniesResponse> getCompanies({
    int page = 1,
    int perPage = 50,
  });
}

/// Implementation of inventory stocks remote data source
class InventoryStocksRemoteDataSourceImpl implements InventoryStocksRemoteDataSource {
  final Dio _dio;
  
  InventoryStocksRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ProductModel>> getStocks({
    int page = 1,
    int perPage = 15,
    int? warehouseId,
    String? status,
    int? companyId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      print('🔵 Запрос остатков на складах...');
      
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'status': status ?? 'in_stock', // Всегда добавляем статус
        'include': 'template,warehouse,creator,producer', // Добавляем include для связанных объектов
      };
      
      if (warehouseId != null) {
        queryParams['warehouse_id'] = warehouseId;
      }
      
      // Добавляем фильтр по компании (если поддерживается API)
      if (companyId != null) {
        queryParams['company_id'] = companyId;
      }
      
      // Добавляем фильтр по датам (если поддерживается API)
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }
      
      print('🔵 Параметры запроса к /products: $queryParams');
      
      // Используем эндпоинт /products со статусом in_stock
      final response = await _dio.get('/products', queryParameters: queryParams);
      
      print('📥 Ответ API товаров (поступление): ${response.data}');
      
      // Парсим ответ как список товаров
      if (response.data is Map<String, dynamic> && response.data['data'] is List) {
        final List<dynamic> productsData = response.data['data'];
        return productsData.map((productJson) => ProductModel.fromJson(productJson)).toList();
      } else if (response.data is List) {
        // Если ответ сразу список
        return (response.data as List).map((productJson) => ProductModel.fromJson(productJson)).toList();
      } else {
        throw const ServerException('Неожиданный формат ответа для товаров');
      }
    } catch (e) {
      print('🔴 Ошибка получения остатков: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<List<InventoryProducerModel>> getProducers() async {
    try {
      print('🔵 Запрос списка производителей...');
      
      final response = await _dio.get('/producers');
      
      print('📥 Ответ API производителей: ${response.data}');
      
      // Производители возвращаются как простой массив
      if (response.data is List) {
        return (response.data as List)
            .map((e) => InventoryProducerModel.fromJson(e))
            .toList();
      }
      
      throw const ServerException('Неожиданный формат ответа для производителей');
    } catch (e) {
      print('🔴 Ошибка получения производителей: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<InventoryWarehousesResponse> getWarehouses({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('🔵 Запрос списка складов...');
      
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      
      final response = await _dio.get('/warehouses', queryParameters: queryParams);
      
      print('📥 Ответ API складов: ${response.data}');
      
      return InventoryWarehousesResponse.fromJson(response.data);
    } catch (e) {
      print('🔴 Ошибка получения складов: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<InventoryCompaniesResponse> getCompanies({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('🔵 Запрос списка компаний...');
      
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      
      final response = await _dio.get('/companies', queryParameters: queryParams);
      
      print('📥 Ответ API компаний: ${response.data}');
      
      return InventoryCompaniesResponse.fromJson(response.data);
    } catch (e) {
      print('🔴 Ошибка получения компаний: $e');
      throw _handleError(e);
    }
  }

  AppException _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const NetworkException('Превышено время ожидания');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['message'] ?? 'Ошибка сервера';
          
          if (statusCode == 401) {
            return const AuthException('Требуется авторизация');
          } else if (statusCode == 403) {
            return const AuthException('Доступ запрещен');
          } else if (statusCode == 404) {
            return const ServerException('Ресурс не найден', 404);
          } else {
            return ServerException('$statusCode: $message', statusCode);
          }
        case DioExceptionType.cancel:
          return const NetworkException('Запрос отменен');
        default:
          return const NetworkException('Ошибка сети');
      }
    }
    
    return UnknownException(error.toString());
  }
}

@riverpod
InventoryStocksRemoteDataSource inventoryStocksRemoteDataSource(InventoryStocksRemoteDataSourceRef ref) {
  final dio = ref.read(dioClientProvider);
  return InventoryStocksRemoteDataSourceImpl(dio);
}
