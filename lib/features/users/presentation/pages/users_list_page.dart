import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/users/data/datasources/users_remote_datasource.dart';
import 'package:sum_warehouse/features/users/presentation/pages/user_form_page.dart';
import 'package:sum_warehouse/shared/models/user_management_model.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';

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
  // Cached future so we can explicitly refresh it after edits/deletes
  Future<PaginatedResponse<UserManagementModel>>? _usersFuture;

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
              ).then((created) {
                if (created == true) _loadUsers();
              });
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
        hintText: 'Поиск пользователей...',
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
        fillColor: const Color(0xFFFAFBFC),
      ),
    );
  }

  Widget _buildRoleFilter() {
    return DropdownButtonFormField<UserRole>(
        dropdownColor: Colors.white,
      value: _roleFilter,
      onChanged: (value) {
        _roleFilter = value;
        _loadUsers();
      },
      decoration: InputDecoration(
        labelText: 'Роль',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Все')),
        ...UserRole.values.map(
          (role) => DropdownMenuItem(
            value: role,
            child: Text(_getRoleDisplayName(role)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<bool>(
        dropdownColor: Colors.white,
      value: _isBlockedFilter,
      onChanged: (value) {
        _isBlockedFilter = value;
        _loadUsers();
      },
      decoration: InputDecoration(
        labelText: 'Статус',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
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

    // Initialize future if null
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
          return _buildErrorState();
        }

        final users = snapshot.data?.data ?? [];
        
        if (users.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) => _buildUserCard(users[index]),
        );
      },
    );
  }

  Widget _buildUserCard(UserManagementModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return _buildMobileUserCard(user);
            } else {
              return _buildDesktopUserCard(user);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMobileUserCard(UserManagementModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Аватар и основная информация
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getRoleColor(user.role),
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(user.isBlocked),
          ],
        ),
        const SizedBox(height: 12),
        
        // Роль и компания
        Row(
          children: [
            _buildRoleChip(user.role),
            if (user.company != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user.company!.name!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C757D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        
        if (user.phone != null) ...[
          const SizedBox(height: 8),
          Text(
            'Телефон: ${user.phone}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6C757D),
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PopupMenuButton<String>(
              onSelected: (action) => _handleUserAction(action, user),
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
                        style: TextStyle(
                          color: user.isBlocked ? Colors.green : Colors.orange,
                        ),
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
      ],
    );
  }

  Widget _buildDesktopUserCard(UserManagementModel user) {
    return Row(
      children: [
        // Аватар и основная информация
        CircleAvatar(
          radius: 24,
          backgroundColor: _getRoleColor(user.role),
          child: Text(
            user.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                user.email,
                style: const TextStyle(
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _buildRoleChip(user.role),
        ),
        
        Expanded(
          child: user.company != null
              ? Text(
                  user.company!.name!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : const Text('-'),
        ),
        
        Expanded(
          child: user.phone != null
              ? Text(user.phone!)
              : const Text('-'),
        ),
        
        _buildStatusBadge(user.isBlocked),
        
        const SizedBox(width: 16),
        PopupMenuButton<String>(
          onSelected: (action) => _handleUserAction(action, user),
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
                    style: TextStyle(
                      color: user.isBlocked ? Colors.green : Colors.orange,
                    ),
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
      case 'view':
        _viewUser(user);
        break;
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

  /// Просмотр пользователя
  void _viewUser(UserManagementModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Пользователь: ${user.name}'),
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
            Text('Создан: ${user.createdAt}'),
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

  /// Редактирование пользователя
  void _editUser(UserManagementModel user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserFormPage(user: _convertToUserEntity(user)),
      ),
    ).then((updated) {
      if (updated == true) _loadUsers();
    });
  }

  /// Блокировка/разблокировка пользователя
  void _toggleUserBlock(UserManagementModel user) async {
    try {
      final dataSource = ref.read(usersRemoteDataSourceProvider);
      
      if (user.isBlocked) {
        await dataSource.unblockUser(user.id);
      } else {
        await dataSource.blockUser(user.id);
      }
      
      // Refresh list from server
      _loadUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(user.isBlocked 
              ? 'Пользователь разблокирован' 
              : 'Пользователь заблокирован'),
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

  /// Удаление пользователя
  void _deleteUser(UserManagementModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: Text('Вы уверены, что хотите удалить пользователя "${user.name}"?'),
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
                
                // Refresh list from server
                _loadUsers();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Пользователь успешно удален'),
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
      case UserRole.manager:
        return 'Менеджер';
      case UserRole.salesManager:
        return 'Менеджер по продажам';
    }
  }

  /// Конвертировать UserManagementModel в UserEntity для формы
  UserEntity _convertToUserEntity(UserManagementModel user) {
    return UserEntity(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      phone: user.phone,
      isBlocked: user.isBlocked,
    );
  }

  Widget _buildEmptyState() {
    return const Center(
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
            'Создайте первого пользователя или измените фильтры поиска',
            style: TextStyle(color: Color(0xFF6C757D)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return AppErrorWidget(
      error: 'Ошибка загрузки пользователей',
      onRetry: () => setState(() {}),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFE74C3C);
      case UserRole.manager:
        return AppColors.primary;
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
      case UserRole.manager:
        return 'Менеджер';
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
    setState(() {
      _usersFuture = dataSource.getUsers(
        search: _searchQuery,
        role: _roleFilter?.name,
        isBlocked: _isBlockedFilter,
      );
    });
  }
}
