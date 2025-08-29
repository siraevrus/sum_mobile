import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/companies/presentation/pages/company_form_page.dart';
import 'package:sum_warehouse/features/companies/presentation/pages/company_details_page.dart';
import 'package:sum_warehouse/features/companies/presentation/providers/companies_provider.dart';
import 'package:sum_warehouse/features/companies/data/datasources/companies_remote_datasource.dart';
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
    final companiesList = ref.watch(companiesListProvider(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      showArchived: _showArchived,
    ));

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
                ref.invalidate(companiesListProvider);
              },
              child: companiesList.when(
                loading: () => const LoadingWidget(message: 'Загружаем компании...'),
                error: (error, stack) => AppErrorWidget(
                  message: 'Не удалось загрузить компании',
                  onRetry: () => ref.invalidate(companiesListProvider),
                ),
                data: (companies) => companies.isEmpty
                    ? const EmptyWidget(
                        message: 'Компании не найдены',
                        icon: Icons.business,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16.0),
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
    return InkWell(
      onTap: () => _editCompany(company),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (company.isArchived) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Архив',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Меню действий
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
              const SizedBox(height: 8),
              
              // ИНН/КПП
              Row(
                children: [
                  Icon(Icons.business_center, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'ИНН: ${company.inn} / КПП: ${company.kpp}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Адрес
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      company.legalAddress ?? 'Не указан',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Контакты и статистика
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (company.phoneFax != null) ...[
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          company.phoneFax!,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  Text(
                    '${company.employeesCount} сотрудников',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
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
    ).then((archived) {
      if (archived == true) {
        // Если компания была архивирована, обновляем список
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
