import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/shared/models/dashboard_stats.dart';

part 'dashboard_remote_datasource.g.dart';

/// Remote data source для дашборда
abstract class DashboardRemoteDataSource {
  /// Получить общую статистику
  Future<DashboardStats> getDashboardStats();
  
  /// Получить статистику по складам
  Future<List<WarehouseStats>> getWarehousesStats();
  
  /// Получить данные для графика продаж
  Future<List<SalesChartData>> getSalesChartData({
    required DateTime startDate,
    required DateTime endDate,
  });
  
  /// Получить топ товары
  Future<List<TopProduct>> getTopProducts({int limit = 10});
  
  /// Получить недавние активности
  Future<List<RecentActivity>> getRecentActivities({int limit = 20});
}

/// Реализация remote data source для дашборда
class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio _dio;
  
  DashboardRemoteDataSourceImpl(this._dio);
  
  @override
  Future<DashboardStats> getDashboardStats() async {
    try {
      // Пытаемся получить агрегаты единым запросом
      try {
        print('🔵 Dashboard: Получение агрегатов через /dashboard/summary ...');
        final resp = await _dio.get('/dashboard/summary');
        final data = resp.data as Map<String, dynamic>;
        return DashboardStats(
          totalProducts: (data['products_total'] ?? 0) as int,
          lowStockProducts: 0,
          totalCompanies: (data['companies_active'] ?? 0) as int,
          activeCompanies: (data['companies_active'] ?? 0) as int,
          totalEmployees: (data['employees_active'] ?? 0) as int,
          activeEmployees: (data['employees_active'] ?? 0) as int,
          todayRequests: (data['requests_pending'] ?? 0) as int,
          completedTodayRequests: 0,
          todaySales: 0,
          monthlySales: 0,
          goodsInTransit: (data['products_in_transit'] ?? 0) as int,
          warehousesActive: (data['warehouses_active'] ?? 0) as int,
          lastUpdated: DateTime.now(),
        );
      } catch (_) {
        print('ℹ️ /dashboard/summary недоступен, используем существующие эндпоинты');
      }

      // Собираем статистику из разных эндпоинтов согласно текущей API
      print('🔵 Dashboard: Получение статистики товаров...');
      final productsResponse = await _dio.get('/products/stats');
      print('📥 Products response: ${productsResponse.data}');
      
      print('🔵 Dashboard: Получение статистики продаж...');
      final salesResponse = await _dio.get('/sales/stats');
      print('📥 Sales response: ${salesResponse.data}');
      
      print('🔵 Dashboard: Получение списка компаний...');
      final companiesResponse = await _dio.get('/companies', queryParameters: {
        'page': 1,
        'per_page': 15,
      });
      print('📥 Companies response: ${companiesResponse.data}');
      
      print('🔵 Dashboard: Получение списка пользователей...');
      final usersResponse = await _dio.get('/users');
      print('📥 Users response: ${usersResponse.data}');
      
      print('🔵 Dashboard: Получение товаров в пути...');
      Map<String, dynamic> goodsInTransitData;
      try {
        // Используем алиас из спеки `/products-in-transit`
        final goodsInTransitResponse = await _dio.get('/products-in-transit', queryParameters: {
          'page': 1,
          'per_page': 10,
        });
        print('📥 Products-in-transit response: ${goodsInTransitResponse.data}');
        final data = goodsInTransitResponse.data;
        if (data is Map<String, dynamic>) {
          goodsInTransitData = data;
        } else if (data is List) {
          goodsInTransitData = { 'data': data, 'meta': { 'total': data.length } };
        } else {
          goodsInTransitData = {'data': [], 'meta': {'total': 0}};
        }
      } catch (e) {
        print('⚠️ Ошибка `/products-in-transit`: $e, пытаемся через /receipts со статусом');
        try {
          final receiptsResp = await _dio.get('/receipts', queryParameters: {
            'status': 'in_transit',
            'page': 1,
            'per_page': 10,
          });
          final data = receiptsResp.data;
          if (data is Map<String, dynamic>) {
            goodsInTransitData = data;
          } else if (data is List) {
            goodsInTransitData = { 'data': data, 'meta': { 'total': data.length } };
          } else {
            goodsInTransitData = {'data': [], 'meta': {'total': 0}};
          }
        } catch (e2) {
          print('⚠️ Fallback тоже не сработал: $e2, используем 0');
          goodsInTransitData = {'data': [], 'meta': {'total': 0}};
        }
      }
      
      print('🔵 Dashboard: Получение запросов...');
      final requestsResponse = await _dio.get('/requests', queryParameters: {
        'page': 1,
        'per_page': 15,
      });
      print('📥 Requests response: ${requestsResponse.data}');
      
      // Парсим данные товаров
      final productsData = productsResponse.data is Map<String, dynamic> && productsResponse.data['success'] == true
          ? productsResponse.data['data']
          : productsResponse.data;
          
      // Парсим данные продаж  
      final salesData = salesResponse.data is Map<String, dynamic> && salesResponse.data['success'] == true
          ? salesResponse.data['data'] 
          : salesResponse.data;
      
      // Парсим данные компаний (с пагинацией)
      final companiesData = companiesResponse.data as Map<String, dynamic>;
      final totalCompanies = companiesData['pagination']?['total'] ?? 
          companiesData['meta']?['total'] ?? 0;
      final companiesItems = companiesData['data'] as List<dynamic>? ?? [];
      final activeCompanies = companiesItems.where((company) => 
        company['is_active'] == true || company['is_archived'] != true
      ).length;
      
      print('📈 Companies: total=$totalCompanies, active=$activeCompanies');
          
      // Парсим данные пользователей
      final usersData = usersResponse.data is Map<String, dynamic> && usersResponse.data['data'] != null
          ? usersResponse.data['data'] as List<dynamic>
          : usersResponse.data as List<dynamic>;
          
      // Парсим товары в пути (данные уже получены выше с обработкой ошибок)
      final goodsInTransitCount = goodsInTransitData['pagination']?['total'] ?? 
          goodsInTransitData['meta']?['total'] ?? 
          (goodsInTransitData['data'] as List<dynamic>?)?.length ?? 0;
      
      print('🚛 Goods in transit: count=$goodsInTransitCount');
      
      // Парсим запросы (с пагинацией)
      final requestsData = requestsResponse.data as Map<String, dynamic>;
      final totalRequests = requestsData['pagination']?['total'] ?? 
          requestsData['meta']?['total'] ?? 0;
      
      print('📝 Requests: total=$totalRequests');
      
      // Подсчитываем активных пользователей
      final totalEmployees = usersData.length;
      final activeEmployees = usersData.where((user) => 
        user['is_blocked'] != true
      ).length;
      
      // Получаем average_sale и округляем до целого числа
      final averageSaleValue = salesData['average_sale'];
      final averageSaleRounded = averageSaleValue is String 
          ? double.tryParse(averageSaleValue)?.round() ?? 0
          : (averageSaleValue as num?)?.round() ?? 0;
      
      print('📊 Dashboard Stats:');
      print('  - Товары: ${productsData['total_products']}');
      print('  - Компании: $totalCompanies (активных: $activeCompanies)');
      print('  - Сотрудники: $totalEmployees (активных: $activeEmployees)');
      print('  - Продажи (average_sale): $averageSaleRounded ₽');
      print('  - Товары в пути: $goodsInTransitCount');
      print('  - Запросы: $totalRequests');
      
      // Формируем общую статистику из доступных данных
      return DashboardStats(
        totalProducts: productsData['total_products'] ?? 0,
        lowStockProducts: productsData['low_stock'] ?? 0,
        totalCompanies: totalCompanies,
        activeCompanies: activeCompanies,
        totalEmployees: totalEmployees,
        activeEmployees: activeEmployees,
        todaySales: averageSaleRounded.toDouble(), // Используем average_sale как целое число
        monthlySales: (salesData['month_revenue'] ?? 0.0).toDouble(),
        goodsInTransit: goodsInTransitCount,
        todayRequests: totalRequests, // Добавляем запросы
        lastUpdated: DateTime.now(),
      );
    } on DioException catch (e) {
      print('🔴 Dashboard: Ошибка получения статистики: ${e.response?.statusCode} - ${e.message}');
      print('🔴 Response data: ${e.response?.data}');
      throw Exception('Нет данных статистики: ${e.message}');
    } catch (e) {
      print('🔴 Dashboard: Общая ошибка: $e');
      throw Exception('Ошибка обработки данных: $e');
    }
  }
  
  @override
  Future<List<WarehouseStats>> getWarehousesStats() async {
    try {
      // Получаем список складов из основного эндпоинта
      final response = await _dio.get('/warehouses');
      final warehousesData = response.data is Map<String, dynamic> && response.data['data'] != null
          ? response.data['data'] as List<dynamic>
          : response.data as List<dynamic>;
      
      // Преобразуем в статистику складов (пока что базовая реализация)
      return warehousesData.map((json) {
        final warehouse = json as Map<String, dynamic>;
        return WarehouseStats(
          warehouseId: warehouse['id'] ?? 0,
          warehouseName: warehouse['name'] ?? 'Неизвестный склад',
          location: warehouse['address'] ?? 'Неизвестно',
          totalProducts: 0, // Пока нет данных в API
          occupancyRate: 0.0,  // Пока нет данных в API
        );
      }).toList();
    } on DioException catch (e) {
      throw Exception('Нет данных о складах');
    }
  }
  
  @override
  Future<List<SalesChartData>> getSalesChartData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Используем основной эндпоинт продаж с фильтрами по дате
      final response = await _dio.get('/sales', queryParameters: {
        'date_from': startDate.toIso8601String().split('T')[0],
        'date_to': endDate.toIso8601String().split('T')[0],
        'per_page': 100, // Ограничиваем для графика
      });
      
      final salesData = response.data is Map<String, dynamic> && response.data['data'] != null
          ? response.data['data'] as List<dynamic>
          : response.data as List<dynamic>;
      
      // Группируем продажи по дням для графика
      final Map<String, double> dailySales = {};
      for (final sale in salesData) {
        final saleMap = sale as Map<String, dynamic>;
        final dateStr = saleMap['sale_date']?.toString().split('T')[0] ?? '';
        final amount = (saleMap['total_price'] ?? 0.0).toDouble();
        dailySales[dateStr] = (dailySales[dateStr] ?? 0.0) + amount;
      }
      
      return dailySales.entries.map((entry) => SalesChartData(
        period: entry.key,
        amount: entry.value,
        quantity: 0, // TODO: добавить количество если будет в API
      )).toList();
    } on DioException catch (e) {
      throw Exception('Нет данных о продажах');
    }
  }
  
  @override
  Future<List<TopProduct>> getTopProducts({int limit = 10}) async {
    try {
      // Используем реальный эндпоинт популярных товаров из API
      final response = await _dio.get('/products/popular');
      final responseData = response.data is Map<String, dynamic> && response.data['data'] != null
          ? response.data['data'] as List<dynamic>
          : response.data as List<dynamic>;
      
      return responseData.take(limit).map((json) {
        final product = json as Map<String, dynamic>;
        return TopProduct(
          productId: product['id'] ?? 0,
          name: product['name'] ?? 'Товар ${product['id']}',
          category: product['template']?['name'] ?? 'Без категории',
          soldQuantity: product['total_sales'] ?? 0,
          totalRevenue: double.tryParse(product['total_revenue']?.toString() ?? '0') ?? 0.0,
          currentStock: product['quantity'] ?? 0,
        );
      }).toList();
    } on DioException catch (e) {
      throw Exception('Нет данных о топ товарах');
    }
  }
  
  @override
  Future<List<RecentActivity>> getRecentActivities({int limit = 20}) async {
    try {
      // Получаем последние продажи как активности (API не предоставляет специального эндпоинта)
      final response = await _dio.get('/sales', queryParameters: {
        'per_page': limit,
        'page': 1,
      });
      
      final salesData = response.data is Map<String, dynamic> && response.data['data'] != null
          ? response.data['data'] as List<dynamic>
          : response.data as List<dynamic>;
      
      return salesData.map((json) {
        final sale = json as Map<String, dynamic>;
        return RecentActivity(
          id: sale['id']?.toString() ?? '0',
          type: 'sale',
          description: 'Продажа товара на сумму ${sale['total_price']} ${sale['currency'] ?? 'RUB'}',
          userName: sale['user_id']?.toString() ?? 'Неизвестный',
          timestamp: DateTime.tryParse(sale['sale_date']?.toString() ?? '') ?? DateTime.now(),
          status: 'success',
        );
      }).toList();
    } on DioException catch (e) {
      throw Exception('Нет данных о последних активностях');
    }
  }

}

/// Provider для remote data source дашборда
@riverpod
DashboardRemoteDataSource dashboardRemoteDataSource(DashboardRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return DashboardRemoteDataSourceImpl(dio);
}



