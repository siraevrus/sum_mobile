import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/sales/data/datasources/sales_remote_datasource.dart';
import 'package:sum_warehouse/features/sales/data/repositories/sales_repository_impl.dart';
import 'package:sum_warehouse/features/sales/data/models/sale_model.dart';
import 'package:sum_warehouse/features/sales/domain/repositories/sales_repository.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';

part 'sales_providers.g.dart';

/// Провайдер репозитория продаж
@riverpod
SalesRepository salesRepository(SalesRepositoryRef ref) {
  final remoteDataSource = ref.watch(salesRemoteDataSourceProvider);
  return SalesRepositoryImpl(remoteDataSource);
}

/// Провайдер для получения списка продаж
@riverpod
Future<PaginatedResponse<SaleModel>> salesList(
  SalesListRef ref, {
  int page = 1,
  int perPage = 15,
  SaleFilters? filters,
}) async {
  final repository = ref.watch(salesRepositoryProvider);
  
  // Используем фильтры из провайдера фильтров если не переданы напрямую
  final filtersToUse = filters ?? ref.watch(salesFiltersNotifierProvider);
  
  return await repository.getSales(
    page: page,
    perPage: perPage,
    filters: filtersToUse,
  );
}

/// Провайдер для получения отдельной продажи
@riverpod
Future<SaleModel> saleDetail(SaleDetailRef ref, int id) async {
  final repository = ref.watch(salesRepositoryProvider);
  return await repository.getSale(id);
}

/// Провайдер для создания продажи
@riverpod
class CreateSale extends _$CreateSale {
  @override
  FutureOr<SaleModel?> build() {
    return null;
  }

  Future<SaleModel> create(CreateSaleRequest request) async {
    state = const AsyncValue.loading();
    final repository = ref.watch(salesRepositoryProvider);
    
    final result = await AsyncValue.guard(() => repository.createSale(request));
    state = result;
    
    if (result.hasValue) {
      // Не инвалидируем здесь - это будет сделано в UI
      return result.value!;
    } else {
      throw result.error!;
    }
  }
}

/// Провайдер для обновления продажи
@riverpod
class UpdateSale extends _$UpdateSale {
  @override
  FutureOr<SaleModel?> build() {
    return null;
  }

  Future<SaleModel> updateSale(int id, UpdateSaleRequest request) async {
    state = const AsyncValue.loading();
    final repository = ref.watch(salesRepositoryProvider);
    
    final result = await AsyncValue.guard(() => repository.updateSale(id, request));
    state = result;
    
    if (result.hasValue) {
      // Не инвалидируем здесь - это будет сделано в UI
      return result.value!;
    } else {
      throw result.error!;
    }
  }
}

/// Провайдер для удаления продажи
@riverpod
class DeleteSale extends _$DeleteSale {
  @override
  FutureOr<bool> build() {
    return false;
  }

  Future<void> delete(int id) async {
    state = const AsyncValue.loading();
    final repository = ref.watch(salesRepositoryProvider);
    
    try {
      await repository.deleteSale(id);
      state = const AsyncValue.data(true);
      // Обновляем список продаж после удаления
      ref.invalidate(salesListProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      throw e;
    }
  }
}

/// Провайдер для отмены продажи
@riverpod
class CancelSale extends _$CancelSale {
  @override
  FutureOr<bool> build() {
    return false;
  }

  Future<void> cancel(int id) async {
    state = const AsyncValue.loading();
    final repository = ref.watch(salesRepositoryProvider);

    try {
      print('🔵 CancelSaleProvider: Начинаем отмену продажи ID: $id');
      await repository.cancelSale(id);
      print('🔵 CancelSaleProvider: Продажа успешно отменена');
      
      // Устанавливаем успешное состояние
      // НЕ инвалидируем провайдеры здесь - это делается в UI после получения результата
      state = const AsyncValue.data(true);
      print('🔵 CancelSaleProvider: Состояние установлено в success');
    } catch (e, stackTrace) {
      print('🔴 CancelSaleProvider: Ошибка отмены продажи: $e');
      print('🔴 CancelSaleProvider: Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

/// Провайдер для обработки продажи
@riverpod
class ProcessSale extends _$ProcessSale {
  @override
  FutureOr<bool> build() {
    return false;
  }

  Future<void> process(int id) async {
    state = const AsyncValue.loading();
    final repository = ref.watch(salesRepositoryProvider);
    
    try {
      await repository.processSale(id);
      state = const AsyncValue.data(true);
      // Обновляем список продаж и детали после обработки
      ref.invalidate(salesListProvider);
      ref.invalidate(saleDetailProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      throw e;
    }
  }
}

/// Провайдер для фильтров продаж
@riverpod
class SalesFiltersNotifier extends _$SalesFiltersNotifier {
  @override
  SaleFilters build() {
    return const SaleFilters();
  }

  void updateFilters(SaleFilters newFilters) {
    state = newFilters;
    // Обновляем список продаж с новыми фильтрами
    ref.invalidate(salesListProvider);
  }

  void clearFilters() {
    state = const SaleFilters();
    // Обновляем список продаж без фильтров
    ref.invalidate(salesListProvider);
  }
}
