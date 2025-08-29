import 'package:freezed_annotation/freezed_annotation.dart';

part 'sales_model.freezed.dart';
part 'sales_model.g.dart';

/// Основная модель продажи по API - согласно OpenAPI спецификации
@freezed
class SaleModel with _$SaleModel {
  const factory SaleModel({
    required int id,
    @JsonKey(name: 'product_id') required dynamic productId, // Составной ключ - может приходить как int или String
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'user_id') required int userId,
    required dynamic quantity,
    @JsonKey(name: 'cash_amount') required dynamic cashAmount,
    @JsonKey(name: 'nocash_amount') required dynamic nocashAmount,
    @JsonKey(name: 'total_price') required dynamic totalPrice,
    @JsonKey(name: 'unit_price') required dynamic unitPrice,
    @JsonKey(name: 'price_without_vat') required dynamic priceWithoutVat,
    @JsonKey(name: 'vat_amount') required dynamic vatAmount,
    @JsonKey(name: 'vat_rate') required dynamic vatRate,
    required String currency,
    @JsonKey(name: 'exchange_rate') required dynamic exchangeRate,
    @JsonKey(name: 'payment_status') required String paymentStatus,
    @JsonKey(name: 'delivery_status') required String deliveryStatus,
    @JsonKey(name: 'sale_date') required DateTime saleDate,
    String? notes,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    
    // Дополнительные поля для совместимости с UI (могут отсутствовать в API)
    @JsonKey(name: 'sale_number') String? saleNumber,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'customer_phone') String? customerPhone,
    @JsonKey(name: 'customer_email') String? customerEmail,
    @JsonKey(name: 'customer_address') String? customerAddress,
    
    // Связанные объекты (заглушки)
    Map<String, dynamic>? product,
    Map<String, dynamic>? warehouse,
    Map<String, dynamic>? user,
  }) = _SaleModel;

  const SaleModel._();

  factory SaleModel.fromJson(Map<String, dynamic> json) => 
      _$SaleModelFromJson(json);

  /// Возвращает productId как строку безопасно
  String get productIdAsString => productId == null ? '' : productId.toString();

  /// Helpers to get numeric fields as double safely
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  double get quantityValue => _toDouble(quantity);
  double get cashAmountValue => _toDouble(cashAmount);
  double get nocashAmountValue => _toDouble(nocashAmount);
  double get totalPriceValue => _toDouble(totalPrice);
  double get unitPriceValue => _toDouble(unitPrice);
  double get priceWithoutVatValue => _toDouble(priceWithoutVat);
  double get vatAmountValue => _toDouble(vatAmount);
  double get vatRateValue => _toDouble(vatRate);
  double get exchangeRateValue => _toDouble(exchangeRate);
}

