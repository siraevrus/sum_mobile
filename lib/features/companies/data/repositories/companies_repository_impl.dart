import 'package:riverpod_annotation/riverpod_annotation.dart';
// import 'package:sum_warehouse/features/companies/data/datasources/companies_remote_datasource.dart';
import 'package:sum_warehouse/features/companies/domain/repositories/companies_repository.dart';
import 'package:sum_warehouse/shared/models/company_model.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';

part 'companies_repository_impl.g.dart';

/// Реализация репозитория компаний
class CompaniesRepositoryImpl implements CompaniesRepository {
  final CompaniesRemoteDataSource _remoteDataSource;
  
  CompaniesRepositoryImpl(this._remoteDataSource);
  
  @override
  Future<List<CompanyModel>> getCompanies({
    String? search,
    bool? isActive,
    bool showArchived = false,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      return await _remoteDataSource.getCompanies(
        search: search,
        isActive: isActive,
        showArchived: showArchived,
        page: page,
        perPage: perPage,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<CompanyModel> getCompanyById(int id) async {
    try {
      return await _remoteDataSource.getCompanyById(id);
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<CompanyModel> createCompany(CompanyFormModel company) async {
    try {
      // Валидация данных
      if (company.name == null || company.name!.trim().isEmpty) {
        throw ValidationException('Название компании обязательно');
      }
      
      if (company.inn == null || company.inn!.trim().isEmpty) {
        throw ValidationException('ИНН обязателен');
      }
      
      if (!_isValidINN(company.inn!)) {
        throw ValidationException('Некорректный ИНН');
      }
      
      return await _remoteDataSource.createCompany(company);
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<CompanyModel> updateCompany(int id, CompanyFormModel company) async {
    try {
      final updated = await _remoteDataSource.updateCompany(id, company);
      return updated;
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<void> deleteCompany(int id) async {
    try {
      return await _remoteDataSource.archiveCompany(id);
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<List<CompanyStatsModel>> getCompaniesStats() async {
    try {
      return await _remoteDataSource.getCompaniesStats();
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<List<WarehouseModel>> getCompanyWarehouses(int companyId) async {
    try {
      return await _remoteDataSource.getCompanyWarehouses(companyId);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Валидация ИНН
  bool _isValidINN(String inn) {
    // Упрощенная валидация ИНН
    if (inn.length != 10 && inn.length != 12) return false;
    if (!RegExp(r'^\d+$').hasMatch(inn)) return false;
    
    // Полная валидация контрольных сумм ИНН здесь не реализована
    // В production версии должна быть полная валидация
    return true;
  }
}

/// Provider для репозитория компаний
@riverpod
Future<CompaniesRepository> companiesRepository(CompaniesRepositoryRef ref) async {
  final remoteDataSource = ref.watch(companiesRemoteDataSourceProvider);
  return CompaniesRepositoryImpl(remoteDataSource);
}

/// Кастомное исключение валидации
class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
  
  @override
  String toString() => 'ValidationException: $message';
}
