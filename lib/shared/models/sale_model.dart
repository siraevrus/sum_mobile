import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/shared/models/common_references.dart';

part 'sale_model.freezed.dart';
part 'sale_model.g.dart';

/// Модель продажи
@freezed
class SaleModel with _$SaleModel {
  const factory SaleModel({
    int? id,
    @JsonKey(name: 'sale_number') String? saleNumber,
    @JsonKey(name: 'product_id') int? productId,
    @JsonKey(name: 'composite_product_key') String? compositeProductKey,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'user_id') int? userId,
    @JsonKey(fromJson: _parseStringToDouble) double? quantity,
    @JsonKey(name: 'cash_amount', fromJson: _parseStringToDouble) double? cashAmount,
    @JsonKey(name: 'nocash_amount', fromJson: _parseStringToDouble) double? nocashAmount,
    @JsonKey(name: 'total_price', fromJson: _parseStringToDouble) double? totalPrice,
    @JsonKey(name: 'unit_price', fromJson: _parseStringToDouble) double? unitPrice,
    @JsonKey(name: 'price_without_vat', fromJson: _parseStringToDouble) double? priceWithoutVat,
    @JsonKey(name: 'vat_amount', fromJson: _parseStringToDouble) double? vatAmount,
    @JsonKey(name: 'vat_rate', fromJson: _parseStringToDouble) double? vatRate,
    String? currency,
    @JsonKey(name: 'exchange_rate', fromJson: _parseStringToDouble) double? exchangeRate,
    @JsonKey(name: 'payment_status') String? paymentStatus,
    @JsonKey(name: 'delivery_status') String? deliveryStatus,
    @JsonKey(name: 'sale_date') required String saleDate,
    @JsonKey(name: 'delivery_date') String? deliveryDate,
    @JsonKey(name: 'invoice_number') String? invoiceNumber,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'customer_phone') String? customerPhone,
    @JsonKey(name: 'customer_email') String? customerEmail,
    @JsonKey(name: 'customer_address') String? customerAddress,
    String? notes,
    @JsonKey(name: 'is_active') bool? isActive,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    // Nested objects from API
    ProductReference? product,
    WarehouseReference? warehouse,
    UserReference? user,
  }) = _SaleModel;

  factory SaleModel.fromJson(Map<String, dynamic> json) =>
      _$SaleModelFromJson(json);
}

/// Парсер строки в double для продаж
double _parseStringToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Парсер строки в DateTime для продаж
DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}

/// Парсер строки в DateTime для временных меток
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}

/// Преобразование DateTime в строку для JSON
String _dateToJson(DateTime date) {
  return date.toIso8601String().split('T')[0];
}

// References moved to common_references.dart

/// Запрос создания продажи
@freezed
class CreateSaleRequest with _$CreateSaleRequest {
  const factory CreateSaleRequest({
    @JsonKey(name: 'product_id') required int productId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    required double quantity,
    @JsonKey(name: 'cash_amount') required double cashAmount,
    @JsonKey(name: 'nocash_amount') required double nocashAmount,
    @JsonKey(name: 'total_price') double? totalPrice,
    @JsonKey(name: 'unit_price') double? unitPrice,
    @JsonKey(name: 'price_without_vat') double? priceWithoutVat,
    @JsonKey(name: 'vat_amount') double? vatAmount,
    @JsonKey(name: 'vat_rate') double? vatRate,
    String? currency,
    @JsonKey(name: 'exchange_rate') double? exchangeRate,
    @JsonKey(name: 'payment_status') String? paymentStatus,
    @JsonKey(name: 'delivery_status') String? deliveryStatus,
    @JsonKey(name: 'sale_date') required String saleDate,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'customer_phone') String? customerPhone,
    @JsonKey(name: 'customer_email') String? customerEmail,
    @JsonKey(name: 'customer_address') String? customerAddress,
    String? notes,
    @JsonKey(name: 'is_active') bool? isActive,
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
    @JsonKey(name: 'total_price') double? totalPrice,
    @JsonKey(name: 'unit_price') double? unitPrice,
    @JsonKey(name: 'price_without_vat') double? priceWithoutVat,
    @JsonKey(name: 'vat_amount') double? vatAmount,
    @JsonKey(name: 'vat_rate') double? vatRate,
    String? currency,
    @JsonKey(name: 'exchange_rate') double? exchangeRate,
    @JsonKey(name: 'payment_status') String? paymentStatus,
    @JsonKey(name: 'delivery_status') String? deliveryStatus,
    @JsonKey(name: 'sale_date') String? saleDate,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'customer_phone') String? customerPhone,
    @JsonKey(name: 'customer_email') String? customerEmail,
    @JsonKey(name: 'customer_address') String? customerAddress,
    String? notes,
    @JsonKey(name: 'is_active') bool? isActive,
  }) = _UpdateSaleRequest;

  factory UpdateSaleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateSaleRequestFromJson(json);
}

/// Статистика продаж согласно API схеме
@freezed
class SalesStatsModel with _$SalesStatsModel {
  const factory SalesStatsModel({
    @JsonKey(name: 'total_sales') required int totalSales,
    @JsonKey(name: 'paid_sales') required int paidSales,
    @JsonKey(name: 'pending_payments') required int pendingPayments,
    @JsonKey(name: 'today_sales') required int todaySales,
    @JsonKey(name: 'month_revenue') required double monthRevenue,
    @JsonKey(name: 'total_revenue') required double totalRevenue,
    @JsonKey(name: 'total_quantity') required double totalQuantity,
    @JsonKey(name: 'average_sale') required double averageSale,
    @JsonKey(name: 'in_delivery') required int inDelivery,
  }) = _SalesStatsModel;

  factory SalesStatsModel.fromJson(Map<String, dynamic> json) =>
      _$SalesStatsModelFromJson(json);
}

/// Ответ API для статистики продаж
@freezed
class SalesStatsResponse with _$SalesStatsResponse {
  const factory SalesStatsResponse({
    required bool success,
    required SalesStatsModel data,
  }) = _SalesStatsResponse;

  factory SalesStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$SalesStatsResponseFromJson(json);
}
