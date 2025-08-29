import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';

part 'company_model.freezed.dart';
part 'company_model.g.dart';

/// Основная модель компании согласно API спецификации
@freezed
class CompanyModel with _$CompanyModel {
  const factory CompanyModel({
    required int id,
    required String name,
    @JsonKey(name: 'legal_address') String? legalAddress,
    @JsonKey(name: 'postal_address') String? postalAddress,
    @JsonKey(name: 'phone_fax') String? phoneFax,
    @JsonKey(name: 'general_director') String? generalDirector,
    String? email,
    String? inn,
    String? kpp,
    String? ogrn,
    String? bank,
    @JsonKey(name: 'account_number') String? accountNumber,
    @JsonKey(name: 'correspondent_account') String? correspondentAccount,
    String? bik,
    @JsonKey(name: 'employees_count') int? employeesCount,
    @JsonKey(name: 'warehouses_count') int? warehousesCount,
    @JsonKey(name: 'is_archived') @Default(false) bool isArchived,
    @JsonKey(name: 'archived_at') DateTime? archivedAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _CompanyModel;

  factory CompanyModel.fromJson(Map<String, dynamic> json) => 
      _$CompanyModelFromJson(json);
}

/// Модель создания компании согласно API спецификации
@freezed
class CreateCompanyRequest with _$CreateCompanyRequest {
  const factory CreateCompanyRequest({
    required String name,
    @JsonKey(name: 'legal_address') String? legalAddress,
    @JsonKey(name: 'postal_address') String? postalAddress,
    @JsonKey(name: 'phone_fax') String? phoneFax,
    @JsonKey(name: 'general_director') String? generalDirector,
    String? email,
    String? inn,
    String? kpp,
    String? ogrn,
    String? bank,
    @JsonKey(name: 'account_number') String? accountNumber,
    @JsonKey(name: 'correspondent_account') String? correspondentAccount,
    String? bik,
    @JsonKey(name: 'employees_count') int? employeesCount,
    @JsonKey(name: 'warehouses_count') int? warehousesCount,
  }) = _CreateCompanyRequest;

  factory CreateCompanyRequest.fromJson(Map<String, dynamic> json) => 
      _$CreateCompanyRequestFromJson(json);
}

/// Модель обновления компании согласно API спецификации
@freezed
class UpdateCompanyRequest with _$UpdateCompanyRequest {
  const factory UpdateCompanyRequest({
    String? name,
    @JsonKey(name: 'legal_address') String? legalAddress,
    @JsonKey(name: 'postal_address') String? postalAddress,
    @JsonKey(name: 'phone_fax') String? phoneFax,
    @JsonKey(name: 'general_director') String? generalDirector,
    String? email,
    String? inn,
    String? kpp,
    String? ogrn,
    String? bank,
    @JsonKey(name: 'account_number') String? accountNumber,
    @JsonKey(name: 'correspondent_account') String? correspondentAccount,
    String? bik,
    @JsonKey(name: 'employees_count') int? employeesCount,
    @JsonKey(name: 'warehouses_count') int? warehousesCount,
  }) = _UpdateCompanyRequest;

  factory UpdateCompanyRequest.fromJson(Map<String, dynamic> json) => 
      _$UpdateCompanyRequestFromJson(json);
}

/// Модель статистики компаний
@freezed
class CompanyStats with _$CompanyStats {
  const factory CompanyStats({
    required int total,
    required int active,
    required int inactive,
    @JsonKey(name: 'total_warehouses') required int totalWarehouses,
    @JsonKey(name: 'total_employees') required int totalEmployees,
  }) = _CompanyStats;

  factory CompanyStats.fromJson(Map<String, dynamic> json) => 
      _$CompanyStatsFromJson(json);
}

/// Модель статистики отдельной компании
@freezed
class SingleCompanyStats with _$SingleCompanyStats {
  const factory SingleCompanyStats({
    @JsonKey(name: 'company_id') required int companyId,
    @JsonKey(name: 'company_name') required String companyName,
    @Default(0) @JsonKey(name: 'warehouses_count') int warehousesCount,
    @Default(0) @JsonKey(name: 'employees_count') int employeesCount,
    @Default(0) @JsonKey(name: 'active_employees') int activeEmployees,
    @Default(0) @JsonKey(name: 'total_products') int totalProducts,
    @Default(0.0) @JsonKey(name: 'monthly_revenue') double monthlyRevenue,
    @Default(0) @JsonKey(name: 'monthly_orders') int monthlyOrders,
    @Default('active') String status,
  }) = _SingleCompanyStats;

  factory SingleCompanyStats.fromJson(Map<String, dynamic> json) => 
      _$SingleCompanyStatsFromJson(json);
}

/// Псевдоним для обратной совместимости
typedef CompanyStatsModel = SingleCompanyStats;

/// Модель фильтров компаний
@freezed
class CompanyFilters with _$CompanyFilters {
  const factory CompanyFilters({
    @JsonKey(name: 'is_active') bool? isActive,
    String? search,
    String? sort,
    String? order,
    @JsonKey(name: 'per_page') @Default(15) int perPage,
    @Default(1) int page,
  }) = _CompanyFilters;

  factory CompanyFilters.fromJson(Map<String, dynamic> json) => 
      _$CompanyFiltersFromJson(json);
}

/// Расширение для методов CompanyFilters
extension CompanyFiltersX on CompanyFilters {
  /// Конвертация в query параметры
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (isActive != null) params['is_active'] = isActive! ? 1 : 0;
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (sort != null) params['sort'] = sort;
    if (order != null) params['order'] = order;
    params['per_page'] = perPage;
    params['page'] = page;
    
    return params;
  }
}

/// Модель для формы компании (локальное состояние)
@freezed
class CompanyFormModel with _$CompanyFormModel {
  const factory CompanyFormModel({
    String? name,
    String? inn,
    String? kpp,
    String? legalAddress,
    String? actualAddress,
    String? phone,
    String? email,
    String? website,
    String? contactPerson,
    String? ogrn,
    String? bank,
    String? accountNumber,
    String? correspondentAccount,
    String? bik,
    @Default(true) bool isActive,
  }) = _CompanyFormModel;

