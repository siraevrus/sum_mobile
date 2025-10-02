import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/products/domain/entities/product_template_entity.dart';
import 'package:sum_warehouse/features/products/presentation/pages/product_template_form_page.dart';

/// Экран списка шаблонов товаров
class ProductTemplatesListPage extends ConsumerStatefulWidget {
  const ProductTemplatesListPage({super.key});

  @override
  ConsumerState<ProductTemplatesListPage> createState() => _ProductTemplatesListPageState();
}

class _ProductTemplatesListPageState extends ConsumerState<ProductTemplatesListPage> {
  final _searchController = TextEditingController();
  bool? _filterActive = true;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Пустой список пока нет провайдера
    final templates = <ProductTemplateEntity>[];

    return Scaffold(
      
      floatingActionButton: FloatingActionButton(
        onPressed: _createTemplate,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      
      body: Column(
        children: [
          // Поиск и фильтры
          _buildSearchAndFilters(),
          
          // Список шаблонов
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // TODO: Refresh data
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: templates.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return _buildTemplateCard(template);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Поле поиска
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск по названию, единице измерения...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            ),
            onChanged: (value) {
              // TODO: Реализовать поиск с задержкой
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() {});
                }
              });
            },
          ),
          const SizedBox(height: 12),
          
          // Фильтры
          Row(
            children: [
              const Text('Статус:'),
              const SizedBox(width: 12),
              
              FilterChip(
                label: const Text('Все'),
                selected: _filterActive == null,
                onSelected: (selected) {
                  setState(() {
                    _filterActive = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              
              FilterChip(
                label: const Text('Активные'),
                selected: _filterActive == true,
                selectedColor: AppColors.success.withValues(alpha: 0.2),
                onSelected: (selected) {
                  setState(() {
                    _filterActive = selected ? true : null;
                  });
                },
              ),
              const SizedBox(width: 8),
              
              FilterChip(
                label: const Text('Неактивные'),
                selected: _filterActive == false,
                selectedColor: AppColors.error.withValues(alpha: 0.2),
                onSelected: (selected) {
                  setState(() {
                    _filterActive = selected ? false : null;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTemplateCard(ProductTemplateEntity template) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewTemplateDetails(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с статусом
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Статус
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: template.isActive 
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          template.isActive ? 'Активен' : 'Неактивен',
                          style: TextStyle(
                            fontSize: 12,
                            color: template.isActive ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Меню действий
                      PopupMenuButton<String>(
                        onSelected: (action) => _handleTemplateAction(action, template),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 20),
                                SizedBox(width: 8),
                                Text('Просмотр'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Редактировать'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy, size: 20),
                                SizedBox(width: 8),
                                Text('Дублировать'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Удалить', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Единица измерения и описание
              Row(
                children: [
                  Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Единица: ${template.unit}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              if (template.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  template.description!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Характеристики и формула
              Row(
                children: [
                  // Количество характеристик
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list_alt, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${template.attributes.length} характеристик',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (template.formula != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calculate, size: 14, color: AppColors.info),
                          const SizedBox(width: 4),
                          Text(
                            'С формулой',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.info,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Количество товаров по шаблону
                  Text(
                    '0 товаров', // Будет заполнено после подключения API
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _handleTemplateAction(String action, ProductTemplateEntity template) {
    switch (action) {
      case 'view':
        _viewTemplateDetails(template);
        break;
      case 'edit':
        _editTemplate(template);
        break;
      case 'duplicate':
        _duplicateTemplate(template);
        break;
      case 'delete':
        _deleteTemplate(template);
        break;
    }
  }
  
  void _viewTemplateDetails(ProductTemplateEntity template) {
    // TODO: Навигация к детальной странице шаблона
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Просмотр шаблона "${template.name}"')),
    );
  }
  
  void _createTemplate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductTemplateFormPage(),
      ),
    );
  }
  
  void _editTemplate(ProductTemplateEntity template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductTemplateFormPage(template: template),
      ),
    );
  }
  
  void _duplicateTemplate(ProductTemplateEntity template) {
    // TODO: Реализовать дублирование
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Дублирован шаблон "${template.name}"')),
    );
  }
  
  void _deleteTemplate(ProductTemplateEntity template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить шаблон'),
        content: Text(
          'Вы уверены, что хотите удалить шаблон "${template.name}"?\n\n'
          'Это действие нельзя будет отменить. Все товары, использующие этот шаблон, останутся без изменений.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDelete(template);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performDelete(ProductTemplateEntity template) async {
    try {
      // TODO: Реализовать удаление через провайдер
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Шаблон "${template.name}" удален'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при удалении: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
}
