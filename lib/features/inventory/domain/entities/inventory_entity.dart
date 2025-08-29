import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_entity.freezed.dart';

/// Сущность остатков товара на складе
@freezed
class InventoryEntity with _$InventoryEntity {
  const factory InventoryEntity({
    required int id,
    required int warehouseId,
    required int productId,
    required double quantity,
    required double reservedQuantity,
    required double availableQuantity,
    double? minStockLevel, // Минимальный уровень остатков
    double? maxStockLevel, // Максимальный уровень остатков
    DateTime? lastMovementDate,
    DateTime? lastUpdated,
    
    // Связанные объекты
    WarehouseEntity? warehouse,
    ProductEntity? product,
    List<StockMovementEntity>? recentMovements,
  }) = _InventoryEntity;
  
  const InventoryEntity._();
  
  /// Получить статус остатков
  StockStatus get stockStatus {
    if (availableQuantity <= 0) {
      return StockStatus.outOfStock;
    } else if (minStockLevel != null && availableQuantity <= minStockLevel!) {
      return StockStatus.lowStock;
    } else {
      return StockStatus.inStock;
    }
  }
  
  /// Получить цвет статуса
  String get statusColor {
    switch (stockStatus) {
      case StockStatus.inStock:
        return '#38A169'; // Зеленый
      case StockStatus.lowStock:
        return '#D69E2E'; // Желтый
      case StockStatus.outOfStock:
        return '#E53E3E'; // Красный
    }
  }
  
  /// Процент заполненности склада (если есть максимальный уровень)
  double? get fillPercentage {
    if (maxStockLevel == null || maxStockLevel! <= 0) return null;
    return (quantity / maxStockLevel!) * 100;
  }
  
  /// Проверить нужна ли закупка
  bool get needsRestock {
    return stockStatus == StockStatus.lowStock || stockStatus == StockStatus.outOfStock;
  }
  
  /// Рекомендуемое количество для закупки
  double? get recommendedRestockQuantity {
    if (!needsRestock || maxStockLevel == null) return null;
    return maxStockLevel! - quantity;
  }
}

/// Сущность движения товара
@freezed
class StockMovementEntity with _$StockMovementEntity {
  const factory StockMovementEntity({
    required int id,
    required int inventoryId,
    required int userId,
    required MovementType type,
    required double quantity,
    required double previousQuantity,
    required double newQuantity,
    String? reason,
    String? documentNumber,
    String? notes,
    DateTime? createdAt,
    
    // Связанные объекты
    UserEntity? user,
    InventoryEntity? inventory,
  }) = _StockMovementEntity;
  
  const StockMovementEntity._();
  
  /// Получить цвет типа движения
  String get typeColor {
    switch (type) {
      case MovementType.incoming:
        return '#38A169'; // Зеленый
      case MovementType.outgoing:
        return '#E53E3E'; // Красный
      case MovementType.transfer:
        return '#3182CE'; // Синий
      case MovementType.adjustment:
        return '#D69E2E'; // Желтый
      case MovementType.reserve:
        return '#805AD5'; // Фиолетовый
      case MovementType.unreserve:
        return '#805AD5'; // Фиолетовый
    }
  }
  
  /// Получить иконку типа движения
  String get typeIcon {
    switch (type) {
      case MovementType.incoming:
        return 'arrow_downward'; // Поступление
      case MovementType.outgoing:
        return 'arrow_upward'; // Расход
      case MovementType.transfer:
        return 'swap_horiz'; // Перемещение
      case MovementType.adjustment:
        return 'edit'; // Корректировка
      case MovementType.reserve:
        return 'lock'; // Резерв
      case MovementType.unreserve:
        return 'lock_open'; // Снятие резерва
    }
  }
}

/// Статус остатков
enum StockStatus {
  inStock,
  lowStock,
  outOfStock,
}

/// Тип движения товара
enum MovementType {
  incoming,   // Поступление
  outgoing,   // Расход
  transfer,   // Перемещение между складами
  adjustment, // Корректировка
  reserve,    // Резерв
  unreserve,  // Снятие резерва
}

/// Расширения для статуса
extension StockStatusExtension on StockStatus {
  String get displayName {
    switch (this) {
      case StockStatus.inStock:
        return 'В наличии';
      case StockStatus.lowStock:
        return 'Мало';
      case StockStatus.outOfStock:
        return 'Нет в наличии';
    }
  }
  
  String get code {
    switch (this) {
      case StockStatus.inStock:
        return 'in_stock';
      case StockStatus.lowStock:
        return 'low_stock';
      case StockStatus.outOfStock:
        return 'out_of_stock';
    }
  }
  
  static StockStatus fromCode(String code) {
    switch (code) {
      case 'in_stock':
        return StockStatus.inStock;
      case 'low_stock':
        return StockStatus.lowStock;
      case 'out_of_stock':
        return StockStatus.outOfStock;
      default:
        throw ArgumentError('Unknown StockStatus code: $code');
    }
  }
}

/// Расширения для типа движения
extension MovementTypeExtension on MovementType {
  String get displayName {
    switch (this) {
      case MovementType.incoming:
        return 'Поступление';
      case MovementType.outgoing:
        return 'Расход';
      case MovementType.transfer:
        return 'Перемещение';
      case MovementType.adjustment:
        return 'Корректировка';
      case MovementType.reserve:
        return 'Резерв';
      case MovementType.unreserve:
        return 'Снятие резерва';
    }
  }
  
  String get code {
    switch (this) {
      case MovementType.incoming:
        return 'incoming';
      case MovementType.outgoing:
        return 'outgoing';
      case MovementType.transfer:
        return 'transfer';
      case MovementType.adjustment:
        return 'adjustment';
      case MovementType.reserve:
        return 'reserve';
      case MovementType.unreserve:
        return 'unreserve';
    }
  }
}

/// Временные сущности (заглушки для inventory модуля)
@freezed
class WarehouseEntity with _$WarehouseEntity {
  const factory WarehouseEntity({
    required int id,
    required String name,
    required String address,
    required int companyId,
    @Default(true) bool isActive,
  }) = _WarehouseEntity;
}

@freezed
class ProductEntity with _$ProductEntity {
  const factory ProductEntity({
    required int id,
    required String name,
    required int productTemplateId,
    required String unit,
    String? description,
    String? producer,
    String? qrCode,
    @Default(true) bool isActive,
  }) = _ProductEntity;
}

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required int id,
    required String name,
    required String email,
    String? role,
  }) = _UserEntity;
}
