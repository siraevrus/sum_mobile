import 'package:freezed_annotation/freezed_annotation.dart';

part 'popular_products_model.freezed.dart';
part 'popular_products_model.g.dart';

/// Модель популярного товара
@freezed
class PopularProductModel with _$PopularProductModel {
  const factory PopularProductModel({
    required int id,
    @JsonKey(name: 'product_template_id') int? productTemplateId,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'created_by') int? createdBy,
    String? name,
    String? description,
    String? producer,
    @JsonKey(fromJson: _parseNullableStringToDouble) double? quantity,
    @JsonKey(name: 'calculated_volume', fromJson: _parseNullableStringToDouble) double? calculatedVolume,
    @JsonKey(name: 'transport_number') String? transportNumber,
    @JsonKey(name: 'arrival_date') String? arrivalDate,
    @JsonKey(name: 'is_active') bool? isActive,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'total_sales') required int totalSales,
    @JsonKey(name: 'total_revenue', fromJson: _parseStringToDouble) @Default(0.0) double totalRevenue,
    // Nested objects - игнорируем для простоты
    @JsonKey(includeFromJson: false, includeToJson: false) Map<String, dynamic>? template,
    @JsonKey(includeFromJson: false, includeToJson: false) Map<String, dynamic>? warehouse,
    @JsonKey(includeFromJson: false, includeToJson: false) Map<String, dynamic>? attributes,
  }) = _PopularProductModel;

  factory PopularProductModel.fromJson(Map<String, dynamic> json) =>
      _$PopularProductModelFromJson(json);
}

/// Парсер строки в double
double _parseStringToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Парсер nullable строки в double
double? _parseNullableStringToDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Ответ API для популярных товаров
@freezed
class PopularProductsResponse with _$PopularProductsResponse {
  const factory PopularProductsResponse({
    required bool success,
    required List<PopularProductModel> data,
  }) = _PopularProductsResponse;

  factory PopularProductsResponse.fromJson(Map<String, dynamic> json) =>
      _$PopularProductsResponseFromJson(json);
}


