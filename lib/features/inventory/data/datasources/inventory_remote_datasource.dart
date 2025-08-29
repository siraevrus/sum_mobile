import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';
import 'package:sum_warehouse/shared/models/stock_model.dart';
import 'package:sum_warehouse/features/inventory/domain/entities/inventory_entity.dart';
import 'package:sum_warehouse/features/inventory/domain/entities/inventory_entity.dart' as entity;

part 'inventory_remote_datasource.g.dart';

/// Абстрактный интерфейс для remote data source остатков
abstract class InventoryRemoteDataSource {
  /// Получить остатки товаров на складе
  Future<List<InventoryEntity>> getInventoryByWarehouse(int warehouseId);
  
  /// Получить остатки конкретного товара
  Future<InventoryEntity> getInventoryByProduct(int productId);
  
  /// Получить все остатки с фильтрацией
  Future<List<InventoryEntity>> getAllInventory({
    int? warehouseId,
    entity.StockStatus? status,
    bool? needsRestock,
    String? search,
  });
  
  /// Получить агрегированные остатки (новое API)
  Future<List<StockModel>> getStocks();
  
  /// Создать движение товара
  Future<void> createStockMovement({
    required int productId,
    required int warehouseId,
    required MovementType type,
    required double quantity,
    String? reason,
    String? documentNumber,
    String? notes,
  });
  
  /// Корректировка остатков
  Future<void> adjustStock({
    required int productId,
    required int warehouseId,
    required double newQuantity,
    required String reason,
    String? notes,
  });
  
  /// Получить историю движений
  Future<List<StockMovementEntity>> getMovementHistory(int productId);
  
  /// Получить список остатков с фильтрацией
  Future<List<InventoryEntity>> getInventoryList({
    int? warehouseId,
    String? status,
    bool? needsRestock,
    String? search,
  });
  
  /// Обновить остатки
  Future<void> updateInventory(int inventoryId, double quantity);
  
