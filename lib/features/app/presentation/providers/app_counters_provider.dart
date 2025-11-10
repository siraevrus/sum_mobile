import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/app/data/datasources/app_counters_remote_datasource.dart';

part 'app_counters_provider.g.dart';

/// Модель счетчиков новых записей
class NewCounters {
  final int? receipts;
  final int? productsInTransit;
  final int? sales;

  const NewCounters({
    this.receipts,
    this.productsInTransit,
    this.sales,
  });

  NewCounters copyWith({
    int? receipts,
    int? productsInTransit,
    int? sales,
  }) {
    return NewCounters(
      receipts: receipts ?? this.receipts,
      productsInTransit: productsInTransit ?? this.productsInTransit,
      sales: sales ?? this.sales,
    );
  }
}

/// Провайдер для счетчиков новых записей
@Riverpod(keepAlive: true)
class AppCounters extends _$AppCounters {
  // Сохраняем последнее загруженное значение для мгновенного отображения
  NewCounters? _lastLoadedValue;

  @override
  Future<NewCounters> build() async {
    // При инициализации загружаем счетчики
    // keepAlive: true - провайдер не удаляется при отсутствии слушателей
    // Это позволяет сохранять последние значения для мгновенного отображения
    final counters = await _loadCounters();
    _lastLoadedValue = counters;
    return counters;
  }

  /// Загрузить все счетчики (параллельно)
  Future<NewCounters> _loadCounters() async {
    final dataSource = ref.read(appCountersRemoteDataSourceProvider);
    
    try {
      // Загружаем все счетчики параллельно для ускорения
      final results = await Future.wait([
        _getReceiptsCount(dataSource),
        _getProductsInTransitCount(dataSource),
        _getSalesCount(dataSource),
      ]);

      return NewCounters(
        receipts: results[0],
        productsInTransit: results[1],
        sales: results[2],
      );
    } catch (e) {
      // При ошибке возвращаем null для всех счетчиков
      return const NewCounters();
    }
  }

  /// Получить счетчик поступлений
  Future<int?> _getReceiptsCount(AppCountersRemoteDataSource dataSource) async {
    try {
      final response = await dataSource.getReceiptsNewCount();
      if (response['success'] == true && response['data'] != null) {
        return response['data']['new_count'] as int?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить счетчик товаров в пути
  Future<int?> _getProductsInTransitCount(AppCountersRemoteDataSource dataSource) async {
    try {
      final response = await dataSource.getProductsInTransitNewCount();
      if (response['success'] == true && response['data'] != null) {
        return response['data']['new_count'] as int?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить счетчик продаж
  Future<int?> _getSalesCount(AppCountersRemoteDataSource dataSource) async {
    try {
      final response = await dataSource.getSalesNewCount();
      if (response['success'] == true && response['data'] != null) {
        return response['data']['new_count'] as int?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Обновить счетчики
  Future<void> refresh() async {
    // Сохраняем текущее значение перед обновлением
    final currentValue = state.value ?? _lastLoadedValue;
    // Устанавливаем состояние loading
    state = const AsyncValue.loading();
    // Загружаем новые данные
    try {
      final newCounters = await _loadCounters();
      _lastLoadedValue = newCounters;
      state = AsyncValue.data(newCounters);
    } catch (e, stackTrace) {
      // При ошибке сохраняем предыдущее значение, если оно было
      if (currentValue != null) {
        _lastLoadedValue = currentValue;
        state = AsyncValue.data(currentValue);
      } else {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  /// Получить последнее загруженное значение (для использования в UI)
  NewCounters? getLastLoadedValue() => _lastLoadedValue;

  /// Отметить просмотр раздела
  Future<void> markSectionViewed(String section) async {
    final dataSource = ref.read(appCountersRemoteDataSourceProvider);
    try {
      await dataSource.markSectionViewed(section);
      // Обновляем счетчики после отметки просмотра
      await refresh();
    } catch (e) {
      // Игнорируем ошибки при отметке просмотра
    }
  }

  /// Отметить открытие приложения
  Future<void> markAppOpened() async {
    final dataSource = ref.read(appCountersRemoteDataSourceProvider);
    try {
      await dataSource.markAppOpened();
      // Обновляем счетчики после отметки открытия
      await refresh();
    } catch (e) {
      // Игнорируем ошибки при отметке открытия
    }
  }
}

