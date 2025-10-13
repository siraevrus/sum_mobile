import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/users/data/datasources/users_remote_datasource.dart';
import 'package:sum_warehouse/features/users/presentation/pages/user_form_page.dart';
import 'package:sum_warehouse/shared/models/user_management_model.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';

/// Страница списка пользователей
class EmployeesListPage extends ConsumerStatefulWidget {
  const EmployeesListPage({super.key});

  @override
  ConsumerState<EmployeesListPage> createState() => _EmployeesListPageState();
}

class _EmployeesListPageState extends ConsumerState<EmployeesListPage> {
  String? _searchQuery;
  UserRole? _roleFilter;
  bool? _isBlockedFilter;
  Future? _usersFuture; // cached future to control reloads

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildUsersList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const UserFormPage(),
            ),
          ).then((created) {
            if (created == true) _loadUsers();
          });
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
            Icons.people,
            color: Color(0xFFE67E22),
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Сотрудники',
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
                  builder: (context) => const UserFormPage(),
                ),
              ).then((_) => setState(() {}));
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
                    Expanded(child: _buildRoleFilter()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusFilter()),
                  ],
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(flex: 2, child: _buildSearchField()),
                const SizedBox(width: 16),
                Expanded(child: _buildRoleFilter()),
                const SizedBox(width: 16),
                Expanded(child: _buildStatusFilter()),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) {
        setState(() => _searchQuery = value);
        _loadUsers(); // Добавляем вызов поиска
      },
      decoration: InputDecoration(
        hintText: 'Поиск сотрудников...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() => _searchQuery = null);
                  _loadUsers();
                },
              )
            : null,
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

  Widget _buildRoleFilter() {
    return DropdownButtonFormField<UserRole>(
        isExpanded: true,
        dropdownColor: Colors.white,
      value: _roleFilter,
      onChanged: (value) {
        setState(() => _roleFilter = value);
        _loadUsers();
      },
      decoration: InputDecoration(
        labelText: 'Роль',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Все')),
        ...UserRole.values.map(
          (role) => DropdownMenuItem(
            value: role,
            child: Text(
              _getRoleDisplayName(role),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<bool>(
        isExpanded: true,
        dropdownColor: Colors.white,
      value: _isBlockedFilter,
      onChanged: (value) {
        setState(() => _isBlockedFilter = value);
        _loadUsers();
      },
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
        DropdownMenuItem(value: false, child: Text('Активные')),
        DropdownMenuItem(value: true, child: Text('Заблокированные')),
      ],
    );
  }

  Widget _buildUsersList() {
    final dataSource = ref.watch(usersRemoteDataSourceProvider);

    _usersFuture ??= dataSource.getUsers(
      search: _searchQuery,
      role: _roleFilter?.name,
      isBlocked: _isBlockedFilter,
    );

    return FutureBuilder(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return RefreshIndicator(
            onRefresh: () async {
              _loadUsers();
            },
            child: _buildErrorState(),
          );
        }

        final users = snapshot.data?.data ?? [];
        
        if (users.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              _loadUsers();
            },
            child: _buildEmptyState(),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadUsers();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) => _buildUserCard(users[index]),
          ),
        );
      },
    );
  }

  Widget _buildUserCard(UserManagementModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UserFormPage(user: user),
            ),
          ).then((updated) {
            if (updated == true) _loadUsers();
          });
        },
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
                      _getFullName(user),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleUserAction(action, user),
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
                      PopupMenuItem(
                        value: user.isBlocked ? 'unblock' : 'block',
                        child: Row(
                          children: [
                            Icon(
                              user.isBlocked ? Icons.lock_open : Icons.lock,
                              size: 20,
                              color: user.isBlocked ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user.isBlocked ? 'Разблокировать' : 'Заблокировать',
                              style: TextStyle(color: user.isBlocked ? Colors.green : Colors.orange),
                            ),
                          ],
                        ),
                      ),
                      if (!user.isBlocked)
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
              const SizedBox(height: 12),
              
              // Информация о сотруднике
              _buildInfoRow('Логин', user.username ?? 'Не указан'),
              _buildInfoRow('Email', user.email),
              _buildInfoRow('Телефон', user.phone ?? 'Не указан'),
              _buildInfoRow('Компания', user.company?.name ?? 'Не указана'),
              _buildInfoRow('Склад', user.warehouse?.name ?? 'Не указан'),
              _buildInfoRow('Роль', _getRoleDisplayName(user.role)),
              
              // Тег статуса блокировки
              if (user.isBlocked) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade700.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.block,
                        size: 14,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Заблокирован',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
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

  Widget _buildRoleChip(UserRole role) {
    final color = _getRoleColor(role);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getRoleDisplayName(role),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isBlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isBlocked 
          ? const Color(0xFFE74C3C).withOpacity(0.1) 
          : const Color(0xFF2ECC71).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isBlocked ? 'Заблокирован' : 'Активен',
        style: TextStyle(
          color: isBlocked ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _handleUserAction(String action, UserManagementModel user) {
    switch (action) {
      case 'edit':
        _editUser(user);
        break;
      case 'block':
      case 'unblock':
        _toggleUserBlock(user);
        break;
      case 'delete':
        _deleteUser(user);
        break;
    }
  }

  /// Просмотр сотрудника
  void _viewUser(UserManagementModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Сотрудник: ${user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            if (user.phone != null) Text('Телефон: ${user.phone}'),
            Text('Роль: ${_getRoleName(user.role)}'),
            if (user.company != null) Text('Компания: ${user.company!.name}'),
            if (user.warehouse != null) Text('Склад: ${user.warehouse!.name}'),
            Text('Статус: ${user.isBlocked ? "Заблокирован" : "Активен"}'),
            Text('Создан: ${_formatDate(user.createdAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  /// Редактирование сотрудника
  void _editUser(UserManagementModel user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserFormPage(user: user),
      ),
    ).then((updated) {
      if (updated == true) _loadUsers();
    });
  }

  /// Блокировка/разблокировка сотрудника
  void _toggleUserBlock(UserManagementModel user) async {
    try {
      final dataSource = ref.read(usersRemoteDataSourceProvider);
      
      if (user.isBlocked) {
        await dataSource.unblockUser(user.id);
      } else {
        await dataSource.blockUser(user.id);
      }
      
      // Обновляем список
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(user.isBlocked 
              ? 'Сотрудник разблокирован' 
              : 'Сотрудник заблокирован'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Удаление сотрудника
  void _deleteUser(UserManagementModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: Text('Вы уверены, что хотите удалить сотрудника "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                final dataSource = ref.read(usersRemoteDataSourceProvider);
                await dataSource.deleteUser(user.id);
                
                // Обновляем список
                _loadUsers();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Сотрудник успешно удален'),
                      backgroundColor: Colors.green,
                    ),
                  );
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
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  /// Получить название роли на русском
  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Администратор';
      case UserRole.operator:
        return 'Оператор';
      case UserRole.warehouseWorker:
        return 'Работник склада';
      case UserRole.salesManager:
        return 'Менеджер по продажам';
    }
  }



  String _getFullName(UserManagementModel user) {
    if (user.lastName != null || user.firstName != null || user.middleName != null) {
      final last = user.lastName ?? '';
      final first = user.firstName ?? '';
      final middle = user.middleName ?? '';
      return [last, first, middle].where((s) => s.isNotEmpty).join(' ');
    }
    return user.name;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
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
                Icons.people,
                size: 64,
                color: Color(0xFFBDC3C7),
              ),
              SizedBox(height: 16),
              Text(
                'Сотрудники не найдены',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C757D),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Создайте первого сотрудника или измените фильтры поиска',
                textAlign: TextAlign.center,
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
          error: 'Ошибка загрузки сотрудников',
          onRetry: () => setState(() {}),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFE74C3C);
      case UserRole.operator:
        return const Color(0xFF3498DB);
      case UserRole.warehouseWorker:
        return const Color(0xFF2ECC71);
      case UserRole.salesManager:
        return const Color(0xFFFF9800);
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Администратор';
      case UserRole.operator:
        return 'Оператор';
      case UserRole.warehouseWorker:
        return 'Работник склада';
      case UserRole.salesManager:
        return 'Менеджер по продажам';
    }
  }

  void _loadUsers() {
    final dataSource = ref.read(usersRemoteDataSourceProvider);
    // Immediately clear current list so UI reflects update in progress
    setState(() {
      _usersFuture = Future.value(PaginatedResponse<UserManagementModel>(data: <UserManagementModel>[]));
    });

    // Fetch fresh data and update the cached future when completed
    dataSource
        .getUsers(
      search: _searchQuery,
      role: _roleFilter?.name,
      isBlocked: _isBlockedFilter,
    )
        .then((resp) {
      if (mounted) {
        setState(() {
          _usersFuture = Future.value(resp);
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _usersFuture = Future.error(e);
        });
      }
    });
  }
}
