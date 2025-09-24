import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/shared/models/user_model.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

/// Парсер для количества (может быть строкой или числом)
double _parseQuantity(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) return parsed;
    // Если строка не является числом, возвращаем 0
    return 0.0;
  }
  return 0.0;
}

/// Парсер для ID полей (может быть строкой или числом)
int? _parseId(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed;
  }
  return null;
}

/// Парсер для обязательного ID поля (может быть строкой или числом)
int _parseRequiredId(dynamic value) {
  if (value is int) return value;
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Invalid required ID value: $value');
}

/// Основная модель товара по API
@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    @JsonKey(fromJson: _parseRequiredId) required int id,
    @JsonKey(name: 'product_template_id', fromJson: _parseId) int? productTemplateId,
    @JsonKey(name: 'warehouse_id', fromJson: _parseId) int? warehouseId,
    @JsonKey(name: 'created_by', fromJson: _parseId) int? createdBy,
    required String name,
    String? description,
    @JsonKey(fromJson: _parseQuantity) required double quantity,
    @JsonKey(fromJson: _parseAttributes) @Default({}) Map<String, dynamic>? attributes,
    @JsonKey(name: 'producer_id', fromJson: _parseId) int? producerId,
    String? producer,
    String? notes,
    @JsonKey(name: 'arrival_date') DateTime? arrivalDate,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'calculated_volume', fromJson: _parseNullableStringToDouble) double? calculatedVolume,
    @JsonKey(name: 'transport_number') String? transportNumber,
    String? status, // Статус товара (in_transit, received, etc.)
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    
    // Связанные объекты (приходят только с ?include)
    ProductTemplateRef? template,
    WarehouseRef? warehouse,
    UserRef? creator,
    @JsonKey(name: 'producer_info') ProducerRef? producerInfo,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) => 
      _$ProductModelFromJson(json);
}

/// Сокращенные ссылочные модели для связанных объектов
@freezed
class ProductTemplateRef with _$ProductTemplateRef {
  const factory ProductTemplateRef({
    required int id,
    String? name,
    String? unit,
  }) = _ProductTemplateRef;

  factory ProductTemplateRef.fromJson(Map<String, dynamic> json) => 
      _$ProductTemplateRefFromJson(json);
}

@freezed
class WarehouseRef with _$WarehouseRef {
  const factory WarehouseRef({
    required int id,
    String? name,
    String? address,
  }) = _WarehouseRef;

  factory WarehouseRef.fromJson(Map<String, dynamic> json) => 
      _$WarehouseRefFromJson(json);
}

@freezed
class UserRef with _$UserRef {
  const factory UserRef({
    required int id,
    String? name,
    String? email,
  }) = _UserRef;

  factory UserRef.fromJson(Map<String, dynamic> json) => 
      _$UserRefFromJson(json);
}

@freezed
class ProducerRef with _$ProducerRef {
  const factory ProducerRef({
    required int id,
    String? name,
    String? region,
  }) = _ProducerRef;

  factory ProducerRef.fromJson(Map<String, dynamic> json) => 
      _$ProducerRefFromJson(json);
}

/// Модель создания товара
@freezed
class CreateProductRequest with _$CreateProductRequest {
  const factory CreateProductRequest({
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    String? name, // Изменили на nullable, так как генерируется автоматически
    required double quantity,
    String? description,
    String? notes,
    @Default({}) Map<String, dynamic> attributes,
    @JsonKey(name: 'producer_id') int? producerId,
    @JsonKey(name: 'transport_number') String? transportNumber,
    @JsonKey(name: 'arrival_date') DateTime? arrivalDate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    String? status, // Статус товара при создании
  }) = _CreateProductRequest;

  factory CreateProductRequest.fromJson(Map<String, dynamic> json) => 
      _$CreateProductRequestFromJson(json);
}

/// Модель обновления товара
@freezed
class UpdateProductRequest with _$UpdateProductRequest {
  const factory UpdateProductRequest({
    @JsonKey(name: 'product_template_id') int? productTemplateId,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    String? name, // Изменили на nullable, так как генерируется автоматически
    double? quantity,
    String? description,
    String? notes,
    Map<String, dynamic>? attributes,
    @JsonKey(name: 'producer_id') int? producerId,
    @JsonKey(name: 'transport_number') String? transportNumber,
    @JsonKey(name: 'arrival_date') DateTime? arrivalDate,
    @JsonKey(name: 'is_active') bool? isActive,
    String? status, // Статус товара при обновлении
  }) = _UpdateProductRequest;

  factory UpdateProductRequest.fromJson(Map<String, dynamic> json) => 
      _$UpdateProductRequestFromJson(json);
}

/// Модель статистики товаров
@freezed
class ProductStats with _$ProductStats {
  const factory ProductStats({
    required bool success,
    required ProductStatsData data,
  }) = _ProductStats;

  factory ProductStats.fromJson(Map<String, dynamic> json) => 
      _$ProductStatsFromJson(json);
}

