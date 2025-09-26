import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sum_warehouse/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';

/// Дашборд выручки с фильтрацией по периодам
class RevenueDashboard extends ConsumerStatefulWidget {
  const RevenueDashboard({super.key});

  @override
  ConsumerState<RevenueDashboard> createState() => _RevenueDashboardState();
}

class _RevenueDashboardState extends ConsumerState<RevenueDashboard> {
  String _selectedPeriod = 'day';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero, // Убираем отступы, они будут управляться родителем
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и фильтры
            Row(
              children: [
                Icon(
                  Icons.monetization_on_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Выручка',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildPeriodFilter(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Фильтр по датам для custom периода
            if (_selectedPeriod == 'custom') ...[
              _buildDateFilters(),
              const SizedBox(height: 16),
            ],
            
            // Таблица с данными
            _buildRevenueTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return DropdownButton<String>(
      value: _selectedPeriod,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedPeriod = newValue;
            if (newValue != 'custom') {
              _dateFrom = null;
              _dateTo = null;
            }
          });
        }
      },
      items: const [
        DropdownMenuItem(value: 'day', child: Text('День')),
        DropdownMenuItem(value: 'week', child: Text('Неделя')),
        DropdownMenuItem(value: 'month', child: Text('Месяц')),
        DropdownMenuItem(value: 'custom', child: Text('Период')),
      ],
    );
  }

  Widget _buildDateFilters() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Дата от',
              suffixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            controller: TextEditingController(
              text: _dateFrom != null 
                  ? DateFormat('yyyy-MM-dd').format(_dateFrom!)
                  : '',
            ),
            onTap: () => _selectDate(true),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Дата до',
              suffixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            controller: TextEditingController(
              text: _dateTo != null 
                  ? DateFormat('yyyy-MM-dd').format(_dateTo!)
                  : '',
            ),
            onTap: () => _selectDate(false),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  Widget _buildRevenueTable() {
    final revenueData = ref.watch(revenueDataProvider(
      period: _selectedPeriod,
      dateFrom: _dateFrom != null 
          ? DateFormat('yyyy-MM-dd').format(_dateFrom!)
          : null,
      dateTo: _dateTo != null 
          ? DateFormat('yyyy-MM-dd').format(_dateTo!)
          : null,
    ));

    return revenueData.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(
          child: LoadingWidget(message: 'Загружаем данные о выручке...'),
        ),
      ),
      error: (error, stackTrace) => SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Ошибка загрузки данных о выручке',
                style: TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => ref.invalidate(revenueDataProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Информация о периоде
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  _getPeriodDisplayName(data.period),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${data.dateFrom} - ${data.dateTo}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Таблица валют
          if (data.revenue.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Нет данных о выручке за выбранный период',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            // Таблица на всю ширину без горизонтального скролла
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Заголовок таблицы
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Валюта',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Сумма',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Строки таблицы
                  ...data.revenue.entries.map((entry) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getCurrencyColor(entry.key).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _getCurrencyColor(entry.key),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.amount.toStringAsFixed(2),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getPeriodDisplayName(String period) {
    switch (period) {
      case 'day':
        return 'День';
      case 'week':
        return 'Неделя';
      case 'month':
        return 'Месяц';
      case 'custom':
        return 'Произвольный';
      default:
        return period;
    }
  }

  Color _getCurrencyColor(String currency) {
    switch (currency) {
      case 'USD':
        return const Color(0xFF2ECC71);
      case 'RUB':
        return const Color(0xFF3498DB);
      case 'UZS':
        return const Color(0xFFF39C12);
      default:
        return Colors.grey;
    }
  }
}