  /// Создать движение товара (по inventory ID)
  Future<void> createStockMovementByInventory({
    required int inventoryId,
    required String type,
    required double quantity,
    String? reason,
    String? documentNumber,
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
  Future<List<InventoryEntity>> getInventoryByWarehouse(int warehouseId) async {
    try {
      final response = await _dio.get('/warehouses/$warehouseId/products');
      print('🟢 Inventory API response for warehouse $warehouseId: ${response.data}');
      
      if (response.data is List) {
        return (response.data as List)
            .map((item) => _convertProductToInventory(item, warehouseId))
            .toList();
      }
      
      return [];
    } on DioException catch (e) {
      print('⚠️ API /warehouses/$warehouseId/products не работает: ${e.response?.statusCode} - ${e.message}');
      return _getMockInventoryForWarehouse(warehouseId);
    } catch (e) {
      print('⚠️ Ошибка парсинга остатков склада: $e');
      return _getMockInventoryForWarehouse(warehouseId);
    }
  }

  @override
  Future<InventoryEntity> getInventoryByProduct(int productId) async {
    try {
      final response = await _dio.get('/products/$productId');
      print('🟢 Product API response for $productId: ${response.data}');
      
      return _convertProductToInventory(response.data, 1); // Default warehouse
    } on DioException catch (e) {
      print('⚠️ API /products/$productId не работает: ${e.response?.statusCode} - ${e.message}');
      throw Exception('Товар не найден');
    }
  }

  @override
  Future<List<InventoryEntity>> getAllInventory({
    int? warehouseId,
    entity.StockStatus? status,
    bool? needsRestock,
    String? search,
  }) async {
    if (warehouseId != null) {
      return getInventoryByWarehouse(warehouseId);
    }
    
    // Если не указан склад, получаем товары со всех складов
    try {
      final Map<String, dynamic> queryParams = {};
      if (search != null) queryParams['search'] = search;
      if (status != null) {
        switch (status) {
          case entity.StockStatus.inStock:
            queryParams['in_stock'] = true;
            break;
          case entity.StockStatus.lowStock:
            queryParams['low_stock'] = true;
            break;
          case entity.StockStatus.outOfStock:
            queryParams['in_stock'] = false;
            break;
        }
      }
      
      final response = await _dio.get('/products', queryParameters: queryParams);
      print('🟢 Products API response: ${response.data}');
      
      if (response.data is Map && response.data['data'] is List) {
        return (response.data['data'] as List)
            .map((item) => _convertProductToInventory(item, item['warehouse_id'] ?? 1))
            .toList();
      }
      
      return [];
    } on DioException catch (e) {
      print('⚠️ API /products не работает: ${e.response?.statusCode} - ${e.message}');
      return _getMockInventory();
    }
  }

  @override
  Future<void> createStockMovement({
    required int productId,
    required int warehouseId,
    required MovementType type,
    required double quantity,
    String? reason,
    String? documentNumber,
    String? notes,
  }) async {
    // TODO: Реализовать когда будет API для движений
    print('🟡 Создание движения товара: product=$productId, type=$type, quantity=$quantity');
    await Future.delayed(const Duration(seconds: 1)); // Имитация API вызова
    throw Exception('API для движений товаров еще не реализовано');
  }

  @override
  Future<void> adjustStock({
    required int productId,
    required int warehouseId,
    required double newQuantity,
    required String reason,
    String? notes,
  }) async {
    // TODO: Реализовать когда будет API для корректировок
    print('🟡 Корректировка остатков: product=$productId, newQuantity=$newQuantity, reason=$reason');
    await Future.delayed(const Duration(seconds: 1)); // Имитация API вызова
    throw Exception('API для корректировки остатков еще не реализовано');
  }

  @override
  Future<List<StockMovementEntity>> getMovementHistory(int productId) async {
    // TODO: Реализовать когда будет API для истории движений
    print('🟡 Получение истории движений для товара $productId');
    await Future.delayed(const Duration(seconds: 1)); // Имитация API вызова
    return _getMockMovements(productId);
  }

  /// Конвертировать данные товара в остатки
  InventoryEntity _convertProductToInventory(Map<String, dynamic> productData, int warehouseId) {
    final quantity = _parseDouble(productData['quantity']) ?? 0.0;
    final reservedQuantity = 0.0; // TODO: получать из API
    
    return InventoryEntity(
      id: productData['id'] ?? 0,
      warehouseId: warehouseId,
      productId: productData['id'] ?? 0,
      quantity: quantity,
      reservedQuantity: reservedQuantity,
      availableQuantity: quantity - reservedQuantity,
      minStockLevel: 10.0, // TODO: получать из API
      maxStockLevel: 100.0, // TODO: получать из API
      lastMovementDate: _parseDateTime(productData['updated_at']),
      lastUpdated: _parseDateTime(productData['updated_at']),
      product: ProductEntity(
        id: productData['id'] ?? 0,
        name: productData['name'] ?? 'Неизвестный товар',
        productTemplateId: productData['product_template_id'] ?? 0,
        unit: productData['unit'] ?? 'шт',
        producer: productData['producer'],
      ),
      warehouse: WarehouseEntity(
        id: warehouseId,
        name: 'Склад №$warehouseId',
        address: 'Адрес склада',
        companyId: 1,
      ),
    );
  }

  /// Парсер double из API
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Парсер DateTime из API
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Моковые данные для остатков склада
  List<InventoryEntity> _getMockInventoryForWarehouse(int warehouseId) {
    return _getMockInventory().where((item) => item.warehouseId == warehouseId).toList();
  }

  /// Моковые данные остатков
  List<InventoryEntity> _getMockInventory() {
    return [
      const InventoryEntity(
        id: 1,
        warehouseId: 1,
        productId: 1,
        quantity: 150,
        reservedQuantity: 20,
        availableQuantity: 130,
        minStockLevel: 50,
        maxStockLevel: 200,
        product: ProductEntity(
          id: 1,
          name: 'Кирпич красный',
          productTemplateId: 1,
          unit: 'шт',
          producer: 'ООО "СтройМатериалы"',
        ),
        warehouse: WarehouseEntity(
          id: 1,
          name: 'Основной склад',
          address: 'ул. Складская, 1',
          companyId: 1,
        ),
      ),
      const InventoryEntity(
        id: 2,
        warehouseId: 1,
        productId: 2,
        quantity: 8,
        reservedQuantity: 2,
        availableQuantity: 6,
        minStockLevel: 10,
        maxStockLevel: 50,
        product: ProductEntity(
          id: 2,
          name: 'Цемент М400',
          productTemplateId: 2,
          unit: 'мешок',
          producer: 'Цементный завод',
        ),
        warehouse: WarehouseEntity(
          id: 1,
          name: 'Основной склад',
          address: 'ул. Складская, 1',
          companyId: 1,
        ),
      ),
      const InventoryEntity(
        id: 3,
        warehouseId: 2,
        productId: 3,
        quantity: 0,
        reservedQuantity: 0,
        availableQuantity: 0,
        minStockLevel: 5,
        maxStockLevel: 25,
        product: ProductEntity(
          id: 3,
          name: 'Песок речной',
          productTemplateId: 3,
          unit: 'м³',
          producer: 'Карьер "Речной"',
        ),
        warehouse: WarehouseEntity(
          id: 2,
          name: 'Склад №2',
          address: 'ул. Промышленная, 15',
          companyId: 1,
        ),
      ),
    ];
  }

  @override
  Future<List<InventoryEntity>> getInventoryList({
    int? warehouseId,
    String? status,
    bool? needsRestock,
    String? search,
  }) async {
    return getAllInventory(
      warehouseId: warehouseId,
      status: status != null ? entity.StockStatus.values.firstWhere(
        (s) => s.code == status,
        orElse: () => entity.StockStatus.inStock,
      ) : null,
      needsRestock: needsRestock,
      search: search,
    );
  }

  @override
  Future<void> updateInventory(int inventoryId, double quantity) async {
    // TODO: Реализовать когда будет API для обновления остатков
    print('🟡 Обновление остатков: inventory=$inventoryId, quantity=$quantity');
    await Future.delayed(const Duration(seconds: 1)); // Имитация API вызова
    throw Exception('API для обновления остатков еще не реализовано');
  }

  @override
  Future<void> createStockMovementByInventory({
    required int inventoryId,
    required String type,
    required double quantity,
    String? reason,
    String? documentNumber,
    String? notes,
  }) async {
    // TODO: Реализовать когда будет API для движений
    print('🟡 Создание движения товара: inventory=$inventoryId, type=$type, quantity=$quantity');
    await Future.delayed(const Duration(seconds: 1)); // Имитация API вызова
    throw Exception('API для движений товаров еще не реализовано');
  }

  /// Моковые данные движений
  List<StockMovementEntity> _getMockMovements(int productId) {
    return [
      StockMovementEntity(
        id: 1,
        inventoryId: productId,
        userId: 1,
        type: MovementType.incoming,
        quantity: 100,
        previousQuantity: 50,
        newQuantity: 150,
        reason: 'Поступление товара',
        documentNumber: 'ПР-001',
        notes: 'Поставка от поставщика',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        user: const UserEntity(
          id: 1,
          name: 'Иван Петров',
          email: 'ivan@company.com',
        ),
      ),
      StockMovementEntity(
        id: 2,
        inventoryId: productId,
        userId: 2,
        type: MovementType.outgoing,
        quantity: -20,
        previousQuantity: 150,
        newQuantity: 130,
        reason: 'Продажа',
        documentNumber: 'РАС-002',
        notes: 'Продажа клиенту',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        user: const UserEntity(
          id: 2,
          name: 'Мария Сидорова',
          email: 'maria@company.com',
        ),
      ),
    ];
  }

  @override
  Future<List<StockModel>> getStocks() async {
    try {
      final response = await _dio.get('/stocks');
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> stocksList = data['data'] ?? [];
        
        return stocksList.map((json) => StockModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response.data is List) {
        final List<dynamic> stocksList = response.data as List;
        return stocksList.map((json) => StockModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching stocks: $e');
      // Возвращаем моковые данные если API недоступно
      return _getMockStocks();
    }
  }

  /// Мок данные для остатков 
  List<StockModel> _getMockStocks() {
    return [
      StockModel(
        id: '1',
        productTemplateId: 23,
        warehouseId: 12,
        producer: 'выфаыва',
        name: 'Пиломатериалы: 55, 55, 55, Ель',
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
        productTemplateId: 23,
        warehouseId: 12,
        producer: 'галала',
        name: 'арматура: 11, 22',
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
        productTemplateId: 23,
        warehouseId: 12,
        producer: 'Люкс',
        name: 'арматура: 11, 1',
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
        productTemplateId: 24,
        warehouseId: 12,
        producer: 'Супер',
        name: 'Пиломатериалы: 22, 22, 22, Ель',
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
        productTemplateId: 23,
        warehouseId: 12,
        producer: 'Пушкин',
        name: 'арматура: 22, 22',
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


