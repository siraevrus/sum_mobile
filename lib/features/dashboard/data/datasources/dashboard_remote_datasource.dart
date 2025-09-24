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
  
  /// Получить данные о выручке
  Future<RevenueData> getRevenueData({
    required String period,
    String? dateFrom,
    String? dateTo,
  });
}

/// Реализация remote data source для дашборда
class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio _dio;
  
  DashboardRemoteDataSourceImpl(this._dio);
  
  @override
  Future<DashboardStats> getDashboardStats() async {
    try {
      print('🔵 Dashboard: Получение агрегатов через /dashboard/summary ...');
      final resp = await _dio.get('/dashboard/summary');
      final data = resp.data as Map<String, dynamic>;
      
      print('📊 Dashboard API Response: $data');
      
      // Парсим последние продажи
      final latestSalesList = (data['latest_sales'] as List<dynamic>? ?? [])
          .map((saleJson) => LatestSale.fromJson(saleJson as Map<String, dynamic>))
          .toList();
          
      return DashboardStats(
        companiesActive: (data['companies_active'] ?? 0) as int,
        employeesActive: (data['employees_active'] ?? 0) as int,
        warehousesActive: (data['warehouses_active'] ?? 0) as int,
        productsTotal: (data['products_total'] ?? 0) as int,
        productsInTransit: (data['products_in_transit'] ?? 0) as int,
        requestsPending: (data['requests_pending'] ?? 0) as int,
        latestSales: latestSalesList,
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

  @override
  Future<RevenueData> getRevenueData({
    required String period,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      print('🔵 Dashboard: Получение данных о выручке через /dashboard/revenue API...');
      
      // Определяем даты для запроса
      String calculatedDateFrom;
      String calculatedDateTo;
      
      if (period == 'custom' && dateFrom != null && dateTo != null) {
        calculatedDateFrom = dateFrom;
        calculatedDateTo = dateTo;
      } else {
        final now = DateTime.now();
        switch (period) {
          case 'day':
            calculatedDateFrom = now.toIso8601String().split('T')[0];
            calculatedDateTo = now.toIso8601String().split('T')[0];
            break;
          case 'week':
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            calculatedDateFrom = weekStart.toIso8601String().split('T')[0];
            calculatedDateTo = now.toIso8601String().split('T')[0];
            break;
          case 'month':
            final monthStart = DateTime(now.year, now.month, 1);
            calculatedDateFrom = monthStart.toIso8601String().split('T')[0];
            calculatedDateTo = now.toIso8601String().split('T')[0];
            break;
          default:
            calculatedDateFrom = now.toIso8601String().split('T')[0];
            calculatedDateTo = now.toIso8601String().split('T')[0];
        }
      }
      
      print('📅 Период: $period, с $calculatedDateFrom по $calculatedDateTo');
      
      // Используем правильный эндпоинт для выручки
      final queryParams = <String, dynamic>{
        'period': period,
        'date_from': calculatedDateFrom,
        'date_to': calculatedDateTo,
      };
      
      final response = await _dio.get('/dashboard/revenue', queryParameters: queryParams);
      
      print('📊 Получен ответ от /dashboard/revenue: ${response.statusCode}');
      print('📄 Данные ответа: ${response.data}');
      
      // Парсим ответ от API
      final data = response.data as Map<String, dynamic>;
      
      // Преобразуем в модель RevenueData
      final Map<String, CurrencyAmount> revenue = {};
      
      if (data.containsKey('revenue') && data['revenue'] is Map<String, dynamic>) {
        final revenueData = data['revenue'] as Map<String, dynamic>;
        
        for (final entry in revenueData.entries) {
          final currency = entry.key;
          final currencyData = entry.value as Map<String, dynamic>;
          
          revenue[currency] = CurrencyAmount(
            amount: _parseToDouble(currencyData['amount']),
            formatted: currencyData['formatted']?.toString() ?? 
                       _formatCurrency(_parseToDouble(currencyData['amount']), currency),
          );
        }
      }
      
      // Если нет данных, добавляем пустые значения для основных валют
      if (revenue.isEmpty) {
        revenue['RUB'] = const CurrencyAmount(amount: 0.0, formatted: '0 ₽');
        revenue['USD'] = const CurrencyAmount(amount: 0.0, formatted: '0 \$');
        revenue['UZS'] = const CurrencyAmount(amount: 0.0, formatted: '0 сўм');
      }
      
      final result = RevenueData(
        period: period,
        dateFrom: data['date_from']?.toString() ?? calculatedDateFrom,
        dateTo: data['date_to']?.toString() ?? calculatedDateTo,
        revenue: revenue,
      );
      
      print('✅ Данные о выручке успешно получены через /dashboard/revenue API');
      return result;
      
    } on DioException catch (e) {
      print('🔴 Revenue: Ошибка получения данных о выручке: ${e.response?.statusCode} - ${e.message}');
      print('🔴 Response data: ${e.response?.data}');
      
      // В случае ошибки API, возвращаем пустые данные
      print('⚠️ Используем пустые данные из-за ошибки API');
      
      final emptyRevenue = {
        'RUB': const CurrencyAmount(amount: 0.0, formatted: '0 ₽'),
        'USD': const CurrencyAmount(amount: 0.0, formatted: '0 \$'),
        'UZS': const CurrencyAmount(amount: 0.0, formatted: '0 сўм'),
      };
      
      return RevenueData(
        period: period,
        dateFrom: dateFrom ?? DateTime.now().toIso8601String().split('T')[0],
        dateTo: dateTo ?? DateTime.now().toIso8601String().split('T')[0],
        revenue: emptyRevenue,
      );
    } catch (e) {
      print('🔴 Revenue: Общая ошибка: $e');
      throw Exception('Ошибка обработки данных о выручке: $e');
    }
  }
  
  /// Преобразование в double с обработкой строк
  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
  
  /// Форматирование валюты
  String _formatCurrency(double amount, String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'RUB':
        return '${amount.toStringAsFixed(2)} ₽';
      case 'UZS':
        return '${amount.toStringAsFixed(0)} сўм';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }
}

/// Provider для remote data source дашборда
@riverpod
DashboardRemoteDataSource dashboardRemoteDataSource(DashboardRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return DashboardRemoteDataSourceImpl(dio);
}



