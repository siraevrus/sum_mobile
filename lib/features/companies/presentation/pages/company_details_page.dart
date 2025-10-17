import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/companies/presentation/pages/company_form_page.dart';
import 'package:sum_warehouse/features/warehouses/presentation/pages/warehouse_form_page.dart';
import 'package:sum_warehouse/features/companies/presentation/providers/companies_provider.dart';
import 'package:sum_warehouse/shared/models/company_model.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';

/// Экран детальной информации о компании
class CompanyDetailsPage extends ConsumerWidget {
  final int companyId;
  
  const CompanyDetailsPage({
    super.key,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyDetails = ref.watch(companyDetailsProvider(companyId));
    final companyWarehouses = ref.watch(companyWarehousesProvider(companyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Компания'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(companyDetailsProvider(companyId));
              ref.invalidate(companyWarehousesProvider(companyId));
            },
          ),
        ],
      ),
      
      body: companyDetails.when(
        loading: () => const LoadingWidget(message: 'Загружаем данные компании...'),
        error: (error, stack) => AppErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(companyDetailsProvider(companyId)),
        ),
        data: (company) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(companyDetailsProvider(companyId));
            ref.invalidate(companyWarehousesProvider(companyId));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Основная информация
                _buildCompanyHeader(context, company),
                const SizedBox(height: 24),
                
                // Детальная информация
                _buildCompanyDetails(context, company),
                const SizedBox(height: 24),
                
                // Склады компании
                _buildWarehousesSection(context, ref, companyWarehouses),
                const SizedBox(height: 24),
                
                // Кнопки действий
                _buildActionButtons(context, ref, company),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Заголовок с основной информацией
  Widget _buildCompanyHeader(BuildContext context, CompanyModel company) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ИНН: ${company.inn} • КПП: ${company.kpp}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Быстрая статистика
            Row(
              children: [
                _buildQuickStat(
                  context,
                  'Сотрудники',
                  company.employeesCount.toString(),
                  Icons.people,
                  AppColors.primary,
                ),
                const SizedBox(width: 20),
                _buildQuickStat(
                  context,
                  'Склады',
                  company.warehousesCount?.toString() ?? '0',
                  Icons.warehouse,
                  AppColors.info,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  /// Детальная информация
  Widget _buildCompanyDetails(BuildContext context, CompanyModel company) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Подробная информация',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow(
              'Юридический адрес',
              company.legalAddress ?? 'Не указан',
              Icons.location_city,
            ),
            
            if (company.postalAddress != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Почтовый адрес',
                company.postalAddress!,
                Icons.location_on,
              ),
            ],
            
            if (company.phoneFax != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Телефон/Факс',
                company.phoneFax!,
                Icons.phone,
                isClickable: true,
              ),
            ],
            
            if (company.email != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Email',
                company.email!,
                Icons.email,
                isClickable: true,
              ),
            ],
            
            if (company.generalDirector != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Генеральный директор',
                company.generalDirector!,
                Icons.person,
              ),
            ],
            
            const SizedBox(height: 12),
            _buildDetailRow(
              'Дата создания',
              company.createdAt != null 
                  ? _formatDate(company.createdAt!)
                  : 'Не указана',
              Icons.calendar_today,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isClickable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isClickable ? AppColors.primary : null,
                  decoration: isClickable ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Секция складов
  Widget _buildWarehousesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<WarehouseModel>> warehousesAsync,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Склады компании',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // TODO: Добавить склад
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            warehousesAsync.when(
              loading: () => const LoadingWidget(size: 20),
              error: (error, stack) => Text('Ошибка загрузки складов: $error'),
              data: (warehouses) => warehouses.isEmpty
                  ? const Text(
                      'У компании пока нет складов',
                      style: TextStyle(color: Colors.grey),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: warehouses.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final warehouse = warehouses[index];
                        return _buildWarehouseItem(context, ref, warehouse);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWarehouseItem(BuildContext context, WidgetRef ref, WarehouseModel warehouse) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WarehouseFormPage(warehouse: warehouse),
          ),
        ).then((_) => ref.invalidate(companyWarehousesProvider(companyId)));
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warehouse,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warehouse.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    warehouse.address,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${warehouse.productsCount} товаров',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                if (warehouse.lowStockCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${warehouse.lowStockCount} мало остатков',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Кнопки действий
  Widget _buildActionButtons(BuildContext context, WidgetRef ref, CompanyModel company) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _editCompany(context, company),
            icon: const Icon(Icons.edit),
            label: const Text('Редактировать'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: company.isArchived
              ? OutlinedButton.icon(
                  onPressed: () => _restoreCompany(context, ref, company),
                  icon: const Icon(Icons.unarchive, color: Colors.green),
                  label: const Text('Восстановить', style: TextStyle(color: Colors.green)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () => _archiveCompany(context, ref, company),
                  icon: const Icon(Icons.archive, color: Colors.orange),
                  label: const Text('Архивировать', style: TextStyle(color: Colors.orange)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
        ),
      ],
    );
  }
  
  void _editCompany(BuildContext context, CompanyModel company) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompanyFormPage(company: company),
      ),
    );
  }
  
  void _archiveCompany(BuildContext context, WidgetRef ref, CompanyModel company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Архивировать компанию'),
        content: Text(
          'Вы уверены, что хотите архивировать компанию "${company.name}"?\n\n'
          'Архивированная компания будет скрыта из списка, но все данные сохранятся. '
          'В будущем её можно будет восстановить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performArchive(context, ref, company);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Архивировать', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performArchive(BuildContext context, WidgetRef ref, CompanyModel company) async {
    try {
      final notifier = ref.read(companyDetailsProvider(company.id).notifier);
      await notifier.archiveCompany();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Компания "${company.name}" архивирована'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при архивировании: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _restoreCompany(BuildContext context, WidgetRef ref, CompanyModel company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановить компанию'),
        content: Text(
          'Вы уверены, что хотите восстановить компанию "${company.name}"?\n\n'
          'Компания снова станет активной и будет отображаться в списке.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performRestore(context, ref, company);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Восстановить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performRestore(BuildContext context, WidgetRef ref, CompanyModel company) async {
    try {
      final notifier = ref.read(companyDetailsProvider(company.id).notifier);
      await notifier.restoreCompany();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Компания "${company.name}" восстановлена'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при восстановлении: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _deleteCompany(BuildContext context, WidgetRef ref, CompanyModel company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить компанию'),
        content: Text(
          'Вы уверены, что хотите удалить компанию "${company.name}"?\n\n'
          'Это действие нельзя будет отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDelete(context, ref, company);
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
  
  Future<void> _performDelete(BuildContext context, WidgetRef ref, CompanyModel company) async {
    try {
      final notifier = ref.read(companiesProvider.notifier);
      await notifier.deleteCompany(company.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Компания "${company.name}" удалена'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при удалении: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
