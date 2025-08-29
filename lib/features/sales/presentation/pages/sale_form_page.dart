import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/sales/data/datasources/sales_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/sale_model.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';

/// Экран создания/редактирования реализации (продажи)
class SaleFormPage extends ConsumerStatefulWidget {
  final SaleModel? sale;
  
  const SaleFormPage({
    super.key,
    this.sale,
  });

  @override
  ConsumerState<SaleFormPage> createState() => _SaleFormPageState();
}

class _SaleFormPageState extends ConsumerState<SaleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _saleNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _cashAmountController = TextEditingController();
  final _nocashAmountController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _currencyController = TextEditingController();
  
  bool _isLoading = false;
  DateTime _saleDate = DateTime.now();
  int? _selectedWarehouseId;
  int? _selectedProductId;
  
  // Данные из API
  List<WarehouseModel> _warehouses = [];
  List<Map<String, dynamic>> _warehouseProducts = [];
  
  bool get _isEditing => widget.sale != null;
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
    // При редактировании данные уже есть, загружаем только справочники
    if (_isEditing) {
      _loadReferenceData();
    } else {
      _loadData();
    }
  }
  
  @override
  void dispose() {
    _saleNumberController.dispose();
    _quantityController.dispose();
    _cashAmountController.dispose();
    _nocashAmountController.dispose();
    _totalAmountController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  void _initializeForm() {
    if (_isEditing) {
      final sale = widget.sale!;
      _saleNumberController.text = sale.saleNumber ?? '';
      _quantityController.text = sale.quantity?.toString() ?? '';
      _cashAmountController.text = sale.cashAmount?.toString() ?? '';
      _nocashAmountController.text = sale.nocashAmount?.toString() ?? '';
      _totalAmountController.text = sale.totalPrice?.toString() ?? '';
      _customerNameController.text = sale.customerName ?? '';
      _customerPhoneController.text = sale.customerPhone ?? '';
      _notesController.text = sale.notes ?? '';
      _currencyController.text = sale.currency ?? '';
      _saleDate = DateTime.parse(sale.saleDate);
      _selectedWarehouseId = sale.warehouseId;
      // Безопасное преобразование productId к int
      _selectedProductId = sale.productId;
    } else {
      // Автогенерация номера продажи
      _generateSaleNumber();
      _quantityController.text = '1';
      _cashAmountController.text = '0';
      _nocashAmountController.text = '0';
      _totalAmountController.text = '0';
      _currencyController.text = 'RUB';
    }
    
    // Подписываемся на изменения сумм для автоматического расчета общей суммы
    _cashAmountController.addListener(_calculateTotalAmount);
    _nocashAmountController.addListener(_calculateTotalAmount);
  }
  
  void _generateSaleNumber() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final increment = '0003'; // TODO: Получить реальный инкремент из API
    _saleNumberController.text = 'SALE-$year$month-$increment';
  }
  
  void _calculateTotalAmount() {
    final cashAmount = double.tryParse(_cashAmountController.text) ?? 0;
    final nocashAmount = double.tryParse(_nocashAmountController.text) ?? 0;
    final total = cashAmount + nocashAmount;
    _totalAmountController.text = total.toString();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Загружаем склады
      final warehousesDataSource = ref.read(warehousesRemoteDataSourceProvider);
      final warehousesResponse = await warehousesDataSource.getWarehouses(perPage: 100);
      _warehouses = warehousesResponse.data;
      
      setState(() {});
    } catch (e) {
      print('Ошибка загрузки данных: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  // Загрузка справочных данных для формы редактирования (без полноэкранного лоадера)
  Future<void> _loadReferenceData() async {
    try {
      // Загружаем склады
      final warehousesDataSource = ref.read(warehousesRemoteDataSourceProvider);
      final warehousesResponse = await warehousesDataSource.getWarehouses(perPage: 100);
      _warehouses = warehousesResponse.data;
      
      // Загружаем товары выбранного склада
      if (_selectedWarehouseId != null) {
        await _loadWarehouseProducts(_selectedWarehouseId!);
      }
      
      setState(() {});
    } catch (e) {
      print('Ошибка загрузки справочных данных: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadWarehouseProducts(int warehouseId) async {
    try {
      final warehousesDataSource = ref.read(warehousesRemoteDataSourceProvider);
      _warehouseProducts = await warehousesDataSource.getWarehouseProducts(warehouseId);
      setState(() {});
    } catch (e) {
      print('Ошибка загрузки товаров склада: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование Реализация' : 'Создать Реализацию'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _deleteSale,
              icon: const Icon(Icons.delete, color: Colors.white),
              tooltip: 'Удалить',
            ),
        ],
      ),
      
      body: (_isLoading && !_isEditing)
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfoSection(),
                  const SizedBox(height: 32),
                  _buildClientInfoSection(),
                  const SizedBox(height: 32),
                  _buildAdditionalInfoSection(),
                  const SizedBox(height: 32),
                  _buildBottomButtons(),
                ],
              ),
            ),
          ),
    );
  }
  
  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Основная информация'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _saleNumberController,
          label: 'Номер продажи',
          isRequired: true,
          enabled: false, // Номер не редактируется
        ),
        const SizedBox(height: 16),

        _buildWarehouseDropdown(),
        const SizedBox(height: 16),

        _buildProductDropdown(),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _quantityController,
          label: 'Количество',
          isRequired: true,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _cashAmountController,
          label: 'Сумма (нал)',
          isRequired: false,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _nocashAmountController,
          label: 'Сумма (безнал)',
          isRequired: false,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _totalAmountController,
          label: 'Общая сумма',
          isRequired: false,
          keyboardType: TextInputType.number,
          enabled: false, // Рассчитывается автоматически
        ),
        const SizedBox(height: 16),

        _buildDateField(),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _currencyController,
          label: 'Валюта',
          isRequired: false,
          enabled: true,
        ),
      ],
    );
  }
  
  Widget _buildClientInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Информация о клиенте'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _customerNameController,
          label: 'Имя клиента',
          isRequired: false,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _customerPhoneController,
          label: 'Телефон клиента',
          isRequired: false,
          keyboardType: TextInputType.phone,
          icon: Icons.call,
        ),
      ],
    );
  }
  
  Widget _buildAdditionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Дополнительная информация'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _notesController,
          label: 'Заметки',
          isRequired: false,
          maxLines: 4,
        ),
      ],
    );
  }
  
  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(color: Colors.grey.shade500),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.white,
        suffixIcon: icon != null ? Icon(icon, color: Colors.grey.shade600) : null,
      ),
      style: const TextStyle(color: Colors.black87),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator ?? (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return '$label обязательно для заполнения';
        }
        return null;
      },
    );
  }
  
  Widget _buildWarehouseDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedWarehouseId,
      decoration: InputDecoration(
        labelText: 'Склад *',
        labelStyle: TextStyle(color: Colors.grey.shade500),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
      ),
      style: const TextStyle(color: Colors.black87),
      dropdownColor: Colors.white,
      items: _warehouses.map((warehouse) => DropdownMenuItem(
        value: warehouse.id,
        child: Text(warehouse.name),
      )).toList(),
      onChanged: (warehouseId) {
        setState(() {
          _selectedWarehouseId = warehouseId;
          _selectedProductId = null; // Сбрасываем выбранный товар
          _warehouseProducts.clear();
        });
        if (warehouseId != null) {
          _loadWarehouseProducts(warehouseId);
        }
      },
      validator: (value) {
        if (value == null) {
          return 'Выберите склад';
        }
        return null;
      },
    );
  }
  
  Widget _buildProductDropdown() {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      value: _selectedProductId,
      decoration: InputDecoration(
        labelText: 'Товар *',
        labelStyle: TextStyle(color: Colors.grey.shade500),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        hintText: _selectedWarehouseId == null 
          ? 'Сначала выберите склад'
          : 'Выберите товар',
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      style: const TextStyle(color: Colors.black87),
      dropdownColor: Colors.white,
      items: _warehouseProducts.map((product) => DropdownMenuItem(
        value: product['id'] as int,
        child: Text(
          '${product['name']} (остаток: ${product['quantity']})',
          overflow: TextOverflow.ellipsis,
        ),
      )).toList(),
      // Ensure selected item text also respects ellipsis by providing
      // a custom selectedItemBuilder that wraps text with ellipsis.
      selectedItemBuilder: (context) => _warehouseProducts.map((product) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${product['name']} (остаток: ${product['quantity']})',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _selectedWarehouseId == null ? null : (productId) {
        setState(() {
          _selectedProductId = productId;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Выберите товар';
        }
        return null;
      },
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
        decoration: InputDecoration(
          labelText: 'Дата продажи *',
          labelStyle: TextStyle(color: Colors.grey.shade500),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          suffixIcon: Icon(Icons.calendar_today, color: Colors.grey.shade600),
        ),
        child: Text(
          '${_saleDate.day.toString().padLeft(2, '0')}.${_saleDate.month.toString().padLeft(2, '0')}.${_saleDate.year}',
          style: const TextStyle(color: Colors.black87),
        ),
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
  
  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataSource = ref.read(salesRemoteDataSourceProvider);
      
      if (_isEditing) {
        // Обновление существующей продажи согласно OpenAPI спецификации
        final updateRequest = UpdateSaleRequest(
          productId: _selectedProductId,
          warehouseId: _selectedWarehouseId!,
          quantity: double.parse(_quantityController.text),
          cashAmount: double.tryParse(_cashAmountController.text) ?? 0.0,
          nocashAmount: double.tryParse(_nocashAmountController.text) ?? 0.0,
          currency: _currencyController.text.isEmpty ? null : _currencyController.text,
          saleDate: _saleDate.toIso8601String().split('T')[0],
          customerName: _customerNameController.text.isEmpty ? null : _customerNameController.text,
          customerPhone: _customerPhoneController.text.isEmpty ? null : _customerPhoneController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
        
        if (widget.sale?.id != null && _selectedWarehouseId != null) {
          await dataSource.updateSale(widget.sale!.id!, updateRequest);
        }
      } else {
        // Создание новой продажи согласно OpenAPI спецификации
        final quantity = double.parse(_quantityController.text);
        final cashAmount = double.tryParse(_cashAmountController.text) ?? 0.0;
        final nocashAmount = double.tryParse(_nocashAmountController.text) ?? 0.0;



        if (_selectedWarehouseId != null) {
          final createRequest = CreateSaleRequest(
            productId: _selectedProductId ?? 0, // ID товара как int
            warehouseId: _selectedWarehouseId!,
            quantity: quantity,
            cashAmount: cashAmount, // ОБЯЗАТЕЛЬНОЕ поле API
            nocashAmount: nocashAmount, // ОБЯЗАТЕЛЬНОЕ поле API
            currency: _currencyController.text.isEmpty ? null : _currencyController.text,
            saleDate: _saleDate.toIso8601String().split('T')[0],
            customerName: _customerNameController.text.isEmpty ? null : _customerNameController.text,
            customerPhone: _customerPhoneController.text.isEmpty ? null : _customerPhoneController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );

          await dataSource.createSale(createRequest);
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Реализация обновлена' 
                : 'Реализация создана'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _deleteSale() {
    if (!_isEditing) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить реализацию'),
        content: const Text(
          'Вы уверены, что хотите удалить эту реализацию?\n\n'
          'Это действие нельзя будет отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performDelete() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataSource = ref.read(salesRemoteDataSourceProvider);
      if (widget.sale?.id != null) {
        await dataSource.deleteSale(widget.sale!.id!);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Реализация удалена'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}