import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/products/data/datasources/products_api_datasource.dart';
import 'package:sum_warehouse/shared/models/product_model.dart';

class DebugProductsApiPage extends ConsumerStatefulWidget {
  const DebugProductsApiPage({super.key});

  @override
  ConsumerState<DebugProductsApiPage> createState() => _DebugProductsApiPageState();
}

class _DebugProductsApiPageState extends ConsumerState<DebugProductsApiPage> {
  String _debugOutput = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Products API'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testAllProducts,
                  child: const Text('Все товары'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testForReceiptProducts,
                  child: const Text('for_receipt товары'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testInStockProducts,
                  child: const Text('in_stock товары'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _debugOutput.isEmpty ? 'Нажмите кнопку для тестирования API' : _debugOutput,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testAllProducts() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    try {
      final apiDataSource = ref.read(productsApiDataSourceProvider);
      
      _addOutput('🔵 Тестируем запрос всех товаров (без фильтра status)...\n');
      
      final response = await apiDataSource.getProducts();
      
      _addOutput('✅ Получено ${response.data.length} товаров\n');
      _addOutput('📊 Статистика по статусам:\n');
      
      final statusCounts = <String, int>{};
      for (final product in response.data) {
        final status = product.status ?? 'null';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        
        // Выводим первые 3 товара для примера
        if (statusCounts.values.fold<int>(0, (sum, count) => sum + count) <= 3) {
          _addOutput('  - ${product.name} (ID: ${product.id}, status: ${product.status})\n');
        }
      }
      
      statusCounts.forEach((status, count) {
        _addOutput('  $status: $count товаров\n');
      });
      
    } catch (e) {
      _addOutput('❌ Ошибка: $e\n');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testForReceiptProducts() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    try {
      final apiDataSource = ref.read(productsApiDataSourceProvider);
      
      _addOutput('🔵 Тестируем запрос товаров со статусом for_receipt...\n');
      
      final filters = ProductFilters(
        status: 'for_receipt',
        page: 1,
        perPage: 15,
      );
      
      _addOutput('🔍 Фильтры: ${filters.toQueryParams()}\n');
      
      final response = await apiDataSource.getProducts(filters);
      
      _addOutput('✅ Получено ${response.data.length} товаров\n');
      
      if (response.data.isEmpty) {
        _addOutput('⚠️ Товары со статусом for_receipt не найдены\n');
      } else {
        _addOutput('📋 Список товаров:\n');
        for (int i = 0; i < response.data.length && i < 10; i++) {
          final product = response.data[i];
          _addOutput('  ${i+1}. ${product.name} (ID: ${product.id}, status: ${product.status})\n');
        }
        
        // Проверяем, есть ли товары с другими статусами
        final wrongStatusProducts = response.data.where((p) => p.status != 'for_receipt').toList();
        if (wrongStatusProducts.isNotEmpty) {
          _addOutput('❌ ВНИМАНИЕ! Найдены товары с неправильным статусом:\n');
          for (final product in wrongStatusProducts) {
            _addOutput('  - ${product.name} (ID: ${product.id}, status: ${product.status})\n');
          }
        } else {
          _addOutput('✅ Все товары имеют правильный статус for_receipt\n');
        }
      }
      
    } catch (e) {
      _addOutput('❌ Ошибка: $e\n');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testInStockProducts() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    try {
      final apiDataSource = ref.read(productsApiDataSourceProvider);
      
      _addOutput('🔵 Тестируем запрос товаров со статусом in_stock...\n');
      
      final filters = ProductFilters(
        status: 'in_stock',
        page: 1,
        perPage: 15,
      );
      
      _addOutput('🔍 Фильтры: ${filters.toQueryParams()}\n');
      
      final response = await apiDataSource.getProducts(filters);
      
      _addOutput('✅ Получено ${response.data.length} товаров со статусом in_stock\n');
      
      if (response.data.isNotEmpty) {
        _addOutput('📋 Первые несколько товаров:\n');
        for (int i = 0; i < response.data.length && i < 5; i++) {
          final product = response.data[i];
          _addOutput('  ${i+1}. ${product.name} (ID: ${product.id}, status: ${product.status})\n');
        }
      }
      
    } catch (e) {
      _addOutput('❌ Ошибка: $e\n');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _addOutput(String text) {
    setState(() {
      _debugOutput += text;
    });
  }
}
