import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_models.freezed.dart';
part 'inventory_models.g.dart';

/// Парсер для ID (может быть строкой или числом)
String _parseId(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is int) return value.toString();
  if (value is double) return value.toString();
  return value.toString();
}

/// Парсер для количества/объема (может быть строкой или числом)
String _parseStringFromNumber(dynamic value) {
  if (value == null) return '0';
  if (value is String) return value;
  if (value is int) return value.toString();
  if (value is double) return value.toString();
  return value.toString();
}

/// Парсер для int ID (может быть строкой или числом)
int? _parseIntId(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  return null;
}

/// Парсер для строк (обрабатывает null)
String? _parseNullableString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

/// Парсер для обязательных строк (обрабатывает null как пустую строку)
String _parseRequiredString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

/// Парсер для bool значений (обрабатывает null как false)
bool _parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is int) return value != 0;
  return false;
}

/// Модель остатков согласно новому API /api/stocks
@freezed
class InventoryStockModel with _$InventoryStockModel {
  const factory InventoryStockModel({
    @JsonKey(fromJson: _parseId) required String id, // Составной ключ "37_13_1"
    @JsonKey(name: 'product_template_id', fromJson: _parseIntId) int? productTemplateId,
    @JsonKey(name: 'warehouse_id', fromJson: _parseIntId) int? warehouseId,
    @JsonKey(name: 'producer_id', fromJson: _parseIntId) int? producerId,
    @JsonKey(name: 'total_quantity', fromJson: _parseStringFromNumber) required String totalQuantity,
    @JsonKey(name: 'total_volume', fromJson: _parseStringFromNumber) required String totalVolume,
    required String name,
    required String status,
    @JsonKey(name: 'is_active', fromJson: _parseBool) required bool isActive,
    @JsonKey(name: 'correction_status', fromJson: _parseNullableString) String? correctionStatus,
    
    // Связанные объекты
    @JsonKey(name: 'product_template') InventoryProductTemplateModel? productTemplate,
    InventoryWarehouseModel? warehouse,
    InventoryProducerModel? producer,
  }) = _InventoryStockModel;

  factory InventoryStockModel.fromJson(Map<String, dynamic> json) => 
      _$InventoryStockModelFromJson(json);
}

/// Модель производителя
@freezed
class InventoryProducerModel with _$InventoryProducerModel {
  const factory InventoryProducerModel({
    required int id,
    @JsonKey(fromJson: _parseRequiredString) required String name,
    @JsonKey(fromJson: _parseNullableString) String? region,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'products_count') int? productsCount,
  }) = _InventoryProducerModel;

  factory InventoryProducerModel.fromJson(Map<String, dynamic> json) => 
      _$InventoryProducerModelFromJson(json);
}

/// Модель склада
@freezed
class InventoryWarehouseModel with _$InventoryWarehouseModel {
  const factory InventoryWarehouseModel({
    required int id,
    @JsonKey(fromJson: _parseRequiredString) required String name,
    @JsonKey(fromJson: _parseRequiredString) required String address,
    @JsonKey(name: 'company_id') required int companyId,
    @JsonKey(name: 'is_active', fromJson: _parseBool) required bool isActive,
    InventoryCompanyModel? company,
    List<dynamic>? employees,
  }) = _InventoryWarehouseModel;

  factory InventoryWarehouseModel.fromJson(Map<String, dynamic> json) => 
      _$InventoryWarehouseModelFromJson(json);
}

/// Модель компании
@freezed
class InventoryCompanyModel with _$InventoryCompanyModel {
  const factory InventoryCompanyModel({
    required int id,
    @JsonKey(fromJson: _parseRequiredString) required String name,
    @JsonKey(name: 'legal_address', fromJson: _parseRequiredString) required String legalAddress,
    @JsonKey(name: 'postal_address', fromJson: _parseRequiredString) required String postalAddress,
    @JsonKey(name: 'phone_fax', fromJson: _parseRequiredString) required String phoneFax,
    @JsonKey(name: 'general_director', fromJson: _parseRequiredString) required String generalDirector,
    @JsonKey(fromJson: _parseRequiredString) required String email,
    @JsonKey(fromJson: _parseRequiredString) required String inn,
    @JsonKey(fromJson: _parseRequiredString) required String kpp,
    @JsonKey(fromJson: _parseRequiredString) required String ogrn,
    @JsonKey(fromJson: _parseRequiredString) required String bank,
    @JsonKey(name: 'account_number', fromJson: _parseRequiredString) required String accountNumber,
    @JsonKey(name: 'correspondent_account', fromJson: _parseRequiredString) required String correspondentAccount,
    @JsonKey(fromJson: _parseRequiredString) required String bik,
    @JsonKey(name: 'employees_count') int? employeesCount,
    @JsonKey(name: 'warehouses_count') int? warehousesCount,
    @JsonKey(name: 'is_archived') bool? isArchived,
  }) = _InventoryCompanyModel;

