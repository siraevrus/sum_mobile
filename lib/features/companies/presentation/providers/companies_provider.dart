import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/core/models/api_response_model.dart';
import 'package:sum_warehouse/features/companies/data/datasources/companies_remote_datasource.dart';
import 'package:sum_warehouse/features/companies/data/repositories/companies_repository_impl.dart';
import 'package:sum_warehouse/features/companies/domain/repositories/companies_repository.dart';
import 'package:sum_warehouse/shared/models/company_model.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';

// Provider для remote datasource
final companiesRemoteDataSourceProvider = Provider<CompaniesRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return CompaniesRemoteDataSourceImpl(dio: dio);
});

// Provider для repository
final companiesRepositoryProvider = Provider<CompaniesRepository>((ref) {
  final remoteDataSource = ref.watch(companiesRemoteDataSourceProvider);
  return CompaniesRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Provider для состояния списка компаний
final companiesProvider = StateNotifierProvider<CompaniesNotifier, AsyncValue<List<CompanyModel>>>((ref) {
  final repository = ref.watch(companiesRepositoryProvider);
  return CompaniesNotifier(repository);
});

// Provider для списка компаний с фильтрами
final companiesListProvider = FutureProvider.family<List<CompanyModel>, ({String? search, bool showArchived})>((ref, params) async {
  final repository = ref.watch(companiesRepositoryProvider);
  final companies = await repository.getCompanies(
    search: params.search,
    isActive: params.showArchived ? null : true, // Если showArchived = false, показываем только активные
    showArchived: params.showArchived,
  );
  return companies;
});

// Provider для детальной информации о компании
final companyDetailsProvider = StateNotifierProvider.family<CompanyDetailsNotifier, AsyncValue<CompanyModel>, int>((ref, id) {
  final repository = ref.watch(companiesRepositoryProvider);
  return CompanyDetailsNotifier(repository, id);
});

// Provider для статистики компаний
final companiesStatsProvider = StateNotifierProvider<CompaniesStatsNotifier, AsyncValue<CompanyStats>>((ref) {
  final repository = ref.watch(companiesRepositoryProvider);
  return CompaniesStatsNotifier(repository);
});

// Provider для статистики отдельной компании
final companyStatsProvider = StateNotifierProvider.family<CompanyStatsNotifier, AsyncValue<SingleCompanyStats>, int>((ref, id) {
  final repository = ref.watch(companiesRepositoryProvider);
  return CompanyStatsNotifier(repository, id);
});

// Provider для складов компании
final companyWarehousesProvider = FutureProvider.family<List<WarehouseModel>, int>((ref, companyId) async {
  final repository = ref.watch(companiesRepositoryProvider);
  return await repository.getCompanyWarehouses(companyId);
});

class CompaniesNotifier extends StateNotifier<AsyncValue<List<CompanyModel>>> {
  final CompaniesRepository _repository;

  CompaniesNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadCompanies({
    String? search,
    bool? isActive,
    bool showArchived = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final companies = await _repository.getCompanies(
      search: search,
      isActive: isActive,
      showArchived: showArchived,
      );
      state = AsyncValue.data(companies);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createCompany(CompanyFormModel company) async {
    try {
      await _repository.createCompany(company);
      // Перезагружаем список после создания
      await loadCompanies();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateCompany(int id, CompanyFormModel company) async {
    try {
      await _repository.updateCompany(id, company);
      // Перезагружаем список после обновления
      await loadCompanies();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteCompany(int id) async {
    try {
      await _repository.deleteCompany(id);
      // Перезагружаем список после удаления
      await loadCompanies();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> archiveCompany(int id) async {
    try {
      await _repository.archiveCompany(id);
      // Перезагружаем список после архивирования
      await loadCompanies();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> restoreCompany(int id) async {
    try {
      await _repository.restoreCompany(id);
      // Перезагружаем список после восстановления
      await loadCompanies();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadCompanies();
  }
}

class CompanyDetailsNotifier extends StateNotifier<AsyncValue<CompanyModel>> {
  final CompaniesRepository _repository;
  final int _id;

  CompanyDetailsNotifier(this._repository, this._id) : super(const AsyncValue.loading());

  Future<void> loadCompany() async {
    state = const AsyncValue.loading();
    try {
      final company = await _repository.getCompanyById(_id);
      state = AsyncValue.data(company);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> archiveCompany() async {
    try {
      await _repository.archiveCompany(_id);
      // Перезагружаем данные компании после архивирования
      await loadCompany();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> restoreCompany() async {
    try {
      await _repository.restoreCompany(_id);
      // Перезагружаем данные компании после восстановления
      await loadCompany();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadCompany();
  }
}

class CompaniesStatsNotifier extends StateNotifier<AsyncValue<CompanyStats>> {
  final CompaniesRepository _repository;

  CompaniesStatsNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      final statsList = await _repository.getCompaniesStats();
      if (statsList.isNotEmpty) {
        // Преобразуем SingleCompanyStats обратно в CompanyStats
        final stats = statsList.first;
        final companyStats = CompanyStats(
          total: 1,
          active: 1,
          inactive: 0,
          totalWarehouses: stats.warehousesCount,
          totalEmployees: stats.employeesCount,
        );
        state = AsyncValue.data(companyStats);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadStats();
  }
}

class CompanyStatsNotifier extends StateNotifier<AsyncValue<SingleCompanyStats>> {
  final CompaniesRepository _repository;
  final int? _id;

  CompanyStatsNotifier(this._repository, [this._id]) : super(const AsyncValue.loading());

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      if (_id != null) {
        // Пока возвращаем пустую статистику, так как метод не реализован
        final stats = SingleCompanyStats(
          companyId: _id!,
          companyName: 'Компания $_id',
          warehousesCount: 0,
          employeesCount: 0,
          activeEmployees: 0,
          totalProducts: 0,
          monthlyRevenue: 0.0,
          monthlyOrders: 0,
          status: 'active',
        );
        state = AsyncValue.data(stats);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadStats();
  }
}