@freezed
class ProductStatsData with _$ProductStatsData {
  const factory ProductStatsData({
    @JsonKey(name: 'total_products') required int totalProducts,
    @JsonKey(name: 'active_products') required int activeProducts,
    @JsonKey(name: 'in_stock') required int inStock,
    @JsonKey(name: 'low_stock') required int lowStock,
    @JsonKey(name: 'out_of_stock') required int outOfStock,
    @JsonKey(name: 'total_quantity') required double totalQuantity,
    @JsonKey(name: 'total_volume') required double totalVolume,
  }) = _ProductStatsData;

  factory ProductStatsData.fromJson(Map<String, dynamic> json) => 
      _$ProductStatsDataFromJson(json);
}

/// Модель популярного товара
@freezed
class PopularProduct with _$PopularProduct {
  const factory PopularProduct({
    required int id,
    @JsonKey(name: 'total_sales') required int totalSales,
    @JsonKey(name: 'total_revenue') required String totalRevenue,
  }) = _PopularProduct;

  factory PopularProduct.fromJson(Map<String, dynamic> json) => 
      _$PopularProductFromJson(json);
}

/// Модель для экспорта товаров
@freezed
class ProductExportRow with _$ProductExportRow {
  const factory ProductExportRow({
    required int id,
    required String name,
    required double quantity,
    @JsonKey(name: 'calculated_volume') required double calculatedVolume,
    required String warehouse,
    required String template,
    @JsonKey(name: 'arrival_date') String? arrivalDate,
    @JsonKey(name: 'is_active') required String isActive, // "Да"/"Нет"
  }) = _ProductExportRow;

  factory ProductExportRow.fromJson(Map<String, dynamic> json) => 
      _$ProductExportRowFromJson(json);
}

/// Модель фильтров товаров
@freezed
class ProductFilters with _$ProductFilters {
  const factory ProductFilters({
    String? search,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'template_id') int? templateId,
    String? producer,
    @JsonKey(name: 'in_stock') bool? inStock,
    @JsonKey(name: 'low_stock') bool? lowStock,
    bool? active,
    String? status, // Фильтр по статусу товара
    @JsonKey(name: 'company_id') int? companyId, // Фильтр по компании
    @JsonKey(name: 'exclude_archived_companies') @Default(true) bool excludeArchivedCompanies, // Исключить товары от архивированных компаний
    @JsonKey(name: 'per_page') @Default(15) int perPage,
    @Default(1) int page,
  }) = _ProductFilters;

  factory ProductFilters.fromJson(Map<String, dynamic> json) => 
      _$ProductFiltersFromJson(json);
}

/// Расширение для ProductFilters
extension ProductFiltersX on ProductFilters {
  /// Конвертация в query параметры
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (warehouseId != null) params['warehouse_id'] = warehouseId;
    if (templateId != null) params['template_id'] = templateId;
    if (producer != null && producer!.isNotEmpty) params['producer'] = producer;
    if (inStock != null) params['in_stock'] = inStock! ? 1 : 0;
    if (lowStock != null) params['low_stock'] = lowStock! ? 1 : 0;
    if (active != null) params['active'] = active! ? 1 : 0;
    if (status != null && status!.isNotEmpty) params['status'] = status;
    if (companyId != null) params['company_id'] = companyId;
    if (excludeArchivedCompanies) params['exclude_archived_companies'] = 1;
    params['per_page'] = perPage;
    params['page'] = page;
    
    return params;
  }
}

/// Парсер для поля calculated_volume (может быть null, строкой или числом)
double? _parseNullableStringToDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Парсер для поля attributes (может быть строкой JSON или объектом)
Map<String, dynamic>? _parseAttributes(dynamic value) {
  if (value == null) return {};
  if (value is Map<String, dynamic>) return value;
  if (value is String) {
    try {
      // Пытаемся распарсить JSON строку
      final parsed = _parseJsonString(value);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
    } catch (e) {
      // Если не получилось распарсить, возвращаем пустой объект
      return {};
    }
  }
  return {};
}

/// Вспомогательная функция для парсинга JSON строки
dynamic _parseJsonString(String jsonString) {
  // Простой парсер для случаев вида: {grade: 1, width: 5, height: 5, length: 5}
  jsonString = jsonString.trim();
  if (!jsonString.startsWith('{') || !jsonString.endsWith('}')) {
    return {};
  }
  
  final result = <String, dynamic>{};
  final content = jsonString.substring(1, jsonString.length - 1);
  final pairs = content.split(',');
  
  for (final pair in pairs) {
    final parts = pair.split(':');
    if (parts.length == 2) {
      final key = parts[0].trim();
      final value = parts[1].trim();
      
      // Попытаемся определить тип значения
      if (value == 'null') {
        result[key] = null;
      } else if (value == 'true') {
        result[key] = true;
      } else if (value == 'false') {
        result[key] = false;
      } else if (int.tryParse(value) != null) {
        result[key] = int.parse(value);
      } else if (double.tryParse(value) != null) {
        result[key] = double.parse(value);
      } else {
        // Удаляем кавычки если они есть
        result[key] = value.replaceAll('"', '').replaceAll("'", '');
      }
    }
  }
  
  return result;
}