  factory InventoryCompanyModel.fromJson(Map<String, dynamic> json) => 
      _$InventoryCompanyModelFromJson(json);
}

/// Модель шаблона товара для остатков
@freezed
class InventoryProductTemplateModel with _$InventoryProductTemplateModel {
  const factory InventoryProductTemplateModel({
    required int id,
    @JsonKey(fromJson: _parseRequiredString) required String name,
    @JsonKey(fromJson: _parseNullableString) String? description,
    @JsonKey(fromJson: _parseNullableString) String? formula,
    @JsonKey(fromJson: _parseNullableString) String? unit,
    @JsonKey(name: 'is_active', fromJson: _parseBool) required bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _InventoryProductTemplateModel;

  factory InventoryProductTemplateModel.fromJson(Map<String, dynamic> json) => 
      _$InventoryProductTemplateModelFromJson(json);
}

/// Ответ API для остатков
@freezed
class InventoryStocksResponse with _$InventoryStocksResponse {
  const factory InventoryStocksResponse({
    required bool success,
    required List<InventoryStockModel> data,
    InventoryPaginationModel? pagination,
  }) = _InventoryStocksResponse;

  factory InventoryStocksResponse.fromJson(Map<String, dynamic> json) => 
      _$InventoryStocksResponseFromJson(json);
}

/// Ответ API для производителей (простой список)
class InventoryProducersResponse {
  final List<InventoryProducerModel> data;
  
  const InventoryProducersResponse({
    required this.data,
  });

  factory InventoryProducersResponse.fromJson(dynamic json) {
    // Производители возвращаются как простой массив
    if (json is List) {
      return InventoryProducersResponse(
        data: json.map((e) => InventoryProducerModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }
    
    // Если это объект с полем data
    if (json is Map<String, dynamic> && json.containsKey('data')) {
      return InventoryProducersResponse(
        data: (json['data'] as List).map((e) => InventoryProducerModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }
    
    throw Exception('Неожиданный формат ответа для производителей');
  }
}

/// Ответ API для складов
@freezed
class InventoryWarehousesResponse with _$InventoryWarehousesResponse {
  const factory InventoryWarehousesResponse({
    required bool success,
    required List<InventoryWarehouseModel> data,
    InventoryPaginationModel? pagination,
  }) = _InventoryWarehousesResponse;

  factory InventoryWarehousesResponse.fromJson(Map<String, dynamic> json) => 
      _$InventoryWarehousesResponseFromJson(json);
}

/// Ответ API для компаний
@freezed
class InventoryCompaniesResponse with _$InventoryCompaniesResponse {
  const factory InventoryCompaniesResponse({
    required bool success,
    required List<InventoryCompanyModel> data,
    InventoryPaginationModel? pagination,
  }) = _InventoryCompaniesResponse;

  factory InventoryCompaniesResponse.fromJson(Map<String, dynamic> json) => 
      _$InventoryCompaniesResponseFromJson(json);
}

/// Модель пагинации
@freezed
class InventoryPaginationModel with _$InventoryPaginationModel {
  const factory InventoryPaginationModel({
    @JsonKey(name: 'current_page') required int currentPage,
    @JsonKey(name: 'last_page') required int lastPage,
    @JsonKey(name: 'per_page') required int perPage,
    required int total,
  }) = _InventoryPaginationModel;

  factory InventoryPaginationModel.fromJson(Map<String, dynamic> json) => 
      _$InventoryPaginationModelFromJson(json);
}