  factory CompanyFormModel.fromJson(Map<String, dynamic> json) => 
      _$CompanyFormModelFromJson(json);
}

/// Расширение для методов CompanyFormModel
extension CompanyFormModelX on CompanyFormModel {
  /// Создать из существующей компании
  static CompanyFormModel fromCompany(CompanyModel company) {
    return CompanyFormModel(
      name: company.name,
      inn: company.inn,
      kpp: company.kpp,
      legalAddress: company.legalAddress,
      actualAddress: company.postalAddress,
      phone: company.phoneFax,
      email: company.email,
      website: null, // Поле website больше не используется
      contactPerson: company.generalDirector,
      ogrn: company.ogrn,
      bank: company.bank,
      accountNumber: company.accountNumber,
      correspondentAccount: company.correspondentAccount,
      bik: company.bik,
      isActive: !company.isArchived, // Используем инверсию isArchived
    );
  }
  
  /// Конвертировать в запрос создания
  CreateCompanyRequest toCreateRequest() {
    return CreateCompanyRequest(
      name: name ?? '',
      inn: inn ?? '',
      kpp: kpp ?? '',
      legalAddress: legalAddress ?? '',
      postalAddress: actualAddress,
      phoneFax: phone,
      email: email,
      generalDirector: contactPerson,
      ogrn: ogrn,
      bank: bank,
      accountNumber: accountNumber,
      correspondentAccount: correspondentAccount,
      bik: bik,
    );
  }
  
  /// Конвертировать в запрос обновления
  UpdateCompanyRequest toUpdateRequest() {
    return UpdateCompanyRequest(
      name: name,
      inn: inn,
      kpp: kpp,
      legalAddress: legalAddress,
      postalAddress: actualAddress,
      phoneFax: phone,
      email: email,
      generalDirector: contactPerson,
      ogrn: ogrn,
      bank: bank,
      accountNumber: accountNumber,
      correspondentAccount: correspondentAccount,
      bik: bik,
    );
  }
}