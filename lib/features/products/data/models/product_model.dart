import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/features/products/domain/entities/product_entity.dart';
import 'package:sum_warehouse/features/products/data/models/product_template_model.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

/// Модель товара для работы с API
@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    required int id,
    required String name,
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'creator_id') required int creatorId,
    required double quantity,
    String? description,
    String? producer,
    @Default({}) Map<String, dynamic> attributes,
    @JsonKey(name: 'calculated_value') double? calculatedValue,
    @JsonKey(name: 'qr_code') String? qrCode,
    @JsonKey(name: 'arrival_date') DateTime? arrivalDate,
    @JsonKey(name: 'expiry_date') DateTime? expiryDate,
    @Default(true) @JsonKey(name: 'is_active') bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    
    // Связанные объекты (приходят из API при детальном запросе)
    ProductTemplateModel? template,
    WarehouseModel? warehouse,
    UserModel? creator,
  }) = _ProductModel;

  const ProductModel._();

  /// Создание из JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  /// Конвертация в Entity
  ProductEntity toEntity() {
    return ProductEntity(
      id: id,
      name: name,
      productTemplateId: productTemplateId,
      warehouseId: warehouseId,
      creatorId: creatorId,
      quantity: quantity,
      description: description,
      producer: producer,
      attributes: attributes,
      calculatedValue: calculatedValue,
      qrCode: qrCode,
      arrivalDate: arrivalDate,
      expiryDate: expiryDate,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      template: template?.toEntity(),
      warehouse: warehouse?.toEntity(),
      creator: creator?.toEntity(),
    );
  }

  /// Создание из Entity
  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      productTemplateId: entity.productTemplateId,
      warehouseId: entity.warehouseId,
      creatorId: entity.creatorId,
      quantity: entity.quantity,
      description: entity.description,
      producer: entity.producer,
      attributes: entity.attributes,
      calculatedValue: entity.calculatedValue,
      qrCode: entity.qrCode,
      arrivalDate: entity.arrivalDate,
      expiryDate: entity.expiryDate,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      template: entity.template != null ? ProductTemplateModel.fromEntity(entity.template!) : null,
      warehouse: entity.warehouse != null ? WarehouseModel.fromEntity(entity.warehouse!) : null,
      creator: entity.creator != null ? UserModel.fromEntity(entity.creator!) : null,
    );
  }
}

/// Модель для создания/обновления товара
@freezed
class CreateProductModel with _$CreateProductModel {
  const factory CreateProductModel({
    required String name,
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    required double quantity,
    String? description,
    String? producer,
    @Default({}) Map<String, dynamic> attributes,
    @JsonKey(name: 'arrival_date') DateTime? arrivalDate,
    @JsonKey(name: 'expiry_date') DateTime? expiryDate,
    @Default(true) @JsonKey(name: 'is_active') bool isActive,
  }) = _CreateProductModel;

  /// Создание из JSON
  factory CreateProductModel.fromJson(Map<String, dynamic> json) =>
      _$CreateProductModelFromJson(json);
}

/// Модель склада (временная, пока не создан отдельный модуль)
@freezed
class WarehouseModel with _$WarehouseModel {
  const factory WarehouseModel({
    required int id,
    required String name,
    required String address,
    @JsonKey(name: 'company_id') required int companyId,
    @Default(true) @JsonKey(name: 'is_active') bool isActive,
  }) = _WarehouseModel;

  const WarehouseModel._();

  /// Создание из JSON
  factory WarehouseModel.fromJson(Map<String, dynamic> json) =>
      _$WarehouseModelFromJson(json);

  /// Конвертация в Entity
  WarehouseEntity toEntity() {
    return WarehouseEntity(
      id: id,
      name: name,
      address: address,
      companyId: companyId,
      isActive: isActive,
    );
  }

  /// Создание из Entity
  factory WarehouseModel.fromEntity(WarehouseEntity entity) {
    return WarehouseModel(
      id: entity.id,
      name: entity.name,
      address: entity.address,
      companyId: entity.companyId,
      isActive: entity.isActive,
    );
  }
}

/// Модель пользователя (временная, пока используем из auth)
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required int id,
    required String name,
    required String email,
  }) = _UserModel;

  const UserModel._();

  /// Создание из JSON
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Конвертация в Entity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
    );
  }

  /// Создание из Entity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
    );
  }
}

/// Модель фильтров для поиска товаров
@freezed
class ProductFiltersModel with _$ProductFiltersModel {
  const factory ProductFiltersModel({
    String? search,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'template_id') int? templateId,
    String? producer,
    @JsonKey(name: 'in_stock') bool? inStock,
    @JsonKey(name: 'low_stock') bool? lowStock,
    bool? active,
    @JsonKey(name: 'per_page') @Default(15) int perPage,
    @Default(1) int page,
  }) = _ProductFiltersModel;

  /// Создание из JSON
  factory ProductFiltersModel.fromJson(Map<String, dynamic> json) =>
      _$ProductFiltersModelFromJson(json);

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
    params['per_page'] = perPage;
    params['page'] = page;
    
    return params;
  }
}
