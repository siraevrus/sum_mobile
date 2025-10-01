import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/inventory_models.dart';
import '../providers/inventory_stocks_provider.dart';

/// Модель фильтра для товаров
class InventoryFilter {
  final int? warehouseId;
  final int? companyId;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const InventoryFilter({
    this.warehouseId,
    this.companyId,
    this.dateFrom,
    this.dateTo,
  });

  InventoryFilter copyWith({
    int? warehouseId,
    int? companyId,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearWarehouse = false,
    bool clearCompany = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return InventoryFilter(
      warehouseId: clearWarehouse ? null : (warehouseId ?? this.warehouseId),
      companyId: clearCompany ? null : (companyId ?? this.companyId),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }

  bool get hasActiveFilters => 
      warehouseId != null || 
      companyId != null || 
      dateFrom != null || 
      dateTo != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryFilter &&
          runtimeType == other.runtimeType &&
          warehouseId == other.warehouseId &&
          companyId == other.companyId &&
          dateFrom == other.dateFrom &&
          dateTo == other.dateTo;

  @override
  int get hashCode =>
      warehouseId.hashCode ^
      companyId.hashCode ^
      dateFrom.hashCode ^
      dateTo.hashCode;
}

/// Виджет фильтра для раздела Поступление товара
class InventoryFilterWidget extends ConsumerStatefulWidget {
  final InventoryFilter currentFilter;
  final Function(InventoryFilter) onFilterChanged;

  const InventoryFilterWidget({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  ConsumerState<InventoryFilterWidget> createState() => _InventoryFilterWidgetState();
}

class _InventoryFilterWidgetState extends ConsumerState<InventoryFilterWidget> {
  late InventoryFilter _tempFilter;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.currentFilter;
  }

  @override
  void didUpdateWidget(InventoryFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentFilter != oldWidget.currentFilter) {
      _tempFilter = widget.currentFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.filter_list),
          if (widget.currentFilter.hasActiveFilters)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      onPressed: () => _showFilterDialog(context),
      tooltip: 'Фильтр',
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтр товаров'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWarehouseFilter(),
                const SizedBox(height: 16),
                _buildCompanyFilter(),
                const SizedBox(height: 16),
                _buildDateRangeFilter(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _tempFilter = const InventoryFilter();
              });
            },
            child: const Text('Сбросить'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onFilterChanged(_tempFilter);
              Navigator.of(context).pop();
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseFilter() {
    final warehousesAsync = ref.watch(inventoryWarehousesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Склад',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        warehousesAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Ошибка: $error'),
          data: (warehouses) => DropdownButtonFormField<int?>(
            value: _tempFilter.warehouseId,
            decoration: const InputDecoration(
              hintText: 'Выберите склад',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Все склады'),
              ),
              ...warehouses.map((warehouse) => DropdownMenuItem<int?>(
                value: warehouse.id,
                child: Text(warehouse.name),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _tempFilter = _tempFilter.copyWith(
                  warehouseId: value,
                  clearWarehouse: value == null,
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyFilter() {
    final companiesAsync = ref.watch(inventoryCompaniesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Компания',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        companiesAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Ошибка: $error'),
          data: (companies) => DropdownButtonFormField<int?>(
            value: _tempFilter.companyId,
            decoration: const InputDecoration(
              hintText: 'Выберите компанию',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Все компании'),
              ),
              ...companies.map((company) => DropdownMenuItem<int?>(
                value: company.id,
                child: Text(company.name),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _tempFilter = _tempFilter.copyWith(
                  companyId: value,
                  clearCompany: value == null,
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Период',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Дата от',
                value: _tempFilter.dateFrom,
                onChanged: (date) {
                  setState(() {
                    _tempFilter = _tempFilter.copyWith(
                      dateFrom: date,
                      clearDateFrom: date == null,
                    );
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'Дата до',
                value: _tempFilter.dateTo,
                onChanged: (date) {
                  setState(() {
                    _tempFilter = _tempFilter.copyWith(
                      dateTo: date,
                      clearDateTo: date == null,
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('ru'),
        );
        onChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null
              ? '${value!.day.toString().padLeft(2, '0')}.${value!.month.toString().padLeft(2, '0')}.${value!.year}'
              : 'Выберите дату',
          style: TextStyle(
            color: value != null ? null : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
