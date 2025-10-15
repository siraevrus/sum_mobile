import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/inventory/domain/entities/inventory_entity.dart';
import 'package:sum_warehouse/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';

/// Форма для создания движения товара
class StockMovementFormPage extends ConsumerStatefulWidget {
  final InventoryEntity? inventory;
  final MovementType? initialType;
  
  const StockMovementFormPage({
    super.key,
    this.inventory,
    this.initialType,
  });

  @override
  ConsumerState<StockMovementFormPage> createState() => _StockMovementFormPageState();
}

class _StockMovementFormPageState extends ConsumerState<StockMovementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _documentController = TextEditingController();
  final _notesController = TextEditingController();
  
  MovementType? _selectedType;
  InventoryEntity? _selectedInventory;
  
  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedInventory = widget.inventory;
  }
  
  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _documentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockMovementAsync = ref.watch(stockMovementNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Движение товара'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Информация о товаре
              if (_selectedInventory != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Товар',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('ID: ${_selectedInventory!.productId}'),
                        Text('Текущий остаток: ${_selectedInventory!.quantity}'),
                        Text('Доступно: ${_selectedInventory!.availableQuantity}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Тип движения
              DropdownButtonFormField<MovementType>(
        dropdownColor: Colors.white,
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип движения',
                  border: OutlineInputBorder(),
                ),
                items: MovementType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите тип движения';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Количество
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Количество',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 16),
              
              // Причина
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Причина',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Номер документа
              TextFormField(
                controller: _documentController,
                decoration: const InputDecoration(
                  labelText: 'Номер документа',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Примечания
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Примечания',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              
              // Кнопка сохранения
              ElevatedButton(
                onPressed: stockMovementAsync.isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: stockMovementAsync.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Создать движение'),
              ),
              
              // Показ ошибок
              if (stockMovementAsync.hasError) ...[
                const SizedBox(height: 16),
                SelectableText.rich(
                  TextSpan(
                    text: 'Ошибка: ${stockMovementAsync.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedInventory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар не выбран')),
      );
      return;
    }
    
    final quantity = double.parse(_quantityController.text);
    
    await ref.read(stockMovementNotifierProvider.notifier).createStockMovement(
      stockId: _selectedInventory!.id,
      type: _selectedType!,
      quantity: quantity,
      reason: _reasonController.text.isEmpty ? null : _reasonController.text,
      documentNumber: _documentController.text.isEmpty ? null : _documentController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );
    
    if (mounted && !ref.read(stockMovementNotifierProvider).hasError) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Движение товара создано')),
      );
    }
  }
}
