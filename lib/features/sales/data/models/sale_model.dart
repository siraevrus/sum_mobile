import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale_model.freezed.dart';
part 'sale_model.g.dart';

/// Модель продажи согласно новому API
@freezed
class SaleModel with _$SaleModel {
  const factory SaleModel({
    required int id,
    @JsonKey(name: 'product_id') required int productId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'sale_number') String? saleNumber,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'customer_phone') String? customerPhone,
    @JsonKey(name: 'customer_email') String? customerEmail,
    @JsonKey(name: 'customer_address') String? customerAddress,
    @JsonKey(name: 'quantity', fromJson: _parseToDouble) required double quantity,
    @JsonKey(name: 'unit_price', fromJson: _parseToDouble) required double unitPrice,
    @JsonKey(name: 'total_price', fromJson: _parseToDouble) required double totalPrice,
    @JsonKey(name: 'vat_rate', fromJson: _parseToDouble) @Default(20.0) double vatRate,
    @JsonKey(name: 'vat_amount', fromJson: _parseToDouble) @Default(0.0) double vatAmount,
    @JsonKey(name: 'price_without_vat', fromJson: _parseToDouble) @Default(0.0) double priceWithoutVat,
    @Default('RUB') String currency,
    @JsonKey(name: 'exchange_rate', fromJson: _parseToDouble) @Default(1.0) double exchangeRate,
    @JsonKey(name: 'cash_amount', fromJson: _parseToDouble) @Default(0.0) double cashAmount,
    @JsonKey(name: 'nocash_amount', fromJson: _parseToDouble) @Default(0.0) double nocashAmount,
    @JsonKey(name: 'payment_method') @Default('mixed') String paymentMethod,
    @JsonKey(name: 'payment_status') @Default('pending') String paymentStatus,
    @JsonKey(name: 'invoice_number') String? invoiceNumber,
    @JsonKey(name: 'reason_cancellation') String? reasonCancellation,
    String? notes,
    @JsonKey(name: 'sale_date') String? saleDate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    // Связанные объекты
    ProductInfo? product,
    WarehouseInfo? warehouse,
    UserInfo? user,
  }) = _SaleModel;

  factory SaleModel.fromJson(Map<String, dynamic> json) =>
      _$SaleModelFromJson(json);
}

/// Модель информации о товаре
@freezed
class ProductInfo with _$ProductInfo {
  const factory ProductInfo({
    required int id,
    required String name,
    String? description,
    String? unit,
  }) = _ProductInfo;

  factory ProductInfo.fromJson(Map<String, dynamic> json) =>
      _$ProductInfoFromJson(json);
}

/// Модель информации о складе
@freezed
class WarehouseInfo with _$WarehouseInfo {
  const factory WarehouseInfo({
    required int id,
    required String name,
    String? address,
  }) = _WarehouseInfo;

  factory WarehouseInfo.fromJson(Map<String, dynamic> json) =>
      _$WarehouseInfoFromJson(json);
}

/// Модель информации о пользователе
@freezed
class UserInfo with _$UserInfo {
  const factory UserInfo({
    required int id,
    required String name,
    String? email,
  }) = _UserInfo;

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);
}

/// Запрос создания продажи
@freezed
class CreateSaleRequest with _$CreateSaleRequest {
  const factory CreateSaleRequest({
    @JsonKey(name: 'sale_number') String? saleNumber,
    @JsonKey(name: 'product_id') required int productId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'customer_name') required String customerName,
    required double quantity,
    @JsonKey(name: 'unit_price') required double unitPrice,
    @JsonKey(name: 'cash_amount') required double cashAmount,
    @JsonKey(name: 'nocash_amount') required double nocashAmount,
    required String currency,
    @JsonKey(name: 'exchange_rate') required double exchangeRate,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    @JsonKey(name: 'payment_status') @Default('paid') String paymentStatus,
    @JsonKey(name: 'sale_date') required String saleDate,
    @JsonKey(name: 'customer_phone') String? customerPhone,
    @JsonKey(name: 'customer_email') String? customerEmail,
    @JsonKey(name: 'customer_address') String? customerAddress,
    @JsonKey(name: 'composite_product_key') String? compositeProductKey,
  }) = _CreateSaleRequest;

  factory CreateSaleRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateSaleRequestFromJson(json);
}

/// Запрос обновления продажи
@freezed
class UpdateSaleRequest with _$UpdateSaleRequest {
  const factory UpdateSaleRequest({
    @JsonKey(name: 'product_id') int? productId,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    double? quantity,
    @JsonKey(name: 'cash_amount') double? cashAmount,
    @JsonKey(name: 'nocash_amount') double? nocashAmount,
    String? currency,
    @JsonKey(name: 'exchange_rate') double? exchangeRate,
    @JsonKey(name: 'sale_date') String? saleDate,
  }) = _UpdateSaleRequest;

  factory UpdateSaleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateSaleRequestFromJson(json);
}

/// Фильтры для поиска продаж
@freezed
class SaleFilters with _$SaleFilters {
  const factory SaleFilters({
    String? search,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'payment_status') String? paymentStatus,
    @JsonKey(name: 'date_from') String? dateFrom,
    @JsonKey(name: 'date_to') String? dateTo,
  }) = _SaleFilters;

  factory SaleFilters.fromJson(Map<String, dynamic> json) =>
      _$SaleFiltersFromJson(json);
}

/// Парсер строки в double с улучшенной обработкой null
double _parseToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) {
    if (value.isEmpty) return 0.0;
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}
