import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/companies/data/datasources/companies_remote_datasource.dart';
import 'package:sum_warehouse/features/companies/domain/repositories/companies_repository.dart';
import 'package:sum_warehouse/features/companies/presentation/providers/companies_provider.dart';
import 'package:sum_warehouse/shared/models/company_model.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';

part 'companies_repository_impl.g.dart';

/// Реализация репозитория компаний
class CompaniesRepositoryImpl implements CompaniesRepository {
  final CompaniesRemoteDataSource _remoteDataSource;
  
  CompaniesRepositoryImpl({required CompaniesRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;
  
  @override
  Future<List<CompanyModel>> getCompanies({
    String? search,
    bool? isActive,
    bool showArchived = false,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _remoteDataSource.getCompanies(
        queryParams: {
          if (search != null) 'search': search,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
          'page': page,
          'per_page': perPage,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<CompanyModel> getCompanyById(int id) async {
    try {
      return await _remoteDataSource.getCompany(id);
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
      
      final request = company.toCreateRequest();
      return await _remoteDataSource.createCompany(request);
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<CompanyModel> updateCompany(int id, CompanyFormModel company) async {
    try {
      final request = company.toUpdateRequest();
      final updated = await _remoteDataSource.updateCompany(id, request);
      return updated;
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<void> deleteCompany(int id) async {
    try {
      await _remoteDataSource.deleteCompany(id);
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<List<CompanyStatsModel>> getCompaniesStats() async {
    try {
      final stats = await _remoteDataSource.getCompaniesStats();
      // Возвращаем список с одной статистикой
      return [SingleCompanyStatsX.fromStats(stats)];
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<List<WarehouseModel>> getCompanyWarehouses(int companyId) async {
    try {
      // Пока возвращаем пустой список, так как метод не реализован в datasource
      return [];
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
  return CompaniesRepositoryImpl(remoteDataSource: remoteDataSource);
}

/// Кастомное исключение валидации
class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
  
  @override
  String toString() => 'ValidationException: $message';
}
