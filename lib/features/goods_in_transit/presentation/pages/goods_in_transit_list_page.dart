import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/reception/domain/entities/receipt_entity.dart';
import 'package:sum_warehouse/features/reception/presentation/providers/receipts_provider.dart';

/// Экран списка товаров в пути
class GoodsInTransitListPage extends ConsumerStatefulWidget {
  const GoodsInTransitListPage({super.key});

  @override
  ConsumerState<GoodsInTransitListPage> createState() => _GoodsInTransitListPageState();
}

class _GoodsInTransitListPageState extends ConsumerState<GoodsInTransitListPage> {
  final _searchController = TextEditingController();
  String? _filterStatus;
  bool? _filterOverdue;
  int? _selectedWarehouseId;
  String _searchQuery = '';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goodsInTransitAsync = ref.watch(goodsInTransitProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: _createTransit,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Новое перемещение',
      ),
      
      body: Column(
        children: [
          // Поиск
          _buildSearchBar(),
          
          // Активные фильтры
          if (_hasActiveFilters()) _buildActiveFilters(),
          
          // Список товаров в пути
          Expanded(
            child: goodsInTransitAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка загрузки: $error',
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(goodsInTransitProvider.notifier).refresh(),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
              data: (receipts) {
                final filteredReceipts = _searchQuery.isEmpty
                  ? receipts
                  : receipts.where((r) => (r.product?.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                if (filteredReceipts.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Нет товаров в пути',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(goodsInTransitProvider.notifier).refresh();
                  },
                  child: Column(
                    children: [
                      // Сводка по статусам
                      _buildStatusSummary(filteredReceipts),
                      
                      // Список
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filteredReceipts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final receipt = filteredReceipts[index];
                            return _buildReceiptCard(receipt);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
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
          hintText: 'Поиск по товару, номеру документа...',
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
          hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }
  
  bool _hasActiveFilters() {
    return _filterStatus != null || 
           _filterOverdue != null ||
           _selectedWarehouseId != null;
  }
  
  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                if (_filterStatus != null)
                  _buildFilterChip(_getStatusDisplayName(_filterStatus!), () => setState(() => _filterStatus = null)),
                if (_filterOverdue == true)
                  _buildFilterChip('Просрочено', () => setState(() => _filterOverdue = null)),
                if (_selectedWarehouseId != null)
                  _buildFilterChip('Склад #$_selectedWarehouseId', () => setState(() => _selectedWarehouseId = null)),
              ],
            ),
          ),
          TextButton(
            onPressed: _clearAllFilters,
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onDeleted: onRemove,
      deleteIconColor: AppColors.primary,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
    );
  }
  
  void _clearAllFilters() {
    setState(() {
      _filterStatus = null;
      _filterOverdue = null;
      _selectedWarehouseId = null;
    });
  }
  
  Widget _buildStatusSummary(List<ReceiptEntity> receipts) {
    final inTransit = receipts.where((r) => r.status == 'in_transit').length;
    final arrived = receipts.where((r) => r.status == 'arrived').length;
    final received = receipts.where((r) => r.status == 'received').length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'В пути',
              inTransit.toString(),
              AppColors.info,
              Icons.local_shipping,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Прибыли',
              arrived.toString(),
              AppColors.warning,
              Icons.place,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Принято',
              received.toString(),
              AppColors.success,
              Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReceiptCard(ReceiptEntity receipt) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        onTap: () => _viewReceiptDetails(receipt),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с типом и статусом
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt.product?.name ?? 'Товар #${receipt.productId}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (receipt.documentNumber != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Документ: ${receipt.documentNumber}',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Тип перемещения
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getTypeColor(receipt.type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          receipt.type.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getTypeColor(receipt.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Статус
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(receipt.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          receipt.status.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getStatusColor(receipt.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Меню действий
                      PopupMenuButton<String>(
                        onSelected: (action) => _handleTransitAction(action, receipt),
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
                            value: 'track',
                            child: Row(
                              children: [
                                Icon(Icons.timeline, size: 20),
                                SizedBox(width: 8),
                                Text('Отслеживание'),
                              ],
                            ),
                          ),
                          if (receipt.canUpdateStatus('admin')) // TODO: Получить настоящую роль
                            const PopupMenuItem(
                              value: 'update_status',
                              child: Row(
                                children: [
                                  Icon(Icons.update, size: 20),
                                  SizedBox(width: 8),
                                  Text('Обновить статус'),
                                ],
                              ),
                            ),
                          if (receipt.status != TransitStatus.delivered && receipt.status != TransitStatus.cancelled)
                            const PopupMenuItem(
                              value: 'cancel',
                              child: Row(
                                children: [
                                  Icon(Icons.cancel, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Отменить', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 8),

            // Маршрут
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${receipt.fromWarehouse?.name ?? 'Склад #${receipt.fromWarehouseId}'} → ${receipt.toWarehouse?.name ?? 'Склад #${receipt.toWarehouseId}'}',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Количество
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${receipt.quantity.toStringAsFixed(0)} ${receipt.product?.unit ?? 'шт'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Прогресс-бар
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Прогресс доставки',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    Text(
                      '${receipt.progressPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(receipt.status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: receipt.progressPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(receipt.status)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Даты
            Row(
              children: [
                if (receipt.dispatchDate != null) ...[
                  Icon(Icons.schedule, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 4),
                  Text(
                    'Отправлено: ${_formatDate(receipt.dispatchDate!)}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 11,
                    ),
                  ),
                ],
                const Spacer(),
                if (receipt.expectedArrivalDate != null) ...[
                  Icon(
                    receipt.isOverdue ? Icons.warning : Icons.event,
                    size: 14,
                    color: receipt.isOverdue ? AppColors.error : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ожидается: ${_formatDate(receipt.expectedArrivalDate!)}',
                    style: TextStyle(
                      color: receipt.isOverdue ? AppColors.error : Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 11,
                      fontWeight: receipt.isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),

            // Транспорт и водитель (если есть)
            if (receipt.transportInfo != null || receipt.driverInfo != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (receipt.transportInfo != null) ...[
                      Row(
                        children: [
                          Icon(Icons.directions_car, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            receipt.transportInfo!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (receipt.driverInfo != null) ...[
                      if (receipt.transportInfo != null) const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            receipt.driverInfo!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(TransitStatus status) {
    switch (status) {
      case TransitStatus.planned:
        return Colors.grey;
      case TransitStatus.dispatched:
        return AppColors.info;
      case TransitStatus.inTransit:
        return AppColors.warning;
      case TransitStatus.arrived:
        return AppColors.success;
      case TransitStatus.delivered:
        return AppColors.success;
      case TransitStatus.cancelled:
        return AppColors.error;
      case TransitStatus.delayed:
        return AppColors.error;
    }
  }
  
  Color _getTypeColor(TransitType type) {
    switch (type) {
      case TransitType.transfer:
        return AppColors.primary;
      case TransitType.delivery:
        return AppColors.success;
      case TransitType.return_:
        return AppColors.warning;
      case TransitType.incoming:
        return AppColors.info;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Статус
              const Text('Статус:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final status in [null, ...TransitStatus.values])
                    FilterChip(
                      label: Text(status?.displayName ?? 'Все'),
                      selected: _filterStatus == status,
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = selected ? status : null;
                        });
                      },
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Text('Тип:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final type in [null, ...TransitType.values])
                    FilterChip(
                      label: Text(type?.displayName ?? 'Все'),
                      selected: _filterType == type,
                      onSelected: (selected) {
                        setState(() {
                          _filterType = selected ? type : null;
                        });
                      },
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Просроченные'),
                value: _filterOverdue ?? false,
                onChanged: (value) {
                  setState(() {
                    _filterOverdue = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearAllFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Очистить'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }
  
  void _showMap() {
    // TODO: Показать карту с маршрутами
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Карта маршрутов - в разработке')),
    );
  }
  
  void _createTransit() {
    // TODO: Создать новое перемещение
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Создание перемещения - в разработке')),
    );
  }
  
  void _handleTransitAction(String action, GoodsInTransitEntity transit) {
    switch (action) {
      case 'view':
        _viewTransitDetails(transit);
        break;
      case 'track':
        _showTrackingHistory(transit);
        break;
      case 'update_status':
        _updateTransitStatus(transit);
        break;
      case 'cancel':
        _cancelTransit(transit);
        break;
    }
  }
  
  void _viewTransitDetails(GoodsInTransitEntity transit) {
    // TODO: Навигация к детальной странице
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Просмотр "${transit.product?.name}"')),
    );
  }
  
  void _showTrackingHistory(GoodsInTransitEntity transit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('История отслеживания'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mock данные отслеживания
              _buildTrackingEvent('Товар отправлен со склада', 'Сегодня 09:00'),
              _buildTrackingEvent('Товар в пути', 'Сегодня 10:30'),
              _buildTrackingEvent('Прибытие на склад назначения', 'Ожидается завтра 14:00'),
            ],
          ),
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
  
  Widget _buildTrackingEvent(String event, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _updateTransitStatus(GoodsInTransitEntity transit) {
    showDialog(
      context: context,
      builder: (context) {
        TransitStatus? newStatus = transit.status;
        return AlertDialog(
          title: const Text('Обновить статус'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Товар: ${transit.product?.name}'),
              Text('Текущий статус: ${transit.status.displayName}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<TransitStatus>(
        dropdownColor: Colors.white,
                value: newStatus,
                decoration: const InputDecoration(
                  labelText: 'Новый статус',
                  border: OutlineInputBorder(),
                ),
                items: TransitStatus.values.map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                )).toList(),
                onChanged: (status) {
                  newStatus = status;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Реализовать обновление статуса
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Статус обновлен на "${newStatus?.displayName}"'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Обновить'),
            ),
          ],
        );
      },
    );
  }
  
  void _cancelTransit(GoodsInTransitEntity transit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить перемещение'),
        content: Text('Отменить перемещение "${transit.product?.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Нет'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Реализовать отмену
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Перемещение "${transit.product?.name}" отменено'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Отменить перемещение', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  List<GoodsInTransitEntity> _getMockGoodsInTransit() {
    final now = DateTime.now();
    return [
      GoodsInTransitEntity(
        id: 1,
        productId: 1,
        fromWarehouseId: 1,
        toWarehouseId: 2,
        userId: 1,
        quantity: 20,
        status: TransitStatus.inTransit,
        type: TransitType.transfer,
        documentNumber: 'ТТН-001',
        description: 'Перемещение досок на склад №2',
        transportInfo: 'ГАЗель А123БВ',
        driverInfo: 'Петров И.И., тел. +7 123 456-78-90',
        dispatchDate: now.subtract(const Duration(hours: 3)),
        expectedArrivalDate: now.add(const Duration(hours: 2)),
        product: const ProductEntity(
          id: 1,
          name: 'Доска обрезная 150x25x6000',
          productTemplateId: 1,
          unit: 'м³',
          producer: 'ООО "СтройМатериалы"',
        ),
        fromWarehouse: const WarehouseEntity(
          id: 1,
          name: 'Основной склад',
          address: 'ул. Складская, 1',
          companyId: 1,
        ),
        toWarehouse: const WarehouseEntity(
          id: 2,
          name: 'Склад №2',
          address: 'ул. Промышленная, 5',
          companyId: 1,
        ),
      ),
      GoodsInTransitEntity(
        id: 2,
        productId: 2,
        fromWarehouseId: 2,
        toWarehouseId: 1,
        userId: 2,
        quantity: 500,
        status: TransitStatus.delayed,
        type: TransitType.transfer,
        documentNumber: 'ТТН-002',
        description: 'Возврат кирпича на основной склад',
        transportInfo: 'КамАЗ В456ГД',
        dispatchDate: now.subtract(const Duration(days: 2)),
        expectedArrivalDate: now.subtract(const Duration(hours: 4)), // Просрочено
        product: const ProductEntity(
          id: 2,
          name: 'Кирпич керамический полнотелый',
          productTemplateId: 2,
          unit: 'шт',
          producer: 'Кирпичный завод "Керам"',
        ),
        fromWarehouse: const WarehouseEntity(
          id: 2,
          name: 'Склад №2',
          address: 'ул. Промышленная, 5',
          companyId: 1,
        ),
        toWarehouse: const WarehouseEntity(
          id: 1,
          name: 'Основной склад',
          address: 'ул. Складская, 1',
          companyId: 1,
        ),
      ),
      GoodsInTransitEntity(
        id: 3,
        productId: 3,
        fromWarehouseId: 1,
        toWarehouseId: 1,
        userId: 1,
        quantity: 10,
        status: TransitStatus.delivered,
        type: TransitType.incoming,
        documentNumber: 'ПН-003',
        description: 'Поставка цемента от поставщика',
        dispatchDate: now.subtract(const Duration(days: 3)),
        expectedArrivalDate: now.subtract(const Duration(days: 2)),
        actualArrivalDate: now.subtract(const Duration(days: 2)),
        product: const ProductEntity(
          id: 3,
          name: 'Цемент портландский М400',
          productTemplateId: 3,
          unit: 'мешок',
          producer: 'Цементный комбинат',
        ),
        fromWarehouse: const WarehouseEntity(
          id: 1,
          name: 'Основной склад',
          address: 'ул. Складская, 1',
          companyId: 1,
        ),
        toWarehouse: const WarehouseEntity(
          id: 1,
          name: 'Основной склад',
          address: 'ул. Складская, 1',
          companyId: 1,
        ),
      ),
    ];
  }
}
