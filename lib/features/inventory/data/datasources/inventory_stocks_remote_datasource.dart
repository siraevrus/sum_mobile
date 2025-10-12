import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/app_exceptions.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../shared/models/inventory_models.dart' as old_models;
import '../../../../shared/models/product_model.dart';
import '../../domain/entities/inventory_aggregation_entity.dart';

part 'inventory_stocks_remote_datasource.g.dart';

/// Abstract interface for inventory stocks remote data source
abstract class InventoryStocksRemoteDataSource {
  /// Получить остатки на складах (товары со статусом in_stock)
  Future<List<ProductModel>> getStocks({
    int page = 1,
    int perPage = 15,
    int? warehouseId,
    String? status,
  });

  /// Получить список производителей с агрегацией
  Future<List<InventoryProducerModel>> getProducers();
  
  /// Получить детальную информацию по производителю
  Future<PaginatedStockDetails> getProducerDetails(int producerId, {int page = 1, int perPage = 15});

  /// Получить список складов с агрегацией
  Future<List<InventoryWarehouseModel>> getWarehouses();
  
  /// Получить детальную информацию по складу
  Future<PaginatedStockDetails> getWarehouseDetails(int warehouseId, {int page = 1, int perPage = 15});

  /// Получить список компаний с агрегацией
  Future<List<InventoryCompanyModel>> getCompanies();
  
  /// Получить детальную информацию по компании
  Future<PaginatedStockDetails> getCompanyDetails(int companyId, {int page = 1, int perPage = 15});
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
      print('🔵 Запрос списка производителей с агрегацией...');
      
      final response = await _dio.get('/stocks/producers');
      
      print('📥 Ответ API производителей: ${response.data}');
      
      // Парсим ответ
      if (response.data is Map<String, dynamic> && response.data['data'] is List) {
        final List<dynamic> producersData = response.data['data'];
        return producersData.map((e) => InventoryProducerModel.fromJson(e)).toList();
      } else if (response.data is List) {
        return (response.data as List).map((e) => InventoryProducerModel.fromJson(e)).toList();
      }
      
      throw const ServerException('Неожиданный формат ответа для производителей');
    } catch (e) {
      print('🔴 Ошибка получения производителей: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<PaginatedStockDetails> getProducerDetails(int producerId, {int page = 1, int perPage = 15}) async {
    try {
      print('🔵 Запрос деталей производителя $producerId...');
      
      final queryParams = <String, dynamic>{
        'per_page': perPage,
      };
      
      final response = await _dio.get('/stocks/by-producer/$producerId', queryParameters: queryParams);
      
      print('📥 Ответ API деталей производителя: ${response.data}');
      
      return PaginatedStockDetails.fromJson(response.data);
    } catch (e) {
      print('🔴 Ошибка получения деталей производителя: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<List<InventoryWarehouseModel>> getWarehouses() async {
    try {
      print('🔵 Запрос списка складов с агрегацией...');
      
      final response = await _dio.get('/stocks/warehouses');
      
      print('📥 Ответ API складов: ${response.data}');
      
      // Парсим ответ
      if (response.data is Map<String, dynamic> && response.data['data'] is List) {
        final List<dynamic> warehousesData = response.data['data'];
        return warehousesData.map((e) => InventoryWarehouseModel.fromJson(e)).toList();
      } else if (response.data is List) {
        return (response.data as List).map((e) => InventoryWarehouseModel.fromJson(e)).toList();
      }
      
      throw const ServerException('Неожиданный формат ответа для складов');
    } catch (e) {
      print('🔴 Ошибка получения складов: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<PaginatedStockDetails> getWarehouseDetails(int warehouseId, {int page = 1, int perPage = 15}) async {
    try {
      print('🔵 Запрос деталей склада $warehouseId...');
      
      final queryParams = <String, dynamic>{
        'per_page': perPage,
      };
      
      final response = await _dio.get('/stocks/by-warehouse/$warehouseId', queryParameters: queryParams);
      
      print('📥 Ответ API деталей склада: ${response.data}');
      
      return PaginatedStockDetails.fromJson(response.data);
    } catch (e) {
      print('🔴 Ошибка получения деталей склада: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<List<InventoryCompanyModel>> getCompanies() async {
    try {
      print('🔵 Запрос списка компаний с агрегацией...');
      
      final response = await _dio.get('/stocks/companies');
      
      print('📥 Ответ API компаний: ${response.data}');
      
      // Парсим ответ
      if (response.data is Map<String, dynamic> && response.data['data'] is List) {
        final List<dynamic> companiesData = response.data['data'];
        return companiesData.map((e) => InventoryCompanyModel.fromJson(e)).toList();
      } else if (response.data is List) {
        return (response.data as List).map((e) => InventoryCompanyModel.fromJson(e)).toList();
      }
      
      throw const ServerException('Неожиданный формат ответа для компаний');
    } catch (e) {
      print('🔴 Ошибка получения компаний: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<PaginatedStockDetails> getCompanyDetails(int companyId, {int page = 1, int perPage = 15}) async {
    try {
      print('🔵 Запрос деталей компании $companyId...');
      
      final queryParams = <String, dynamic>{
        'per_page': perPage,
      };
      
      final response = await _dio.get('/stocks/by-company/$companyId', queryParameters: queryParams);
      
      print('📥 Ответ API деталей компании: ${response.data}');
      
      return PaginatedStockDetails.fromJson(response.data);
    } catch (e) {
      print('🔴 Ошибка получения деталей компании: $e');
      throw _handleError(e);
    }
  }

  AppException _handleError(dynamic error) {
    return ErrorHandler.handleError(error);
  }
}

@riverpod
InventoryStocksRemoteDataSource inventoryStocksRemoteDataSource(InventoryStocksRemoteDataSourceRef ref) {
  final dio = ref.read(dioClientProvider);
  return InventoryStocksRemoteDataSourceImpl(dio);
}
