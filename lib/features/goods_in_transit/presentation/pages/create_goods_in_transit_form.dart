import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/reception/presentation/providers/receipts_provider.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/product_template_model.dart';
import 'package:sum_warehouse/features/products/data/datasources/product_template_remote_datasource.dart';

/// Форма создания товара в пути (Receipt)
class CreateGoodsInTransitForm extends ConsumerStatefulWidget {
  const CreateGoodsInTransitForm({super.key});

  @override
  ConsumerState<CreateGoodsInTransitForm> createState() => _CreateGoodsInTransitFormState();
}

class _CreateGoodsInTransitFormState extends ConsumerState<CreateGoodsInTransitForm> {
  final _formKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _transportInfoController = TextEditingController();
  final _driverInfoController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  int? _selectedWarehouseId;
  int? _selectedProductTemplateId;
  DateTime? _dispatchDate;
  DateTime? _expectedArrivalDate;

  @override
  void dispose() {
    _documentNumberController.dispose();
    _quantityController.dispose();
    _transportInfoController.dispose();
    _driverInfoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать товар в пути'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация
              _buildSectionTitle('Основная информация'),
              const SizedBox(height: 16),
              
              // Номер документа
              _buildTextField(
                controller: _documentNumberController,
                label: 'Номер документа *',
                hint: 'ТТН-001',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер документа';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Склад назначения
              _buildWarehouseDropdown(),
              const SizedBox(height: 16),
              
              // Шаблон товара
              _buildProductTemplateDropdown(),
              const SizedBox(height: 16),
              
              // Количество
              _buildTextField(
                controller: _quantityController,
                label: 'Количество *',
                hint: '1',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите количество';
                  }
                  final quantity = double.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Введите корректное количество';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Даты
              _buildSectionTitle('Даты отгрузки'),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Дата отгрузки',
                      date: _dispatchDate,
                      onDateSelected: (date) => setState(() => _dispatchDate = date),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      label: 'Ожидаемое прибытие',
                      date: _expectedArrivalDate,
                      onDateSelected: (date) => setState(() => _expectedArrivalDate = date),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Транспорт
              _buildSectionTitle('Информация о транспорте'),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _transportInfoController,
                label: 'Номер транспорта',
                hint: 'ГАЗель А123БВ',
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _driverInfoController,
                label: 'Водитель',
                hint: 'Петров И.И., тел. +7 123 456-78-90',
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _notesController,
                label: 'Примечания',
                hint: 'Дополнительная информация о перевозке',
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              
              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createGoodsInTransit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Создать'),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
      ),
    );
  }

  Widget _buildWarehouseDropdown() {
    return FutureBuilder(
      future: ref.read(warehousesRemoteDataSourceProvider).getWarehouses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        
        if (snapshot.hasError) {
          return Text('Ошибка загрузки складов: ${snapshot.error}');
        }
        
        final warehouses = snapshot.data?.data ?? [];
        
        return DropdownButtonFormField<int>(
        dropdownColor: Colors.white,
          value: _selectedWarehouseId,
          decoration: InputDecoration(
            labelText: 'Склад назначения *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
          ),
          items: warehouses.map((warehouse) => DropdownMenuItem(
            value: warehouse.id,
            child: Text(warehouse.name),
          )).toList(),
          onChanged: (value) => setState(() => _selectedWarehouseId = value),
          validator: (value) {
            if (value == null) {
              return 'Выберите склад назначения';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildProductTemplateDropdown() {
    return FutureBuilder(
      future: ref.read(productTemplateRemoteDataSourceProvider).getProductTemplates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        
        if (snapshot.hasError) {
          return Text('Ошибка загрузки шаблонов: ${snapshot.error}');
        }
        
        final templates = snapshot.data?.data ?? [];
        
        return DropdownButtonFormField<int>(
        dropdownColor: Colors.white,
          value: _selectedProductTemplateId,
          decoration: InputDecoration(
            labelText: 'Шаблон товара *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
          ),
          items: templates.map((template) => DropdownMenuItem(
            value: template.id,
            child: Text(template.name),
          )).toList(),
          onChanged: (value) => setState(() => _selectedProductTemplateId = value),
          validator: (value) {
            if (value == null) {
              return 'Выберите шаблон товара';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () => _selectDate(onDateSelected),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'
                  : 'Выберите дату',
              style: TextStyle(
                fontSize: 16,
                color: date != null ? Colors.black : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(Function(DateTime) onDateSelected) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _createGoodsInTransit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Реализовать API создания receipt
      // Пока показываем заглушку
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Функция создания товара в пути пока недоступна в API'),
            backgroundColor: AppColors.warning,
          ),
        );
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
