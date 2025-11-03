import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Основная модель пользователя по API
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required int id,
    required String name,
    String? username,
    required String email,
    required String role,
    @JsonKey(name: 'company_id') int? companyId,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'is_blocked') bool? isBlocked,
    String? phone,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    
    // Связанные объекты
    CompanyModel? company,
    WarehouseModel? warehouse,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
}

/// Модель ответа аутентификации
@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required UserModel user,
    required String token,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => 
      _$AuthResponseFromJson(json);
}

/// Модель запроса логина
@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) => 
      _$LoginRequestFromJson(json);
}

/// Модель запроса регистрации
@freezed
class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String name,
    required String email,
    required String password,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => 
      _$RegisterRequestFromJson(json);
}

/// Модель обновления профиля
@freezed
class UpdateProfileRequest with _$UpdateProfileRequest {
  const factory UpdateProfileRequest({
    String? name,
    String? username,
    String? email,
    String? phone,
    String? password,
    @JsonKey(name: 'password_confirmation') String? passwordConfirmation,
    @JsonKey(name: 'current_password') String? currentPassword,
    @JsonKey(name: 'new_password') String? newPassword,
  }) = _UpdateProfileRequest;

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) => 
      _$UpdateProfileRequestFromJson(json);
}

/// Модель создания пользователя (для админа)
@freezed
class CreateUserRequest with _$CreateUserRequest {
  const factory CreateUserRequest({
    required String name,
    required String email,
    required String password,
    required String role,
    String? username,
    String? phone,
    @JsonKey(name: 'company_id') int? companyId,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'is_blocked') @Default(false) bool isBlocked,
  }) = _CreateUserRequest;

  factory CreateUserRequest.fromJson(Map<String, dynamic> json) => 
      _$CreateUserRequestFromJson(json);
}

/// Модель обновления пользователя (для админа)
@freezed
class UpdateUserRequest with _$UpdateUserRequest {
  const factory UpdateUserRequest({
    String? name,
    String? username,
    String? email,
    String? phone,
    String? password,
    String? role,
    @JsonKey(name: 'company_id') int? companyId,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'is_blocked') bool? isBlocked,
  }) = _UpdateUserRequest;

  factory UpdateUserRequest.fromJson(Map<String, dynamic> json) => 
      _$UpdateUserRequestFromJson(json);
}

/// Модель статистики пользователей
@freezed
class UserStats with _$UserStats {
  const factory UserStats({
    required int total,
    required int active,
    required int blocked,
    @JsonKey(name: 'by_role') required Map<String, int> byRole,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) => 
      _$UserStatsFromJson(json);
}

/// Модель фильтров пользователей
@freezed  
class UserFilters with _$UserFilters {
  const factory UserFilters({
    String? role,
    @JsonKey(name: 'company_id') int? companyId,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'is_blocked') bool? isBlocked,
    String? search,
    String? sort,
    String? order,
    @JsonKey(name: 'per_page') @Default(15) int perPage,
    @Default(1) int page,
  }) = _UserFilters;

  factory UserFilters.fromJson(Map<String, dynamic> json) => 
      _$UserFiltersFromJson(json);
}

/// Расширение для UserFilters
extension UserFiltersX on UserFilters {
  /// Конвертация в query параметры
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (this.role != null) params['role'] = this.role;
    if (this.companyId != null) params['company_id'] = this.companyId;
    if (this.warehouseId != null) params['warehouse_id'] = this.warehouseId;
    if (this.isBlocked != null) params['is_blocked'] = this.isBlocked! ? 1 : 0;
    if (this.search != null && this.search!.isNotEmpty) params['search'] = this.search;
    if (this.sort != null) params['sort'] = this.sort;
    if (this.order != null) params['order'] = this.order;
    params['per_page'] = this.perPage;
    params['page'] = this.page;
    
    return params;
  }
}

// Временные заглушки для компании и склада в пользователе
@freezed
class CompanyModel with _$CompanyModel {
  const factory CompanyModel({
    required int id,
    String? name,
  }) = _CompanyModel;

  factory CompanyModel.fromJson(Map<String, dynamic> json) => 
      _$CompanyModelFromJson(json);
}

@freezed
class WarehouseModel with _$WarehouseModel {
  const factory WarehouseModel({
    required int id,
    String? name,
  }) = _WarehouseModel;

  factory WarehouseModel.fromJson(Map<String, dynamic> json) => 
      _$WarehouseModelFromJson(json);
}