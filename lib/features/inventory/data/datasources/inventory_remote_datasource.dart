import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/core/error/error_handler.dart';
import 'package:sum_warehouse/shared/models/stock_model.dart';

part 'inventory_remote_datasource.g.dart';

/// Абстрактный интерфейс для remote data source остатков (новое API)
abstract class InventoryRemoteDataSource {
  /// Получить остатки товаров (новый API /stocks)
  Future<List<StockModel>> getStocks({
    int? warehouseId,
    bool? lowStock,
    int page = 1,
    int perPage = 15,
  });
  
  /// Получить конкретный остаток по ID
  Future<StockModel> getStockById(String stockId);
  
  /// Создать движение товара (НЕ РЕАЛИЗОВАНО в OpenAPI спецификации)
  /// TODO: Добавить endpoint /stock-movements в OpenAPI перед использованием
  Future<void> createStockMovement({
    required String stockId,
    required String type,
    required double quantity,
    String? reason,
    String? documentNumber,
    String? notes,
  });
  
  /// Корректировка остатков (НЕ РЕАЛИЗОВАНО в OpenAPI спецификации)
  /// TODO: Добавить endpoint /stocks/{id}/adjust в OpenAPI перед использованием
  Future<void> adjustStock({
    required String stockId,
    required double newQuantity,
    required String reason,
    String? notes,
  });
}

/// Реализация remote data source остатков
@riverpod
InventoryRemoteDataSource inventoryRemoteDataSource(InventoryRemoteDataSourceRef ref) {
  return InventoryRemoteDataSourceImpl(ref.read(dioClientProvider));
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final Dio _dio;

  InventoryRemoteDataSourceImpl(this._dio);

  @override
  Future<List<StockModel>> getStocks({
    int? warehouseId,
    bool? lowStock,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      
      if (warehouseId != null) {
        queryParams['warehouse_id'] = warehouseId;
      }
      
      if (lowStock != null) {
        queryParams['low_stock'] = lowStock;
      }
      
      final response = await _dio.get('/stocks', queryParameters: queryParams);
      
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> stocksList = data['data'] ?? [];
        
        return stocksList.map((json) => StockModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response.data is List) {
        final List<dynamic> stocksList = response.data as List;
        return stocksList.map((json) => StockModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      
      return [];
    } on DioException catch (e) {
      // Обрабатываем ошибку
      throw ErrorHandler.handleError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  @override
  Future<StockModel> getStockById(String stockId) async {
    try {
      final response = await _dio.get('/stocks/$stockId');
      
      
      return StockModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // Обрабатываем ошибку
      throw ErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> createStockMovement({
    required String stockId,
    required String type,
    required double quantity,
    String? reason,
    String? documentNumber,
    String? notes,
  }) async {
    // TODO: Endpoint /stock-movements is not defined in OpenAPI specification
    // This functionality needs to be added to the API before it can be used
    throw Exception('Функция движения товаров еще не реализована в API. Обратитесь к администратору.');
    
    /*
    // Original implementation that uses non-existent endpoint:
    try {
      final body = {
        'stock_id': stockId,
        'type': type,
        'quantity': quantity,
        if (reason != null) 'reason': reason,
        if (documentNumber != null) 'document_number': documentNumber,
        if (notes != null) 'notes': notes,
      };
      
      await _dio.post('/stock-movements', data: body);
      
    } on DioException catch (e) {
      throw Exception('API для движений товаров еще не реализовано');
    }
    */
  }

  @override
  Future<void> adjustStock({
    required String stockId,
    required double newQuantity,
    required String reason,
    String? notes,
  }) async {
    // TODO: Endpoint /stocks/{id}/adjust is not defined in OpenAPI specification
    // This functionality needs to be added to the API before it can be used
    throw Exception('Функция корректировки остатков еще не реализована в API. Обратитесь к администратору.');
    
    /*
    // Original implementation that uses non-existent endpoint:
    try {
      final body = {
        'new_quantity': newQuantity,
        'reason': reason,
        if (notes != null) 'notes': notes,
      };
      
      await _dio.patch('/stocks/$stockId/adjust', data: body);
      
    } on DioException catch (e) {
      throw Exception('API для корректировки остатков еще не реализовано');
    }
    */
  }

}


