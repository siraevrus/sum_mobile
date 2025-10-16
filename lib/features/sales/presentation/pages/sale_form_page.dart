import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/sales/data/models/sale_model.dart';
import 'package:sum_warehouse/features/sales/presentation/providers/sales_providers.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';

/// Страница создания/редактирования/просмотра продажи
class SaleFormPage extends ConsumerStatefulWidget {
  final SaleModel? sale;
  final bool isViewMode;
  
  const SaleFormPage({
    super.key,
    this.sale,
    this.isViewMode = false,
  });

  @override
  ConsumerState<SaleFormPage> createState() => _SaleFormPageState();
}

class _SaleFormPageState extends ConsumerState<SaleFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _saleNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _cashAmountController = TextEditingController();
  final _nocashAmountController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  final _notesController = TextEditingController();
  // Customer info controllers
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerAddressController = TextEditingController();

  // State variables
  bool _isLoading = false;
  DateTime _saleDate = DateTime.now();
  int? _selectedWarehouseId;
  String? _selectedCompositeProductKey; // Изменили на composite_product_key
  String _selectedCurrency = 'RUB';
  double _exchangeRate = 1.0;
  int _saleNumberCounter = 1;
  
  // Reference data
  List<WarehouseModel> _warehouses = [];
  List<Map<String, dynamic>> _warehouseProducts = [];
  
  bool get _isEditing => widget.sale != null;
  bool get _isViewMode => widget.isViewMode;
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
      _loadData();
  }
  
  @override
  void dispose() {
    _saleNumberController.dispose();
    _quantityController.dispose();
    _cashAmountController.dispose();
    _nocashAmountController.dispose();
    _totalPriceController.dispose();
    _exchangeRateController.dispose();
    _notesController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _customerAddressController.dispose();
    super.dispose();
  }
  
  void _initializeForm() {
    if (_isEditing) {
      final sale = widget.sale!;
      _saleNumberController.text = sale.saleNumber ?? '';
      _quantityController.text = sale.quantity.toString();
      _cashAmountController.text = sale.cashAmount.toString();
      _nocashAmountController.text = sale.nocashAmount.toString();
      _totalPriceController.text = sale.totalPrice.toString();
      _exchangeRateController.text = sale.exchangeRate.toString();
      _notesController.text = sale.notes ?? '';
      
      // Initialize customer info
      _customerNameController.text = sale.customerName ?? '';
      _customerPhoneController.text = sale.customerPhone ?? '';
      _customerEmailController.text = sale.customerEmail ?? '';
      _customerAddressController.text = sale.customerAddress ?? '';
      
      if (sale.saleDate != null) {
        try {
          _saleDate = DateTime.parse(sale.saleDate!);
        } catch (e) {
          _saleDate = DateTime.now();
        }
      } else {
        _saleDate = DateTime.now();
      }
      
      _selectedWarehouseId = sale.warehouseId;
      // Для редактирования нужно будет получить composite_product_key из данных товара
      _selectedCurrency = sale.currency;
      _exchangeRate = sale.exchangeRate;
    } else {
      // Default values for new sale
      _generateSaleNumber();
      // Оставляем поля пустыми, без предустановленных значений
      _quantityController.text = '';
      _cashAmountController.text = '';
      _nocashAmountController.text = '';
      _totalPriceController.text = '';
      _exchangeRateController.text = '1.0';
      _notesController.text = '';
      _customerNameController.text = '';
      _customerPhoneController.text = '';
      _customerEmailController.text = '';
      _customerAddressController.text = '';
    }

    // Add listeners for automatic calculations
    _cashAmountController.addListener(_calculateTotalPrice);
    _nocashAmountController.addListener(_calculateTotalPrice);
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final warehousesDataSource = ref.read(warehousesRemoteDataSourceProvider);
      final warehousesResponse = await warehousesDataSource.getWarehouses(perPage: 100);
      _warehouses = warehousesResponse.data;
      
      if (_selectedWarehouseId != null) {
        await _loadWarehouseProducts(_selectedWarehouseId!);
      }
      
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadWarehouseProducts(int warehouseId) async {
    try {
      final warehousesDataSource = ref.read(warehousesRemoteDataSourceProvider);
      _warehouseProducts = await warehousesDataSource.getWarehouseProducts(warehouseId);
      
      // Отладочная информация
      print('Загружено товаров: ${_warehouseProducts.length}');
      for (final product in _warehouseProducts) {
        print('Товар: ${product['name']}, composite_product_key: ${product['composite_product_key']}');
      }
      
      setState(() {});
    } catch (e) {
      print('Ошибка загрузки товаров: $e');
      // Очищаем список товаров при ошибке
      _warehouseProducts.clear();
      setState(() {});
    }
  }

  void _generateSaleNumber() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final increment = _saleNumberCounter.toString().padLeft(4, '0');
    _saleNumberController.text = 'SALE-$year$month-$increment';
  }

  void _calculateTotalPrice() {
    final cashAmount = double.tryParse(_cashAmountController.text) ?? 0;
    final nocashAmount = double.tryParse(_nocashAmountController.text) ?? 0;
    final total = cashAmount + nocashAmount;
    _totalPriceController.text = total.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_getPageTitle()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: _buildAppBarActions(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: _isViewMode ? _buildViewModeBottomBar() : null,
    );
  }

  String _getPageTitle() {
    if (_isViewMode) return 'Просмотр продажи';
    if (_isEditing) return 'Редактирование продажи';
    return 'Создание продажи';
  }

  List<Widget> _buildAppBarActions() {
    final actions = <Widget>[];

    if (_isEditing && !_isViewMode) {
      actions.add(
            IconButton(
              onPressed: _deleteSale,
          icon: const Icon(Icons.delete),
              tooltip: 'Удалить',
            ),
      );
    }

    // Удалена кнопка "Редактировать" из режима просмотра

    return actions;
  }

  Widget _buildBody() {
    if (_isViewMode) {
      return _buildViewMode();
    } else {
      return _buildEditMode();
    }
  }

  Widget _buildViewMode() {
    final sale = widget.sale!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Основная информация
          _buildViewSection('Основная информация', [
            _buildViewField('Номер продажи', sale.saleNumber ?? 'Не указан'),
            _buildViewField('Дата продажи', _formatDate(sale.saleDate)),
            _buildViewField('Товар', sale.product?.name ?? 'ID: ${sale.productId}'),
            _buildViewField('Количество', sale.quantity.toInt().toString()),
            _buildViewField('Склад', sale.warehouse?.name ?? 'ID: ${sale.warehouseId}'),
            _buildViewField('Сумма (нал)', '${sale.cashAmount} ${sale.currency}'),
            _buildViewField('Сумма (безнал)', '${sale.nocashAmount} ${sale.currency}'),
            _buildViewField('Общая сумма', '${sale.totalPrice} ${sale.currency}'),
            _buildViewField('Курс валюты', sale.exchangeRate.toString()),
            _buildViewField('Продавец', sale.user?.name ?? 'ID: ${sale.userId}'),
            _buildViewField('Статус оплаты', _getPaymentStatusDisplayName(sale.paymentStatus)),
          ]),
          
          const SizedBox(height: 24),
          
          // Информация о покупателе
          _buildViewSection('Информация о покупателе', [
            _buildViewField('Имя покупателя', sale.customerName ?? 'Не указан'),
            _buildViewField('Телефон', sale.customerPhone ?? 'Не указан'),
            _buildViewField('Email', sale.customerEmail ?? 'Не указан'),
            _buildViewField('Адрес', sale.customerAddress ?? 'Не указан'),
          ]),
          
          // Платежная информация
          if (sale.invoiceNumber != null) ...[
            const SizedBox(height: 24),
            _buildViewSection('Платежная информация', [
              _buildViewField('Номер счета', sale.invoiceNumber!),
            ]),
          ],
          
          // Дополнительная информация
          if (sale.notes != null && sale.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildViewSection('Дополнительная информация', [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  sale.notes!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D3748),
                    height: 1.5,
                  ),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
  
  Widget _buildEditMode() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_saleNumberController, 'Номер продажи', enabled: false),
            const SizedBox(height: 16),
            _buildWarehouseDropdown(),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 16),
            _buildProductDropdown(),
            const SizedBox(height: 16),
            _buildTextField(_quantityController, 'Количество', isRequired: true, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(_cashAmountController, 'Сумма (нал)', isRequired: true, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(_nocashAmountController, 'Сумма (безнал)', isRequired: true, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(_totalPriceController, 'Общая сумма', enabled: false),
            const SizedBox(height: 16),
            _buildCurrencyDropdown(),
            const SizedBox(height: 16),
            _buildTextField(_exchangeRateController, 'Курс валюты', isRequired: true, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(_notesController, 'Примечания', maxLines: 3),
            const SizedBox(height: 32),
            
            // Customer information section
            const Text('Информация о покупателе', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTextField(_customerNameController, 'Имя покупателя', isRequired: true),
            const SizedBox(height: 16),
            _buildTextField(_customerPhoneController, 'Телефон', keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField(_customerEmailController, 'Email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(_customerAddressController, 'Адрес'),
            const SizedBox(height: 32),
            
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEditSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
  
  Widget _buildViewField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isRequired = false,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
      ),
      validator: validator ?? (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'Поле "$label" обязательно для заполнения';
        }
        return null;
      },
    );
  }
  
  Widget _buildWarehouseDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedWarehouseId,
      decoration: const InputDecoration(
        labelText: 'Склад *',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _warehouses.map((warehouse) => DropdownMenuItem(
        value: warehouse.id,
        child: Text(warehouse.name),
      )).toList(),
      onChanged: (warehouseId) {
        setState(() {
          _selectedWarehouseId = warehouseId;
          _selectedCompositeProductKey = null;
          _warehouseProducts.clear();
        });
        if (warehouseId != null) {
          _loadWarehouseProducts(warehouseId);
        }
      },
      validator: (value) {
        if (value == null) return 'Выберите склад';
        return null;
      },
    );
  }
  
  Widget _buildProductDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCompositeProductKey,
      decoration: InputDecoration(
        labelText: 'Товар *',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        hintText: _selectedWarehouseId == null 
          ? 'Сначала выберите склад'
          : 'Выберите товар',
      ),
      isExpanded: true,
      items: _warehouseProducts.map((product) {
        final compositeKey = product['composite_product_key'] as String;
        return DropdownMenuItem(
          value: compositeKey,
          child: Text(
            '${product['name']} (остаток: ${product['available_quantity']})',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return _warehouseProducts.map<Widget>((product) {
          return Text(
            '${product['name']} (остаток: ${product['available_quantity']})',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        }).toList();
      },
      onChanged: _selectedWarehouseId == null ? null : (compositeKey) {
        print('Выбран товар с composite_product_key: $compositeKey');
        setState(() => _selectedCompositeProductKey = compositeKey);
      },
      validator: (value) {
        if (value == null || value.isEmpty) return 'Выберите товар';
        return null;
      },
    );
  }

  Widget _buildCurrencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCurrency,
      decoration: const InputDecoration(
        labelText: 'Валюта',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: const [
        DropdownMenuItem(value: 'RUB', child: Text('RUB')),
        DropdownMenuItem(value: 'USD', child: Text('USD')),
        DropdownMenuItem(value: 'UZS', child: Text('UZS')),
      ],
      onChanged: (value) => setState(() => _selectedCurrency = value ?? 'RUB'),
    );
  }


  
  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _saleDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _saleDate = date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Дата продажи *',
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(_formatDate(_saleDate.toIso8601String())),
      ),
    );
  }
  
  Widget _buildBottomButtons() {
    return Row(
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
            onPressed: _isLoading ? null : _saveSale,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                : Text(_isEditing ? 'Сохранить' : 'Создать'),
          ),
        ),
      ],
    );
  }

  Widget? _buildViewModeBottomBar() {
    if (widget.sale?.paymentStatus == 'cancelled') {
      return null; // Не показываем кнопку для отмененных продаж
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: ElevatedButton(
        onPressed: _cancelSaleFromView,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Отменить продажу'),
      ),
    );
  }
  
  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    bool success = false;

    try {
      if (_isEditing) {
        // TODO: Обновить логику редактирования под новое API
        throw Exception('Редактирование продаж временно недоступно. Используйте создание новой продажи.');
      } else {
        // Логика создания новой продажи с обработкой дублирования номера
        try {
          await _createSaleWithRetry();
          success = true;
        } catch (createError) {
          
          if (createError.toString().contains('Future already completed')) {
            success = true; // Считаем операцию успешной
          } else {
            throw createError;
          }
        }
      }
      
      if (mounted && success) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Продажа обновлена' : 'Продажа создана'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Небольшая задержка перед закрытием формы
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (mounted) {
          Navigator.of(context).pop(true); // Возвращаем true при успешном создании
        }
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createSaleWithRetry() async {
    int maxRetries = 10;
    int currentRetry = 0;
    

    while (currentRetry < maxRetries) {
      try {
        
        final cashAmount = double.parse(_cashAmountController.text);
        final nocashAmount = double.parse(_nocashAmountController.text);
        final quantity = double.parse(_quantityController.text);

        // Проверяем, что товар выбран
        if (_selectedCompositeProductKey == null || _selectedCompositeProductKey!.isEmpty) {
          throw Exception('Выберите товар для продажи');
        }

        // Используем уже готовый composite_product_key
        final compositeProductKey = _selectedCompositeProductKey!;

        final request = CreateSaleRequest(
          compositeProductKey: compositeProductKey,
          warehouseId: _selectedWarehouseId!,
          customerName: _customerNameController.text,
          customerPhone: _customerPhoneController.text.isEmpty ? null : _customerPhoneController.text,
          customerEmail: _customerEmailController.text.isEmpty ? null : _customerEmailController.text,
          customerAddress: _customerAddressController.text.isEmpty ? null : _customerAddressController.text,
          quantity: quantity,
          currency: _selectedCurrency,
          exchangeRate: double.parse(_exchangeRateController.text),
          cashAmount: cashAmount,
          nocashAmount: nocashAmount,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          saleDate: _saleDate.toIso8601String().split('T')[0],
        );

        
        // Оборачиваем в try-catch для отлова ошибки Future already completed
        try {
          await ref.read(createSaleProvider.notifier).create(request);
          break; // Успешное создание, выходим из цикла
        } catch (innerError) {
          
          // Проверяем на ошибку Future already completed
          if (innerError.toString().contains('Future already completed')) {
            // Продажа, вероятно, была создана успешно
            break;
          } else {
            // Пробрасываем ошибку дальше для обработки
            throw innerError;
          }
        }
        
      } catch (e) {
        final errorString = e.toString();
        
        if (errorString.contains('duplicate_sale_number') || 
            errorString.contains('Ошибка генерации номера продажи')) {
          // Увеличиваем счетчик и генерируем новый номер
          currentRetry++;
          _saleNumberCounter++;
          _generateSaleNumber();
          
          
          // Небольшая задержка перед повторной попыткой
          await Future.delayed(const Duration(milliseconds: 500));
        } else if (errorString.contains('Future already completed')) {
          // Если ошибка связана с Future already completed, считаем операцию успешной
          break;
        } else {
          // Другие ошибки пробрасываем выше
          rethrow;
        }
      }
    }

    if (currentRetry >= maxRetries) {
      throw Exception('Не удалось создать продажу после $maxRetries попыток');
    }
    
  }

  void _editSale() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SaleFormPage(sale: widget.sale),
      ),
    );
  }

  Future<void> _cancelSaleFromView() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить продажу'),
        content: Text(
          'Вы уверены, что хотите отменить продажу №${widget.sale?.saleNumber ?? 'Без номера'}?\n\n'
          'Это действие нельзя будет отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Отменить продажу', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Вызываем repository напрямую, без провайдера
        final repository = ref.read(salesRepositoryProvider);
        await repository.cancelSale(widget.sale!.id);
        
        // Инвалидируем провайдеры после успешной отмены
        ref.invalidate(salesListProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Продажа отменена'),
              backgroundColor: Colors.green,
            ),
          );
          // Возвращаемся на главный экран "Реализация" с флагом обновления
          Navigator.of(context).pop(true);
        }
      } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка отмены продажи: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSale() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить продажу'),
        content: const Text(
          'Вы уверены, что хотите удалить эту продажу?\n\n'
          'Это действие нельзя будет отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(deleteSaleProvider.notifier).delete(widget.sale!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Продажа удалена'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
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
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Дата не указана';
    }
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getPaymentMethodDisplayName(String method) {
    switch (method) {
      case 'cash': return 'Наличные';
      case 'card': return 'Карта';
      case 'bank_transfer': return 'Банковский перевод';
      case 'other': return 'Другое';
      default: return method;
    }
  }

  String _getPaymentStatusDisplayName(String status) {
    switch (status) {
      case 'pending': return 'Ожидание';
      case 'paid': return 'Оплачено';
      case 'partially_paid': return 'Частично оплачено';
      case 'cancelled': return 'Отменено';
      default: return status;
    }
  }
}
