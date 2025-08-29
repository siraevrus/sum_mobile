import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/companies/data/repositories/companies_repository_impl.dart';
import 'package:sum_warehouse/shared/models/company_model.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';

part 'companies_provider.g.dart';

/// Provider для списка компаний
@riverpod
class CompaniesList extends _$CompaniesList {
  @override
  FutureOr<List<CompanyModel>> build({
    String? search,
    bool? isActive,
    bool showArchived = false,
    int page = 1,
    int perPage = 15,
  }) {
    return _loadCompanies(
      search: search, 
      isActive: isActive, 
      showArchived: showArchived,
      page: page, 
      perPage: perPage
    );
  }
  
  Future<List<CompanyModel>> _loadCompanies({
    String? search,
    bool? isActive,
    bool showArchived = false,
    int page = 1,
    int perPage = 15,
  }) async {
    final repository = await ref.read(companiesRepositoryProvider.future);
    final companies = await repository.getCompanies(
      search: search,
      isActive: isActive,
      showArchived: showArchived,
      page: page,
      perPage: perPage,
    );
    
    return companies;
  }
  
  /// Обновить список с текущими параметрами
  Future<void> refresh() async {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _loadCompanies(
        search: null,
        isActive: null,
        showArchived: false,
        page: 1,
        perPage: 15,
      ));
    }
  }
  
  /// Создать компанию
  Future<CompanyModel?> createCompany(CompanyFormModel company) async {
    try {
      final repository = await ref.read(companiesRepositoryProvider.future);
      final newCompany = await repository.createCompany(company);
      
      // Обновляем список после создания
      await refresh();
      
      return newCompany;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Обновить компанию
  Future<CompanyModel?> updateCompany(int id, CompanyFormModel company) async {
    try {
      final repository = await ref.read(companiesRepositoryProvider.future);
      final updatedCompany = await repository.updateCompany(id, company);
      
      // Обновляем список после обновления
      await refresh();
      
      return updatedCompany;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Удалить компанию
  Future<bool> deleteCompany(int id) async {
    try {
      final repository = await ref.read(companiesRepositoryProvider.future);
      await repository.deleteCompany(id);
      
      // Обновляем список после удаления
      await refresh();
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Provider для получения компании по ID
@riverpod
class CompanyDetails extends _$CompanyDetails {
  @override
  FutureOr<CompanyModel> build(int companyId) {
    return _loadCompanyDetails(companyId);
  }
  
  Future<CompanyModel> _loadCompanyDetails(int companyId) async {
    final repository = await ref.read(companiesRepositoryProvider.future);
    final company = await repository.getCompanyById(companyId);
    
    // Проверяем, что компания не архивирована
    if (company.isArchived) {
      throw Exception('Компания архивирована');
    }
    
    return company;
  }
  
  /// Обновить данные компании
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadCompanyDetails(companyId));
  }
}

/// Provider для статистики компаний
@riverpod
class CompaniesStats extends _$CompaniesStats {
  @override
  FutureOr<List<CompanyStatsModel>> build() {
    return _loadCompaniesStats();
  }
  
  Future<List<CompanyStatsModel>> _loadCompaniesStats() async {
    final repository = await ref.read(companiesRepositoryProvider.future);
    return await repository.getCompaniesStats();
  }
  
  /// Обновить статистику
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadCompaniesStats());
  }
}

/// Provider для складов компании
@riverpod
class CompanyWarehouses extends _$CompanyWarehouses {
  @override
  FutureOr<List<WarehouseModel>> build(int companyId) {
    return _loadCompanyWarehouses(companyId);
  }
  
  Future<List<WarehouseModel>> _loadCompanyWarehouses(int companyId) async {
    final repository = await ref.read(companiesRepositoryProvider.future);
    return await repository.getCompanyWarehouses(companyId);
  }
  
  /// Обновить список складов
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadCompanyWarehouses(companyId));
  }
}

/// Provider для состояния формы компании
@riverpod
class CompanyFormState extends _$CompanyFormState {
  @override
  CompanyFormModel build() {
    return const CompanyFormModel();
  }
  
  /// Обновить поле формы
  void updateField({
    String? name,
    String? inn,
    String? kpp,
    String? legalAddress,
    String? actualAddress,
    String? phone,
    String? email,
    String? website,
    String? contactPerson,
    bool? isActive,
  }) {
    state = state.copyWith(
      name: name ?? state.name,
      inn: inn ?? state.inn,
      kpp: kpp ?? state.kpp,
      legalAddress: legalAddress ?? state.legalAddress,
      actualAddress: actualAddress ?? state.actualAddress,
      phone: phone ?? state.phone,
      email: email ?? state.email,
      website: website ?? state.website,
      contactPerson: contactPerson ?? state.contactPerson,
      isActive: isActive ?? state.isActive,
    );
  }
  
  /// Загрузить данные существующей компании в форму
  void loadCompanyData(CompanyModel company) {
    state = CompanyFormModelX.fromCompany(company);
  }
  
  /// Очистить форму
  void clearForm() {
    state = const CompanyFormModel();
  }
  
  /// Валидация формы
  Map<String, String> validateForm() {
    final errors = <String, String>{};
    
    if (state.name == null || state.name!.trim().isEmpty) {
      errors['name'] = 'Название компании обязательно';
    }
    
    if (state.inn == null || state.inn!.trim().isEmpty) {
      errors['inn'] = 'ИНН обязателен';
    } else if (!_isValidINN(state.inn!)) {
      errors['inn'] = 'Некорректный ИНН';
    }
    
    if (state.kpp == null || state.kpp!.trim().isEmpty) {
      errors['kpp'] = 'КПП обязателен';
    } else if (!_isValidKPP(state.kpp!)) {
      errors['kpp'] = 'Некорректный КПП';
    }
    
    if (state.legalAddress == null || state.legalAddress!.trim().isEmpty) {
      errors['legalAddress'] = 'Юридический адрес обязателен';
    }
    
    if (state.email != null && state.email!.isNotEmpty && !_isValidEmail(state.email!)) {
      errors['email'] = 'Некорректный email';
    }
    
    return errors;
  }
  
  /// Валидация ИНН (упрощенная)
  bool _isValidINN(String inn) {
    if (inn.length != 10 && inn.length != 12) return false;
    return RegExp(r'^\d+$').hasMatch(inn);
  }
  
  /// Валидация КПП (упрощенная)
  bool _isValidKPP(String kpp) {
    if (kpp.length != 9) return false;
    return RegExp(r'^\d+$').hasMatch(kpp);
  }
  
  /// Валидация email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
