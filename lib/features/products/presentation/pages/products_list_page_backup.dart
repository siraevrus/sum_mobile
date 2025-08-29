import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sum_warehouse/features/products/presentation/providers/products_provider.dart';
import 'package:sum_warehouse/features/products/data/datasources/products_api_datasource.dart';
import 'package:sum_warehouse/shared/models/product_model.dart';
import 'package:sum_warehouse/features/products/presentation/pages/product_form_page.dart';

/// Страница списка товаров
class ProductsListPage extends ConsumerStatefulWidget {
  const ProductsListPage({super.key});

  @override
  ConsumerState<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends ConsumerState<ProductsListPage> {
  final _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    
    return Column(
      children: [
        // Панель поиска и фильтров
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Мобильная версия - в колонну
                return Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Поиск товаров...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                      onSubmitted: (value) {
                        ref.read(productsProvider.notifier).searchProducts(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                                            onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProductFormPage(),
                        ),
                      );
                    },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Добавить товар'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007BFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Десктопная версия - в строку
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Поиск товаров...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                        ),
                        onSubmitted: (value) {
                          ref.read(productsProvider.notifier).searchProducts(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProductFormPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить товар'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007BFF),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
        
        // Список товаров
        Expanded(
          child: switch (productsState) {
            ProductsInitial() => const Center(
              child: Text('Инициализация...'),
            ),
            ProductsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ProductsError(:final message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка: $message',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(productsProvider.notifier).refresh();
                    },
                    child: const Text('Попробовать снова'),
                  ),
                ],
              ),
            ),
            ProductsLoaded(:final products) => products.data.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Color(0xFF999999),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Товары не найдены',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF666666),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Попробуйте изменить критерии поиска',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(productsProvider.notifier).refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.data.length + 1, // +1 для кнопки загрузки
                      itemBuilder: (context, index) {
                        if (index == products.data.length) {
                          // Кнопка "Загрузить еще" в конце списка
                          if (products.meta.currentPage < products.meta.lastPage) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: () {
                                    ref.read(productsProvider.notifier).loadNextPage();
                                  },
                                  child: const Text('Загрузить еще'),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        
                        final product = products.data[index];
                        return _ProductCard(product: product);
                      },
                    ),
                  ),
          },
        ),
      ],
    );
  }
}

/// Карточка товара
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      if (product.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6C757D),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: product.isActive 
                        ? const Color(0xFFD4EDDA) 
                        : const Color(0xFFF8D7DA),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.isActive ? 'Активен' : 'Неактивен',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: product.isActive 
                          ? const Color(0xFF155724)
                          : const Color(0xFF721C24),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Информация о товаре
            Row(
              children: [
                _InfoChip(
                  icon: Icons.inventory,
                  label: 'Остаток: ${product.quantity.toStringAsFixed(0)}',
                ),
                const SizedBox(width: 8),
                if (product.producer?.isNotEmpty == true)
                  _InfoChip(
                    icon: Icons.business,
                    label: product.producer!,
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Действия - адаптивные для мобильных
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Мобильная версия - только иконки
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          // TODO: Просмотр товара
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 20),
                        tooltip: 'Просмотр',
                      ),
                      IconButton(
                        onPressed: () {
                          // TODO: Редактирование товара
                        },
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Изменить',
                      ),
                      IconButton(
                        onPressed: () {
                          // TODO: Удаление товара
                        },
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        tooltip: 'Удалить',
                      ),
                    ],
                  );
                } else {
                  // Десктопная версия - кнопки с текстом
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Просмотр товара
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('Просмотр'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Редактирование товара
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Изменить'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Удаление товара
                        },
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Удалить'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Чип с информацией
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF6C757D),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF495057),
            ),
          ),
        ],
      ),
    );
  }
}