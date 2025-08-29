import 'package:sum_warehouse/features/products/domain/entities/product_entity.dart';
import 'package:sum_warehouse/features/products/data/models/product_model.dart';

/// Репозиторий для работы с товарами
abstract class ProductRepository {
  /// Получить список товаров с фильтрацией
  Future<List<ProductEntity>> getProducts({
    String? search,
    int? warehouseId,
    int? templateId,
    String? producer,
    bool? inStock,
    bool? lowStock,
    bool? active,
    int page = 1,
    int perPage = 15,
  });

  /// Получить товар по ID
  Future<ProductEntity> getProduct(int id);

  /// Создать новый товар
  Future<ProductEntity> createProduct(CreateProductModel product);

  /// Обновить товар
  Future<ProductEntity> updateProduct(int id, CreateProductModel product);

  /// Удалить товар
  Future<void> deleteProduct(int id);

  /// Активировать/деактивировать товар
  Future<ProductEntity> toggleProductStatus(int id, bool isActive);

  /// Получить статистику товаров
  Future<ProductStatsEntity> getProductStats();

  /// Получить популярные товары
  Future<List<PopularProductEntity>> getPopularProducts({int limit = 10});

  /// Экспортировать товары в различных форматах
  Future<List<ProductEntity>> exportProducts({
    String? search,
    int? warehouseId,
    int? templateId,
    String? producer,
    bool? inStock,
    bool? lowStock,
    bool? active,
  });

  /// Получить товары склада
  Future<List<ProductEntity>> getWarehouseProducts(
    int warehouseId, {
    bool? isActive,
    int? templateId,
    String? search,
    int page = 1,
    int perPage = 15,
  });

  /// Обновить остатки товара
  Future<ProductEntity> updateProductQuantity(int id, double newQuantity, String reason);

  /// Получить историю движения товара
  Future<List<ProductMovementEntity>> getProductMovements(
    int productId, {
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int perPage = 15,
  });

  /// Генерировать QR код для товара
  Future<String> generateQRCode(int productId);

  /// Найти товар по QR коду
  Future<ProductEntity?> findProductByQRCode(String qrCode);

  /// Проверить наличие товара с таким же названием
  Future<bool> checkProductNameExists(String name, {int? excludeId});

  /// Рассчитать значение по формуле шаблона
  Future<double?> calculateTemplateFormula(int templateId, Map<String, dynamic> attributes);
}

/// Сущность статистики товаров
abstract class ProductStatsEntity {
  int get totalProducts;
  int get activeProducts;
  int get inStock;
  int get lowStock;
  int get outOfStock;
  double get totalQuantity;
  double get totalVolume;
}

/// Сущность популярного товара
abstract class PopularProductEntity {
  int get id;
  String get name;
  int get totalSales;
  double get totalRevenue;
  double get soldQuantity;
}

/// Сущность движения товара
abstract class ProductMovementEntity {
  int get id;
  int get productId;
  String get type; // 'receipt', 'sale', 'transfer', 'adjustment'
  double get quantity;
  double get previousQuantity;
  double get newQuantity;
  String? get reason;
  String? get notes;
  int get userId;
  DateTime get createdAt;
  
  // Связанные объекты
  ProductEntity? get product;
  UserEntity? get user;
}
