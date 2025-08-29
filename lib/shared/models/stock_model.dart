import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_model.freezed.dart';
part 'stock_model.g.dart';

/// Модель агрегированных остатков согласно OpenAPI спецификации
@freezed
class StockModel with _$StockModel {
  const factory StockModel({
    required String id, // Составной ключ для агрегированных данных
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    required String producer,
    required String name, // Наименование товара (шаблон + характеристики)
    @JsonKey(name: 'available_quantity') required double availableQuantity, // Доступное количество с учетом продаж
    @JsonKey(name: 'available_volume') required double availableVolume, // Доступный объем с учетом продаж
    @JsonKey(name: 'items_count') required int itemsCount, // Количество позиций товара
    @JsonKey(name: 'first_arrival') required DateTime firstArrival, // Дата первого поступления
    @JsonKey(name: 'last_arrival') required DateTime lastArrival, // Дата последнего поступления
    
    // Связанные объекты
    StockTemplateRef? template,
    StockWarehouseRef? warehouse,
  }) = _StockModel;

  const StockModel._();

  factory StockModel.fromJson(Map<String, dynamic> json) => 
      _$StockModelFromJson(json);

  /// Получить статус остатков
  StockStatus get stockStatus {
    if (availableQuantity <= 0) {
      return StockStatus.outOfStock;
    } else if (availableQuantity <= 10) { // API определяет ≤10 как low_stock
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
}

/// Ссылка на шаблон товара в остатках
@freezed
class StockTemplateRef with _$StockTemplateRef {
  const factory StockTemplateRef({
    required int id,
    required String name,
  }) = _StockTemplateRef;

  factory StockTemplateRef.fromJson(Map<String, dynamic> json) => 
      _$StockTemplateRefFromJson(json);
}

/// Ссылка на склад в остатках
@freezed
class StockWarehouseRef with _$StockWarehouseRef {
  const factory StockWarehouseRef({
    required int id,
    required String name,
  }) = _StockWarehouseRef;

  factory StockWarehouseRef.fromJson(Map<String, dynamic> json) => 
      _$StockWarehouseRefFromJson(json);
}

/// Статус остатков согласно API
enum StockStatus {
  inStock,
  lowStock,
  outOfStock,
}

/// Расширения для статуса остатков
extension StockStatusExtension on StockStatus {
  String get displayName {
    switch (this) {
      case StockStatus.inStock:
        return 'В наличии';
      case StockStatus.lowStock:
        return 'Заканчивается';
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
}


