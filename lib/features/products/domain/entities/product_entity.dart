import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/features/products/domain/entities/product_template_entity.dart';

part 'product_entity.freezed.dart';

/// Сущность товара с динамическими характеристиками
@freezed
class ProductEntity with _$ProductEntity {
  const factory ProductEntity({
    required int id,
    required String name,
    required int productTemplateId,
    required int warehouseId,
    required int creatorId,
    required double quantity,
    String? description,
    String? producer, // Производитель
    @Default({}) Map<String, dynamic> attributes, // Динамические характеристики
    double? calculatedValue, // Вычисленное значение по формуле (например, объем)
    String? qrCode, // QR код товара
    String? transportNumber, // Номер транспортного средства
    DateTime? arrivalDate, // Дата поступления
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    
    // Связанные сущности (могут быть null при загрузке списков)
    ProductTemplateEntity? template,
    WarehouseEntity? warehouse,
    UserEntity? creator,
  }) = _ProductEntity;
  
  const ProductEntity._();
  
  /// Получить значение характеристики по переменной
  dynamic getAttributeValue(String variable) {
    return attributes[variable];
  }
  
  /// Получить значение характеристики как строку
  String getAttributeValueAsString(String variable, [String defaultValue = '']) {
    final value = attributes[variable];
    if (value == null) return defaultValue;
    return value.toString();
  }
  
  /// Получить значение характеристики как число
  double getAttributeValueAsDouble(String variable, [double defaultValue = 0.0]) {
    final value = attributes[variable];
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
  
  /// Получить значение характеристики как целое число
  int getAttributeValueAsInt(String variable, [int defaultValue = 0]) {
    final value = attributes[variable];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
  
  /// Получить значение характеристики как булево
  bool getAttributeValueAsBool(String variable, [bool defaultValue = false]) {
    final value = attributes[variable];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'да' || lower == 'yes';
    }
    if (value is num) return value != 0;
    return defaultValue;
  }
  
  /// Проверить, заполнены ли все обязательные характеристики
  bool hasRequiredAttributes(List<TemplateAttributeEntity> templateAttributes) {
    final requiredAttributes = templateAttributes.where((attr) => attr.isRequired);
    
    for (final attr in requiredAttributes) {
      final value = attributes[attr.variable];
      if (value == null || value.toString().trim().isEmpty) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Получить список отсутствующих обязательных характеристик
  List<String> getMissingRequiredAttributes(List<TemplateAttributeEntity> templateAttributes) {
    final requiredAttributes = templateAttributes.where((attr) => attr.isRequired);
    final missing = <String>[];
    
    for (final attr in requiredAttributes) {
      final value = attributes[attr.variable];
      if (value == null || value.toString().trim().isEmpty) {
        missing.add(attr.name);
      }
    }
    
    return missing;
  }
  
  /// Проверить критически низкий остаток (менее 10 единиц или 10% от среднего)
  bool get isLowStock {
    if (quantity <= 0) return true;
    if (quantity < 10) return true; // Менее 10 единиц - всегда низкий остаток
    // TODO: Можно добавить логику сравнения со средним остатком по шаблону
    return false;
  }
  
  /// Проверить отсутствие товара
  bool get isOutOfStock {
    return quantity <= 0;
  }
  
  /// Получить статус остатка
  StockStatus get stockStatus {
    if (isOutOfStock) return StockStatus.outOfStock;
    if (isLowStock) return StockStatus.lowStock;
    return StockStatus.inStock;
  }
}

/// Статус остатка товара
enum StockStatus {
  /// В наличии
  inStock,
  /// Мало остатков
  lowStock,
  /// Нет в наличии
  outOfStock,
}

/// Расширение для получения отображаемого названия статуса
extension StockStatusExtension on StockStatus {
  String get displayName {
    switch (this) {
      case StockStatus.inStock:
        return 'В наличии';
      case StockStatus.lowStock:
        return 'Мало остатков';
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

/// Временная сущность склада (заглушка)
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

/// Временная сущность пользователя (заглушка)
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required int id,
    required String name,
    required String email,
  }) = _UserEntity;
}
