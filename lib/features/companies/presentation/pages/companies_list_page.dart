import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/companies/presentation/pages/company_form_page.dart';
import 'package:sum_warehouse/features/companies/presentation/pages/company_details_page.dart';
import 'package:sum_warehouse/features/companies/presentation/providers/companies_provider.dart';
import 'package:sum_warehouse/shared/models/company_model.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';

/// Экран списка компаний
class CompaniesListPage extends ConsumerStatefulWidget {
  const CompaniesListPage({super.key});

  @override
  ConsumerState<CompaniesListPage> createState() => _CompaniesListPageState();
}

class _CompaniesListPageState extends ConsumerState<CompaniesListPage> {
  final _searchController = TextEditingController();
  bool _showArchived = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companiesList = ref.watch(companiesListProvider((
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      showArchived: _showArchived,
    )));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: _createCompany,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      
      body: Column(
        children: [
          // Поиск и фильтры
          _buildSearchAndFilters(),
          
          // Переключатель показа архивированных компаний
          _buildArchivedToggle(),
          
          // Список компаний
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(companiesListProvider((
                  search: _searchController.text.isNotEmpty ? _searchController.text : null,
                  showArchived: _showArchived,
                )));
              },
              child: companiesList.when(
                loading: () => const LoadingWidget(message: 'Загружаем компании...'),
                error: (error, stack) => AppErrorWidget(
                  error: error,
                  onRetry: () => ref.invalidate(companiesListProvider((
                    search: _searchController.text.isNotEmpty ? _searchController.text : null,
                    showArchived: _showArchived,
                  ))),
                ),
                data: (companies) => companies.isEmpty
                    ? const EmptyWidget(
                        message: 'Компании не найдены',
                        icon: Icons.business,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                        itemCount: companies.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final company = companies[index];
                          return _buildCompanyCard(company);
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Переключатель показа архивированных компаний
  Widget _buildArchivedToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.archive, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          const Text(
            'Показать архивированные',
            style: TextStyle(fontSize: 14),
          ),
          const Spacer(),
          Switch(
            value: _showArchived,
            onChanged: (value) {
              setState(() {
                _showArchived = value;
              });
              // Обновляем провайдер
              ref.invalidate(companiesListProvider);
            },
          ),
        ],
      ),
    );
  }

  /// Поиск
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск по названию, ИНН...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        ),
        onChanged: (value) {
          // Обновляем список с задержкой для оптимизации
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {});
            }
          });
        },
      ),
    );
  }
  
  /// Карточка компании
  Widget _buildCompanyCard(CompanyModel company) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _editCompany(company),
        borderRadius: BorderRadius.circular(12),
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
                      company.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleCompanyAction(action, company),
                    itemBuilder: (context) => [
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
                      if (!company.isArchived)
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive, size: 20, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Архивировать', style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'restore',
                          child: Row(
                            children: [
                              Icon(Icons.unarchive, size: 20, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Восстановить', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Информация о компании
              _buildInfoRow('ИНН', company.inn ?? 'Не указан'),
              _buildInfoRow('КПП', company.kpp ?? 'Не указан'),
              _buildInfoRow('Адрес', company.legalAddress ?? 'Не указан'),
              _buildInfoRow('Телефон', company.phoneFax ?? 'Не указан'),
              _buildInfoRow('Email', company.email ?? 'Не указан'),
              _buildInfoRow('Сотрудников', '${company.employeesCount ?? 0}'),
              _buildInfoRow('Складов', '${company.warehousesCount ?? 0}'),
              
              // Тег статуса архива
              if (company.isArchived) ...[
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
                        'Архив',
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
  
  Widget _buildInfoRow(String label, String value) {
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
  
  /// Обработка действий с компанией
  void _handleCompanyAction(String action, CompanyModel company) {
    switch (action) {
      case 'edit':
        _editCompany(company);
        break;
      case 'archive':
        _archiveCompany(company);
        break;
      case 'restore':
        _restoreCompany(company);
        break;
    }
  }
  
  /// Просмотр деталей компании
  void _viewCompanyDetails(CompanyModel company) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompanyDetailsPage(companyId: company.id),
      ),
    );
  }
  
  /// Создание новой компании
  void _createCompany() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CompanyFormPage(),
      ),
    ).then((_) {
      // Обновляем список после возврата из формы
      ref.invalidate(companiesListProvider);
    });
  }
  
  /// Редактирование компании
  void _editCompany(CompanyModel company) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompanyFormPage(company: company),
      ),
    ).then((result) {
      // После редактирования или архивирования обновляем список
      if (result != null) {
        ref.invalidate(companiesListProvider);
      }
    });
  }
  
  /// Архивирование компании
  void _archiveCompany(CompanyModel company) {
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
              await _performArchive(company);
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
  
  /// Выполнение архивирования
  Future<void> _performArchive(CompanyModel company) async {
    try {
      final dataSource = ref.read(companiesRemoteDataSourceProvider);
      await dataSource.archiveCompany(company.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Компания "${company.name}" архивирована'),
            backgroundColor: AppColors.success,
          ),
        );
        // Обновляем список после архивирования
        ref.invalidate(companiesListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при архивировании: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  /// Восстановление компании
  void _restoreCompany(CompanyModel company) {
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
              await _performRestore(company);
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
  
  /// Выполнение восстановления
  Future<void> _performRestore(CompanyModel company) async {
    try {
      final dataSource = ref.read(companiesRemoteDataSourceProvider);
      await dataSource.restoreCompany(company.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Компания "${company.name}" восстановлена'),
            backgroundColor: AppColors.success,
          ),
        );
        // Обновляем список после восстановления
        ref.invalidate(companiesListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при восстановлении: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
