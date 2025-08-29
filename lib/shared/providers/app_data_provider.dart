import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/products/data/datasources/product_template_remote_datasource.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/features/products/data/models/product_template_model.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';

part 'app_data_provider.g.dart';

/// Провайдер для загрузки всех шаблонов товаров (для dropdown'ов)
@riverpod
class AllProductTemplates extends _$AllProductTemplates {
  @override
  Future<List<ProductTemplateModel>> build() async {
    return _loadAllTemplates();
  }

  Future<List<ProductTemplateModel>> _loadAllTemplates() async {
    try {
      final dataSource = ref.read(productTemplateRemoteDataSourceProvider);
      final response = await dataSource.getProductTemplates(
        isActive: true,
        perPage: 100, // Загружаем много шаблонов
      );
      return response.data;
    } catch (e) {
      print('⚠️ Ошибка загрузки шаблонов товаров: $e');
      return [];
    }
  }

  /// Обновить список шаблонов
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadAllTemplates());
  }
}

/// Провайдер для загрузки всех складов (для dropdown'ов)
@riverpod
class AllWarehouses extends _$AllWarehouses {
  @override
  Future<List<WarehouseModel>> build() async {
    return _loadAllWarehouses();
  }

  Future<List<WarehouseModel>> _loadAllWarehouses() async {
    try {
      final dataSource = ref.read(warehousesRemoteDataSourceProvider);
      final response = await dataSource.getWarehouses(
        isActive: true,
        perPage: 100, // Загружаем много складов
      );
      return response.data;
    } catch (e) {
      print('⚠️ Ошибка загрузки складов: $e');
      return [];
    }
  }

  /// Обновить список складов
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadAllWarehouses());
  }
}

/// Провайдер для предзагрузки всех необходимых данных при старте приложения
@riverpod
class AppDataPreloader extends _$AppDataPreloader {
  @override
  Future<bool> build() async {
    print('🔄 Предзагрузка данных приложения...');
    
    // Запускаем загрузку всех необходимых данных параллельно
    await Future.wait([
      ref.read(allProductTemplatesProvider.future),
      ref.read(allWarehousesProvider.future),
    ]);
    
    print('✅ Предзагрузка данных завершена');
    return true;
  }

  /// Обновить все данные
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    
    // Обновляем все провайдеры
    ref.invalidate(allProductTemplatesProvider);
    ref.invalidate(allWarehousesProvider);
    
    state = await AsyncValue.guard(() => build());
  }
}


