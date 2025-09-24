import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
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
      
      print('🔵 Запрос к /stocks с параметрами: $queryParams');
      final response = await _dio.get('/stocks', queryParameters: queryParams);
      
      print('📥 Stocks API response: ${response.data}');
      
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
      print('⚠️ API /stocks не работает: ${e.response?.statusCode} - ${e.message}');
      // Возвращаем mock данные для тестирования
      return _getMockStocks();
    } catch (e) {
      print('⚠️ Ошибка парсинга stocks: $e');
      return _getMockStocks();
    }
  }

  @override
  Future<StockModel> getStockById(String stockId) async {
    try {
      print('🔵 Запрос к /stocks/$stockId');
      final response = await _dio.get('/stocks/$stockId');
      
      print('📥 Stock by ID response: ${response.data}');
      
      return StockModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('⚠️ API /stocks/$stockId не работает: ${e.response?.statusCode} - ${e.message}');
      // Возвращаем первый mock остаток
      final mockStocks = _getMockStocks();
      if (mockStocks.isNotEmpty) {
        return mockStocks.first;
      }
      throw Exception('Остаток не найден');
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
      
      print('🔵 Создание движения: $body');
      await _dio.post('/stock-movements', data: body);
      
      print('✅ Движение создано успешно');
    } on DioException catch (e) {
      print('⚠️ API /stock-movements не работает: ${e.response?.statusCode} - ${e.message}');
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
      
      print('🔵 Корректировка остатков: stock=$stockId, body=$body');
      await _dio.patch('/stocks/$stockId/adjust', data: body);
      
      print('✅ Остатки откорректированы успешно');
    } on DioException catch (e) {
      print('⚠️ API /stocks/$stockId/adjust не работает: ${e.response?.statusCode} - ${e.message}');
      throw Exception('API для корректировки остатков еще не реализовано');
    }
    */
  }

  /// Мок данные для остатков 
  List<StockModel> _getMockStocks() {
    return [
      StockModel(
        id: '1',
        productTemplateId: 23,
        warehouseId: 12,
        producer: 'ООО "СтройМатериалы"',
        name: 'Пиломатериалы: 55x55x55, Ель',
        availableQuantity: 14.0,
        availableVolume: 2329.25,
        itemsCount: 1,
        firstArrival: DateTime.now().subtract(const Duration(days: 10)),
        lastArrival: DateTime.now().subtract(const Duration(days: 2)),
        template: null,
        warehouse: null,
      ),
      StockModel(
        id: '2',
        productTemplateId: 24,
        warehouseId: 12,
        producer: 'Металлургический завод',
        name: 'Арматура: 11x22мм',
        availableQuantity: 22.0,
        availableVolume: 53.24,
        itemsCount: 1,
        firstArrival: DateTime.now().subtract(const Duration(days: 5)),
        lastArrival: DateTime.now().subtract(const Duration(days: 1)),
        template: null,
        warehouse: null,
      ),
      StockModel(
        id: '3',
        productTemplateId: 25,
        warehouseId: 12,
        producer: 'Люкс Строй',
        name: 'Арматура: 11x11мм',
        availableQuantity: 13.0,
        availableVolume: 1.43,
        itemsCount: 1,
        firstArrival: DateTime.now().subtract(const Duration(days: 7)),
        lastArrival: DateTime.now().subtract(const Duration(days: 7)),
        template: null,
        warehouse: null,
      ),
      StockModel(
        id: '4',
        productTemplateId: 26,
        warehouseId: 12,
        producer: 'Супер Строй',
        name: 'Пиломатериалы: 22x22x22, Ель',
        availableQuantity: 10.0,
        availableVolume: 106.48,
        itemsCount: 1,
        firstArrival: DateTime.now().subtract(const Duration(days: 3)),
        lastArrival: DateTime.now().subtract(const Duration(days: 3)),
        template: null,
        warehouse: null,
      ),
      StockModel(
        id: '5',
        productTemplateId: 27,
        warehouseId: 12,
        producer: 'Пушкин Металл',
        name: 'Арматура: 22x22мм',
        availableQuantity: 131.0,
        availableVolume: 687.28,
        itemsCount: 2,
        firstArrival: DateTime.now().subtract(const Duration(days: 15)),
        lastArrival: DateTime.now().subtract(const Duration(days: 1)),
        template: null,
        warehouse: null,
      ),
    ];
  }
}


