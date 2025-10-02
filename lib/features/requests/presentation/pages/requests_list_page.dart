import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/requests/data/datasources/requests_remote_datasource.dart';
import 'package:sum_warehouse/features/requests/domain/entities/request_entity.dart';
import 'package:sum_warehouse/features/requests/presentation/pages/request_form_page.dart';
import 'package:sum_warehouse/shared/models/request_model.dart' as models;
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';

/// Страница списка запросов
class RequestsListPage extends ConsumerStatefulWidget {
  const RequestsListPage({super.key});

  @override
  ConsumerState<RequestsListPage> createState() => _RequestsListPageState();
}

class _RequestsListPageState extends ConsumerState<RequestsListPage> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildRequestsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const RequestFormPage(),
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
            Icons.assignment,
            color: Color(0xFF3498DB),
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Запросы',
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
                  builder: (context) => const RequestFormPage(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Создать запрос'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498DB),
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                _buildStatusFilter(),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(child: _buildStatusFilter()),
                const Spacer(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
        dropdownColor: Colors.white,
      value: _statusFilter,
      onChanged: (value) => setState(() => _statusFilter = value),
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
        DropdownMenuItem(value: 'pending', child: Text('Ожидает')),
        DropdownMenuItem(value: 'approved', child: Text('Одобрен')),
      ],
    );
  }

  Widget _buildRequestsList() {
    final dataSource = ref.watch(requestsRemoteDataSourceProvider);

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: FutureBuilder(
        future: dataSource.getRequests(
          status: _statusFilter,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final requests = snapshot.data?.data ?? [];
          
          if (requests.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) => _buildRequestCard(requests[index]),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(models.RequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RequestFormPage(request: request),
            ),
          ).then((_) {
            // Перезапускаем FutureBuilder для обновления списка
            if (mounted) setState(() {});
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return _buildMobileRequestCard(request);
              } else {
                return _buildDesktopRequestCard(request);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileRequestCard(models.RequestModel request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                request.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // PopupMenuButton удалён
          ],
        ),
        const SizedBox(height: 8),
        if (request.description != null)
          Text(
            request.description!,
            style: const TextStyle(color: Color(0xFF6C757D)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 8),
        Text(
          'Количество: ${request.quantity}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          'Шаблон: Не указан',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          'Склад: ${request.warehouse?.name ?? 'ID ${request.warehouse?.id}'}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatusChip(request.status),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopRequestCard(models.RequestModel request) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (request.description != null)
                Text(
                  request.description!,
                  style: const TextStyle(color: Color(0xFF6C757D)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Expanded(
          child: Text('${request.quantity}'),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Не указан',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: _buildStatusChip(request.status),
        ),
        SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // PopupMenuButton удалён
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusDisplayName(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<Widget> _buildActions(models.RequestModel request) {
    return [
      IconButton(
        onPressed: () {
          // TODO: Просмотр деталей запроса
        },
        icon: const Icon(Icons.visibility, size: 18),
        tooltip: 'Просмотр',
      ),
      if (request.status == 'pending') ...[
        IconButton(
          onPressed: () {
            _approveRequest(request);
          },
          icon: const Icon(Icons.check, color: Colors.green, size: 18),
          tooltip: 'Одобрить',
        ),
      ],
      IconButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RequestFormPage(request: request),
            ),
          );
        },
        icon: const Icon(Icons.edit, size: 18),
        tooltip: 'Редактировать',
      ),
    ];
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment,
                size: 64,
                color: Color(0xFFBDC3C7),
              ),
              SizedBox(height: 16),
              Text(
                'Запросы не найдены',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C757D),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Создайте первый запрос или измените фильтры',
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
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        child: AppErrorWidget(
          error: 'Ошибка загрузки запросов',
          onRetry: () => setState(() {}),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF2ECC71); // Зеленый
      case 'pending':
        return const Color(0xFFF39C12); // Оранжевый
      default:
        return const Color(0xFF6C757D); // Серый
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'approved':
        return 'Одобрен';
      case 'pending':
        return 'Ожидает';
      default:
        return status;
    }
  }

  /// Конвертировать RequestModel в RequestEntity для формы



  /// Конвертировать RequestStatus из строки в enum
  RequestStatus _convertStatusFromModel(String status) {
    switch (status) {
      case 'pending':
        return RequestStatus.pending;
      case 'in_progress':
      case 'processing':
        return RequestStatus.processing;
      case 'completed':
        return RequestStatus.completed;
      case 'rejected':
        return RequestStatus.rejected;
      default:
        return RequestStatus.pending;
    }
  }

  /// Одобрить запрос
  Future<void> _approveRequest(models.RequestModel request) async {
    try {
      final dataSource = ref.read(requestsRemoteDataSourceProvider);
      await dataSource.processRequest(request.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Запрос одобрен'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Обновляем список
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

}