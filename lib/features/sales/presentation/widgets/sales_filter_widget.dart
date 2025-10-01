import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/sales/data/models/sale_model.dart';
import 'package:sum_warehouse/features/sales/presentation/providers/sales_providers.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';

/// Виджет фильтров для продаж
class SalesFilterWidget extends ConsumerStatefulWidget {
  const SalesFilterWidget({super.key});

  @override
  ConsumerState<SalesFilterWidget> createState() => _SalesFilterWidgetState();
}

class _SalesFilterWidgetState extends ConsumerState<SalesFilterWidget> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  
  int? _selectedWarehouseId;
  String? _selectedPaymentStatus;

  @override
  void initState() {
    super.initState();
    // Загружаем текущие фильтры
    final currentFilters = ref.read(salesFiltersNotifierProvider);
    _loadCurrentFilters(currentFilters);
  }

  void _loadCurrentFilters(SaleFilters filters) {
    _searchController.text = filters.search ?? '';
    _dateFromController.text = filters.dateFrom ?? '';
    _dateToController.text = filters.dateTo ?? '';
    _selectedWarehouseId = filters.warehouseId;
    _selectedPaymentStatus = filters.paymentStatus;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Фильтры',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildFiltersGrid(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildFiltersGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildSearchField(),
              const SizedBox(height: 12),
              _buildPaymentStatusFilter(),
              const SizedBox(height: 12),
              _buildWarehouseFilter(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDateFromField()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateToField()),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(flex: 2, child: _buildSearchField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPaymentStatusFilter()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(flex: 2, child: _buildWarehouseFilter()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateFromField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateToField()),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Поиск',
        hintText: 'Номер продажи, имя клиента, телефон',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
    );
  }

  Widget _buildPaymentStatusFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedPaymentStatus,
      onChanged: (value) => setState(() => _selectedPaymentStatus = value),
      decoration: InputDecoration(
        labelText: 'Статус оплаты',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('Все')),
        DropdownMenuItem(value: 'paid', child: Text('Оплачено')),
        DropdownMenuItem(value: 'cancelled', child: Text('Отменено')),
      ],
    );
  }


  Widget _buildWarehouseFilter() {
    final warehousesAsync = ref.watch(warehousesRemoteDataSourceProvider);

    return FutureBuilder(
      future: warehousesAsync.getWarehouses(perPage: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return DropdownButtonFormField<int>(
            value: null,
            onChanged: null,
            decoration: InputDecoration(
              labelText: 'Склад (загрузка...)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            ),
            items: const [],
          );
        }

        if (snapshot.hasError) {
          return DropdownButtonFormField<int>(
            value: null,
            onChanged: null,
            decoration: InputDecoration(
              labelText: 'Склад (ошибка)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            ),
            items: const [],
          );
        }

        final warehouses = snapshot.data?.data ?? [];

        return DropdownButtonFormField<int>(
          value: _selectedWarehouseId,
          onChanged: (value) => setState(() => _selectedWarehouseId = value),
          decoration: InputDecoration(
            labelText: 'Склад',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Все склады')),
            ...warehouses.map((warehouse) => DropdownMenuItem(
              value: warehouse.id,
              child: Text(warehouse.name),
            )),
          ],
        );
      },
    );
  }

  Widget _buildDateFromField() {
    return TextField(
      controller: _dateFromController,
      decoration: InputDecoration(
        labelText: 'Дата от',
        hintText: 'YYYY-MM-DD',
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      readOnly: true,
      onTap: () => _selectDate(_dateFromController, 'от'),
    );
  }

  Widget _buildDateToField() {
    return TextField(
      controller: _dateToController,
      decoration: InputDecoration(
        labelText: 'Дата до',
        hintText: 'YYYY-MM-DD',
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      readOnly: true,
      onTap: () => _selectDate(_dateToController, 'до'),
    );
  }


  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _applyFilters,
          icon: const Icon(Icons.filter_alt),
          label: const Text('Применить'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _clearFilters,
          icon: const Icon(Icons.clear),
          label: const Text('Очистить'),
        ),
      ],
    );
  }

  Future<void> _selectDate(TextEditingController controller, String label) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Выберите дату $label',
    );

    if (date != null) {
      controller.text = date.toIso8601String().split('T')[0];
    }
  }

  void _applyFilters() {
    final filters = SaleFilters(
      search: _searchController.text.isEmpty ? null : _searchController.text,
      warehouseId: _selectedWarehouseId,
      paymentStatus: _selectedPaymentStatus,
      dateFrom: _dateFromController.text.isEmpty ? null : _dateFromController.text,
      dateTo: _dateToController.text.isEmpty ? null : _dateToController.text,
    );

    ref.read(salesFiltersNotifierProvider.notifier).updateFilters(filters);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _dateFromController.clear();
      _dateToController.clear();
      _selectedWarehouseId = null;
      _selectedPaymentStatus = null;
    });

    ref.read(salesFiltersNotifierProvider.notifier).clearFilters();
  }
}
