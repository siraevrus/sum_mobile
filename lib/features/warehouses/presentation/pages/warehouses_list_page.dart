import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/features/warehouses/presentation/pages/warehouse_form_page.dart';
import 'package:sum_warehouse/features/companies/data/datasources/companies_remote_datasource.dart';
import 'package:sum_warehouse/features/companies/presentation/providers/companies_provider.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/shared/models/company_model.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';

/// Страница списка складов
class WarehousesListPage extends ConsumerStatefulWidget {
  const WarehousesListPage({super.key});

  @override
  ConsumerState<WarehousesListPage> createState() => _WarehousesListPageState();
}

class _WarehousesListPageState extends ConsumerState<WarehousesListPage> {
  String? _searchQuery;
  bool? _isActiveFilter;
  int? _companyIdFilter;
  List<CompanyModel> _companies = [];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final dataSource = ref.read(companiesRemoteDataSourceProvider);
      final companiesResponse = await dataSource.getCompanies();
      if (mounted) {
        setState(() {
          _companies = companiesResponse.data;
        });
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildWarehousesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const WarehouseFormPage(),
            ),
          ).then((_) => setState(() {}));
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warehouse,
            color: Color(0xFF9B59B6),
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Остатки на складе',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WarehouseFormPage(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Создать'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildActiveFilter()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCompanyFilter()),
                  ],
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(flex: 2, child: _buildSearchField()),
                const SizedBox(width: 16),
                Expanded(child: _buildActiveFilter()),
                const SizedBox(width: 16),
                Expanded(child: _buildCompanyFilter()),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Поиск складов...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF007BFF)),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
    );
  }

  Widget _buildActiveFilter() {
    return DropdownButtonFormField<bool>(
        isExpanded: true,
        dropdownColor: Colors.white,
      value: _isActiveFilter,
      onChanged: (value) => setState(() {
        _isActiveFilter = value;
      }),
      decoration: InputDecoration(
        labelText: 'Статус',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('Все')),
        DropdownMenuItem(value: true, child: Text('Активные')),
        DropdownMenuItem(value: false, child: Text('Неактивные')),
      ],
    );
  }

  Widget _buildCompanyFilter() {
    return DropdownButtonFormField<int>(
        isExpanded: true,
        dropdownColor: Colors.white,
      value: _companyIdFilter,
      onChanged: (value) => setState(() => _companyIdFilter = value),
      decoration: InputDecoration(
        labelText: 'Компания',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Все')),
        ..._companies.map((company) => DropdownMenuItem(
          value: company.id,
          child: Text(
            company.name ?? '',
            overflow: TextOverflow.ellipsis,
          ),
        )),
      ],
    );
  }

  Widget _buildWarehousesList() {
    return FutureBuilder(
      future: _loadWarehousesFiltered(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: _buildErrorState(),
          );
        }

        final warehouses = snapshot.data ?? <WarehouseModel>[];
        
        if (warehouses.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: _buildEmptyState(),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
            itemCount: warehouses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildWarehouseCard(warehouses[index]),
          ),
        );
      },
    );
  }

  Future<List<WarehouseModel>> _loadWarehousesFiltered() async {
    final dataSource = ref.read(warehousesRemoteDataSourceProvider);
    try {
      List<WarehouseModel> items;
      if (_companyIdFilter != null) {
        // Используем фильтр по компании в общем методе
        final resp = await dataSource.getWarehouses(companyId: _companyIdFilter!);
        items = resp.data;
      } else {
        // Общий список `/warehouses` (спека возвращает массив)
        final resp = await dataSource.getWarehouses();
        items = resp.data;
      }

      // Клиентская фильтрация по is_active (если поле присутствует в модели)
      if (_isActiveFilter != null) {
        items = items.where((w) => w.isActive == _isActiveFilter).toList();
      }

      // Клиентский поиск по названию/адресу
      final query = (_searchQuery ?? '').trim().toLowerCase();
      if (query.isNotEmpty) {
        items = items.where((w) {
          final name = w.name.toLowerCase();
          final address = (w.address).toLowerCase();
          return name.contains(query) || address.contains(query);
        }).toList();
      }

      return items;
    } catch (e) {
      rethrow;
    }
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildWarehouseCard(WarehouseModel warehouse) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WarehouseFormPage(warehouse: warehouse),
          ),
        ).then((_) => setState(() {}));
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с меню
              Row(
                children: [
                  Expanded(
                    child: Text(
                      warehouse.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleWarehouseAction(action, warehouse),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Редактировать')],
                        ),
                      ),
                      if (!warehouse.isActive)
                        const PopupMenuItem(
                          value: 'restore',
                          child: Row(
                            children: [Icon(Icons.unarchive, size: 20, color: Colors.green), SizedBox(width: 8), Text('Восстановить', style: TextStyle(color: Colors.green))],
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [Icon(Icons.archive, size: 20, color: Colors.orange), SizedBox(width: 8), Text('Архивировать', style: TextStyle(color: Colors.orange))],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Информация о складе
              _buildWarehouseInfoRow('Компания', warehouse.company?.name ?? 'Не указана'),
              _buildWarehouseInfoRow('Адрес', warehouse.address),
              _buildWarehouseInfoRow('Сотрудников', '${warehouse.actualEmployeesCount ?? 0}'),
              
              // Тег статуса архива
              if (!warehouse.isActive) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade700.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.archive,
                        size: 14,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Архив",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarehouseInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive 
          ? const Color(0xFF2ECC71).withOpacity(0.1) 
          : const Color(0xFFE74C3C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Активен' : 'Неактивен',
        style: TextStyle(
          color: isActive ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF6C757D),
          ),
        ),
      ],
    );
  }

  void _handleWarehouseAction(String action, WarehouseModel warehouse) {
    switch (action) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WarehouseFormPage(warehouse: warehouse),
          ),
        ).then((deleted) {
          if (deleted == true) {
            setState(() {});
          }
        });
        break;
      case 'archive':
        _showArchiveConfirmDialog(warehouse);
        break;
      case 'restore':
        _restoreWarehouse(warehouse);
        break;
      case 'activate':
      case 'deactivate':
        break;
      case 'delete':
        _showDeleteConfirmDialog(warehouse);
        break;
    }
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warehouse,
                size: 64,
                color: Color(0xFFBDC3C7),
              ),
              SizedBox(height: 16),
              Text(
                'Остатки не найдены',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C757D),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Создайте первый склад или измените фильтры поиска',
                style: TextStyle(color: Color(0xFF6C757D)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: AppErrorWidget(
          error: 'Ошибка загрузки складов',
          onRetry: () => setState(() {}),
        ),
      ),
    );
  }

  /// Показать диалог подтверждения удаления
  void _showDeleteConfirmDialog(WarehouseModel warehouse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: Text(
          'Вы уверены, что хотите удалить склад "${warehouse.name}"?\n\n'
          'Это действие нельзя будет отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteWarehouse(warehouse);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Удалить склад
  Future<void> _deleteWarehouse(WarehouseModel warehouse) async {
    try {
      final dataSource = ref.read(warehousesRemoteDataSourceProvider);
      await dataSource.deleteWarehouse(warehouse.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Склад "${warehouse.name}" успешно удален'),
            backgroundColor: Colors.green,
          ),
        );
        // Обновляем список
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showArchiveConfirmDialog(WarehouseModel warehouse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите архивирование'),
        content: Text(
          'Вы уверены, что хотите архивировать склад "${warehouse.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _archiveWarehouse(warehouse);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Архивировать', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveWarehouse(WarehouseModel warehouse) async {
    try {
      final dataSource = ref.read(warehousesRemoteDataSourceProvider);
      await dataSource.updateWarehouse(
        warehouse.id,
        UpdateWarehouseRequest(isActive: false),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Склад "${warehouse.name}" архивирован'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка архивирования: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreWarehouse(WarehouseModel warehouse) async {
    try {
      final dataSource = ref.read(warehousesRemoteDataSourceProvider);
      await dataSource.updateWarehouse(
        warehouse.id,
        UpdateWarehouseRequest(isActive: true),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Склад "${warehouse.name}" восстановлен'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка восстановления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
