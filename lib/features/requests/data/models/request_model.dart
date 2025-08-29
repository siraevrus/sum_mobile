import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/features/requests/domain/entities/request_entity.dart';

part 'request_model.freezed.dart';
part 'request_model.g.dart';

/// Модель запроса для работы с API
@freezed
class RequestModel with _$RequestModel {
  const factory RequestModel({
    required int id,
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    required String title,
    required String description,
    required double quantity,
    required String priority, // Сериализуем как строку
    required String status, // Сериализуем как строку
    @JsonKey(name: 'admin_notes') String? adminNotes,
    @JsonKey(name: 'processed_at') DateTime? processedAt,
    @JsonKey(name: 'processed_by_user_id') int? processedByUserId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    
    // Связанные объекты
    UserModel? user,
    WarehouseModel? warehouse,
    @JsonKey(name: 'product_template') ProductTemplateModel? productTemplate,
    @JsonKey(name: 'processed_by') UserModel? processedBy,
  }) = _RequestModel;

  const RequestModel._();

  /// Создание из JSON
  factory RequestModel.fromJson(Map<String, dynamic> json) =>
      _$RequestModelFromJson(json);

  /// Получить приоритет как enum
  RequestPriority get requestPriority => RequestPriorityExtension.fromCode(priority);

  /// Получить статус как enum
  RequestStatus get requestStatus => RequestStatusExtension.fromCode(status);

  /// Конвертация в Entity
  RequestEntity toEntity() {
    return RequestEntity(
      id: id,
      userId: userId,
      warehouseId: warehouseId,
      productTemplateId: productTemplateId,
      title: title,
      description: description,
      quantity: quantity,
      priority: requestPriority,
      status: requestStatus,
      adminNotes: adminNotes,
      processedAt: processedAt,
      processedByUserId: processedByUserId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      user: user?.toEntity(),
      warehouse: warehouse?.toEntity(),
      productTemplate: productTemplate?.toEntity(),
      processedBy: processedBy?.toEntity(),
    );
  }

  /// Создание из Entity
  factory RequestModel.fromEntity(RequestEntity entity) {
    return RequestModel(
      id: entity.id,
      userId: entity.userId,
      warehouseId: entity.warehouseId,
      productTemplateId: entity.productTemplateId,
      title: entity.title,
      description: entity.description,
      quantity: entity.quantity,
      priority: entity.priority.code,
      status: entity.status.code,
      adminNotes: entity.adminNotes,
      processedAt: entity.processedAt,
      processedByUserId: entity.processedByUserId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      user: entity.user != null ? UserModel.fromEntity(entity.user!) : null,
      warehouse: entity.warehouse != null ? WarehouseModel.fromEntity(entity.warehouse!) : null,
      productTemplate: entity.productTemplate != null ? ProductTemplateModel.fromEntity(entity.productTemplate!) : null,
      processedBy: entity.processedBy != null ? UserModel.fromEntity(entity.processedBy!) : null,
    );
  }
}

/// Модель для создания/обновления запроса
@freezed
class CreateRequestModel with _$CreateRequestModel {
  const factory CreateRequestModel({
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    required String title,
    required String description,
    required double quantity,
    required String priority,
    String? status,
  }) = _CreateRequestModel;

  /// Создание из JSON
  factory CreateRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreateRequestModelFromJson(json);
}

/// Модель пользователя (временная)
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required int id,
    required String name,
    required String email,
    String? role,
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
      role: role,
    );
  }

  /// Создание из Entity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      role: entity.role,
    );
  }
}

/// Модель склада (временная)
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

/// Модель шаблона товара (временная)
@freezed
class ProductTemplateModel with _$ProductTemplateModel {
  const factory ProductTemplateModel({
    required int id,
    required String name,
    required String unit,
    String? description,
  }) = _ProductTemplateModel;

  const ProductTemplateModel._();

  /// Создание из JSON
  factory ProductTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$ProductTemplateModelFromJson(json);

  /// Конвертация в Entity
  ProductTemplateEntity toEntity() {
    return ProductTemplateEntity(
      id: id,
      name: name,
      unit: unit,
      description: description,
    );
  }

  /// Создание из Entity
  factory ProductTemplateModel.fromEntity(ProductTemplateEntity entity) {
    return ProductTemplateModel(
      id: entity.id,
      name: entity.name,
      unit: entity.unit,
      description: entity.description,
    );
  }
}

/// Модель фильтров для поиска запросов
@freezed
class RequestFiltersModel with _$RequestFiltersModel {
  const factory RequestFiltersModel({
    String? status,
    String? priority,
    @JsonKey(name: 'user_id') int? userId,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'product_template_id') int? productTemplateId,
    String? sort,
    String? order,
    @JsonKey(name: 'per_page') @Default(15) int perPage,
    @Default(1) int page,
  }) = _RequestFiltersModel;

  /// Создание из JSON
  factory RequestFiltersModel.fromJson(Map<String, dynamic> json) =>
      _$RequestFiltersModelFromJson(json);

  /// Конвертация в query параметры
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (userId != null) params['user_id'] = userId;
    if (warehouseId != null) params['warehouse_id'] = warehouseId;
    if (productTemplateId != null) params['product_template_id'] = productTemplateId;
    if (sort != null) params['sort'] = sort;
    if (order != null) params['order'] = order;
    params['per_page'] = perPage;
    params['page'] = page;
    
    return params;
  }
}