/// Модель создания продажи - согласно OpenAPI спецификации
@freezed
class CreateSaleRequest with _$CreateSaleRequest {
  const factory CreateSaleRequest({
    @JsonKey(name: 'product_id') String? productId, // Составной ключ: template_id|warehouse_id|producer|encoded_name
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    required double quantity,
    @JsonKey(name: 'cash_amount') required double cashAmount, // ОБЯЗАТЕЛЬНОЕ поле из API
    @JsonKey(name: 'nocash_amount') required double nocashAmount, // ОБЯЗАТЕЛЬНОЕ поле из API
    @JsonKey(name: 'total_price') double? totalPrice, // Автоматически рассчитывается
    @JsonKey(name: 'unit_price') double? unitPrice, // Автоматически рассчитывается
    @JsonKey(name: 'payment_method') String? paymentMethod,
    @JsonKey(name: 'customer_name') String? customerName,
    @JsonKey(name: 'price_without_vat') double? priceWithoutVat, // Автоматически рассчитывается
    @JsonKey(name: 'vat_amount') double? vatAmount, // Автоматически рассчитывается
    @JsonKey(name: 'vat_rate') @Default(20.0) double vatRate, // По умолчанию 20%
    @JsonKey(name: 'currency') @Default('RUB') String currency, // По умолчанию RUB
    @JsonKey(name: 'exchange_rate') @Default(1.0) double exchangeRate, // По умолчанию 1.0
    @JsonKey(name: 'payment_status') @Default('pending') String paymentStatus, // По умолчанию pending
    @JsonKey(name: 'delivery_status') @Default('pending') String deliveryStatus, // По умолчанию pending
    @JsonKey(name: 'sale_date') required DateTime saleDate,
    String? notes,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _CreateSaleRequest;

  factory CreateSaleRequest.fromJson(Map<String, dynamic> json) => 
      _$CreateSaleRequestFromJson(json);
}

/// Модель обновления продажи - согласно OpenAPI спецификации
@freezed
class UpdateSaleRequest with _$UpdateSaleRequest {
  const factory UpdateSaleRequest({
    @JsonKey(name: 'product_id') String? productId, // Составной ключ
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    double? quantity,
    @JsonKey(name: 'cash_amount') double? cashAmount, // ОБЯЗАТЕЛЬНОЕ поле API
    @JsonKey(name: 'nocash_amount') double? nocashAmount, // ОБЯЗАТЕЛЬНОЕ поле API
    @JsonKey(name: 'total_price') double? totalPrice,
    @JsonKey(name: 'unit_price') double? unitPrice,
    @JsonKey(name: 'price_without_vat') double? priceWithoutVat,
    @JsonKey(name: 'vat_amount') double? vatAmount,
    @JsonKey(name: 'vat_rate') double? vatRate,
    @JsonKey(name: 'currency') String? currency,
    @JsonKey(name: 'exchange_rate') double? exchangeRate,
    @JsonKey(name: 'payment_status') String? paymentStatus,
    @JsonKey(name: 'delivery_status') String? deliveryStatus,
    @JsonKey(name: 'sale_date') DateTime? saleDate,
    String? notes,
    @JsonKey(name: 'is_active') bool? isActive,
  }) = _UpdateSaleRequest;

  factory UpdateSaleRequest.fromJson(Map<String, dynamic> json) => 
      _$UpdateSaleRequestFromJson(json);
}

/// Модель статистики продаж
@freezed
class SalesStats with _$SalesStats {
  const factory SalesStats({
    @JsonKey(name: 'total_sales') required int totalSales,
    @JsonKey(name: 'paid_sales') required int paidSales,
    @JsonKey(name: 'pending_payments') required int pendingPayments,
    @JsonKey(name: 'today_sales') required int todaySales,
    @JsonKey(name: 'month_revenue') required double monthRevenue,
    @JsonKey(name: 'total_revenue') required double totalRevenue,
    @JsonKey(name: 'total_quantity') required double totalQuantity,
    @JsonKey(name: 'average_sale') required double averageSale,
    @JsonKey(name: 'in_delivery') required int inDelivery,
  }) = _SalesStats;

  factory SalesStats.fromJson(Map<String, dynamic> json) => 
      _$SalesStatsFromJson(json);
}

/// Модель фильтров продаж
@freezed
class SalesFilters with _$SalesFilters {
  const factory SalesFilters({
    String? search,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'payment_status') String? paymentStatus,
    @JsonKey(name: 'delivery_status') String? deliveryStatus,
    @JsonKey(name: 'payment_method') String? paymentMethod,
    @JsonKey(name: 'date_from') DateTime? dateFrom,
    @JsonKey(name: 'date_to') DateTime? dateTo,
    bool? active,
    @JsonKey(name: 'per_page') @Default(15) int perPage,
    @Default(1) int page,
  }) = _SalesFilters;

  const SalesFilters._();

  factory SalesFilters.fromJson(Map<String, dynamic> json) => 
      _$SalesFiltersFromJson(json);
      
  /// Конвертация в query параметры
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (warehouseId != null) params['warehouse_id'] = warehouseId;
    if (paymentStatus != null) params['payment_status'] = paymentStatus;
    if (deliveryStatus != null) params['delivery_status'] = deliveryStatus;
    if (paymentMethod != null) params['payment_method'] = paymentMethod;
    if (dateFrom != null) {
      params['date_from'] = dateFrom!.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      params['date_to'] = dateTo!.toIso8601String().split('T')[0];
    }
    if (active != null) params['active'] = active! ? 1 : 0;
    params['per_page'] = perPage;
    params['page'] = page;
    
    return params;
  }
}

/// Модель статистики продаж (из admin_stats)
@freezed
class SalesStatsModel with _$SalesStatsModel {
  const factory SalesStatsModel({
    @JsonKey(name: 'total_sales') @Default(0) int totalSales,
    @JsonKey(name: 'paid_sales') @Default(0) int paidSales,
    @JsonKey(name: 'pending_payments') @Default(0) int pendingPayments,
    @JsonKey(name: 'today_sales') @Default(0) int todaySales,
    @JsonKey(name: 'month_revenue') @Default(0.0) double monthRevenue,
    @JsonKey(name: 'total_revenue') @Default(0.0) double totalRevenue,
    @JsonKey(name: 'total_quantity') @Default(0.0) double totalQuantity,
    @JsonKey(name: 'average_sale') @Default(0.0) double averageSale,
    @JsonKey(name: 'in_delivery') @Default(0) int inDelivery,
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
