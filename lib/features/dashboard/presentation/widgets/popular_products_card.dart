import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/products/data/datasources/products_api_datasource.dart';
import 'package:sum_warehouse/shared/models/popular_products_model.dart';

/// Карточка с популярными товарами
class PopularProductsCard extends ConsumerWidget {
  final VoidCallback? onShowAllPressed;
  
  const PopularProductsCard({
    super.key,
    this.onShowAllPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsApiDataSource = ref.watch(productsApiDataSourceProvider);
    
    return FutureBuilder<List<PopularProductModel>>(
      future: _getPopularProducts(productsApiDataSource),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        
        if (snapshot.hasError) {
          return _buildErrorCard(() => ref.invalidate(productsApiDataSourceProvider));
        }
        
        final popularProducts = snapshot.data ?? [];
        return _buildCard(popularProducts);
      },
    );
  }

  Future<List<PopularProductModel>> _getPopularProducts(ProductsApiDataSource dataSource) async {
    try {
      return await dataSource.getPopularProducts();
    } catch (e) {
      // При ошибке возвращаем пустой список
      return [];
    }
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загружаем популярные товары...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          const Text('Ошибка загрузки популярных товаров'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<PopularProductModel> popularProducts) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE0E0E0),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Color(0xFF2ECC71),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Популярные товары',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Список популярных товаров или заглушка
            if (popularProducts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: Color(0xFF6C757D),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Нет данных о популярных товарах',
                        style: TextStyle(
                          color: Color(0xFF6C757D),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...popularProducts.take(5).toList().asMap().entries.map((entry) => 
                _buildProductItemFromApi(entry.key + 1, entry.value)
              ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItemFromApi(int position, PopularProductModel product) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE9ECEF),
            width: position == 5 ? 0 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Позиция
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: position <= 3 ? const Color(0xFFFFD700) : const Color(0xFFE9ECEF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$position',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: position <= 3 ? Colors.white : const Color(0xFF6C757D),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Информация о товаре
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name ?? 'Товар #${product.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2C3E50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.totalSales} продаж',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ],
            ),
          ),
          
          // Доход
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₽${_formatApiMoney(product.totalRevenue)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2ECC71),
                ),
              ),
              Text(
                'ID: ${product.id}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatApiMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

}