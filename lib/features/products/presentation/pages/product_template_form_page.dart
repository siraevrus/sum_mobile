import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/products/domain/entities/product_template_entity.dart';

/// Экран создания/редактирования шаблона товара
class ProductTemplateFormPage extends ConsumerStatefulWidget {
  final ProductTemplateEntity? template;
  
  const ProductTemplateFormPage({
    super.key,
    this.template,
  });

  @override
  ConsumerState<ProductTemplateFormPage> createState() => _ProductTemplateFormPageState();
}

class _ProductTemplateFormPageState extends ConsumerState<ProductTemplateFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formulaController = TextEditingController();
  
  bool _isActive = true;
  bool _isLoading = false;
  List<TemplateAttributeEntity> _attributes = [];
  
  bool get _isEditing => widget.template != null;
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _formulaController.dispose();
    super.dispose();
  }
  
  void _initializeForm() {
    if (_isEditing) {
      final template = widget.template!;
      _nameController.text = template.name;
      _unitController.text = template.unit;
      _descriptionController.text = template.description ?? '';
      _formulaController.text = template.formula ?? '';
      _isActive = template.isActive;
      _attributes = List.from(template.attributes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать шаблон' : 'Новый шаблон'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTemplate,
            ),
          TextButton(
            onPressed: _isLoading ? null : _testFormula,
            child: const Text(
              'Тест',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация
              _buildSectionTitle('Основная информация'),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _nameController,
                label: 'Название шаблона',
                hint: 'Доски обрезные, Кирпич и т.д.',
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Название шаблона обязательно';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _unitController,
                label: 'Единица измерения',
                hint: 'м³, шт, кг, л и т.д.',
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Единица измерения обязательна';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _descriptionController,
                label: 'Описание',
                hint: 'Краткое описание шаблона товара',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Формула расчета
              _buildSectionTitle('Формула расчета (опционально)'),
              const SizedBox(height: 8),
              Text(
                'Используйте переменные из характеристик для автоматического расчета объема, площади и т.д.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _formulaController,
                label: 'Формула',
                hint: 'length * width * height / 1000000',
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              // Характеристики
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Характеристики (${_attributes.length})'),
                  ElevatedButton.icon(
                    onPressed: _addAttribute,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Добавить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_attributes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.list_alt, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Пока нет характеристик',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Добавьте характеристики для детального описания товаров',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...(_attributes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final attribute = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAttributeCard(attribute, index),
                  );
                })),
              
              const SizedBox(height: 24),
              
              // Статус
              _buildSectionTitle('Статус'),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Активный шаблон'),
                subtitle: Text(_isActive 
                    ? 'Шаблон доступен для создания товаров'
                    : 'Шаблон скрыт из списка'),
                value: _isActive,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 32),
              
              // Кнопки действий
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
                      onPressed: _isLoading ? null : _saveTemplate,
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
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
  
  Widget _buildAttributeCard(TemplateAttributeEntity attribute, int index) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Порядок
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Название и тип
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attribute.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTypeColor(attribute.type).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              attribute.type.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                color: _getTypeColor(attribute.type),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (attribute.isRequired) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Обязательно',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          if (attribute.isInFormula) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'В формуле',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Действия
                PopupMenuButton<String>(
                  onSelected: (action) => _handleAttributeAction(action, index),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Редактировать'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Удалить', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert, size: 18),
                ),
              ],
            ),
            
            if (attribute.unit != null || attribute.defaultValue != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (attribute.variable.isNotEmpty) ...[
                    Text(
                      'Переменная: ${attribute.variable}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (attribute.unit != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• Ед.: ${attribute.unit}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                  if (attribute.defaultValue != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• По умолч.: ${attribute.defaultValue}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Color _getTypeColor(AttributeType type) {
    switch (type) {
      case AttributeType.number:
        return AppColors.primary;
      case AttributeType.text:
        return AppColors.info;
      case AttributeType.select:
        return AppColors.success;
      case AttributeType.boolean:
        return AppColors.warning;
      case AttributeType.date:
        return Colors.purple;
      case AttributeType.file:
        return Colors.orange;
    }
  }
  
  void _addAttribute() {
    _showAttributeDialog();
  }
  
  void _handleAttributeAction(String action, int index) {
    switch (action) {
      case 'edit':
        _showAttributeDialog(attribute: _attributes[index], index: index);
        break;
      case 'delete':
        _deleteAttribute(index);
        break;
    }
  }
  
  void _deleteAttribute(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить характеристику'),
        content: Text('Удалить характеристику "${_attributes[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _attributes.removeAt(index);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showAttributeDialog({TemplateAttributeEntity? attribute, int? index}) {
    showDialog(
      context: context,
      builder: (context) => AttributeFormDialog(
        attribute: attribute,
        onSave: (newAttribute) {
          setState(() {
            if (index != null) {
              _attributes[index] = newAttribute;
            } else {
              _attributes.add(newAttribute);
            }
          });
        },
        existingVariables: _attributes
            .where((attr) => attr != attribute)
            .map((attr) => attr.variable)
            .toList(),
      ),
    );
  }
  
  void _testFormula() {
    if (_formulaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите формулу для тестирования')),
      );
      return;
    }
    
    // TODO: Реализовать тестирование формулы
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Тестирование формул - в разработке')),
    );
  }
  
  void _saveTemplate() {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // TODO: Реализовать сохранение через провайдер
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Шаблон "${_nameController.text}" обновлен' 
                : 'Шаблон "${_nameController.text}" создан'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    });
  }
  
  void _deleteTemplate() {
    if (!_isEditing) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить шаблон'),
        content: Text(
          'Вы уверены, что хотите удалить шаблон "${widget.template!.name}"?\n\n'
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
    
    // TODO: Реализовать удаление через провайдер
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Шаблон "${widget.template!.name}" удален'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    });
  }
}

/// Диалог для создания/редактирования характеристики
class AttributeFormDialog extends StatefulWidget {
  final TemplateAttributeEntity? attribute;
  final Function(TemplateAttributeEntity) onSave;
  final List<String> existingVariables;
  
  const AttributeFormDialog({
    super.key,
    this.attribute,
    required this.onSave,
    required this.existingVariables,
  });

  @override
  State<AttributeFormDialog> createState() => _AttributeFormDialogState();
}

class _AttributeFormDialogState extends State<AttributeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _variableController = TextEditingController();
  final _defaultValueController = TextEditingController();
  final _unitController = TextEditingController();
  
  AttributeType _selectedType = AttributeType.text;
  bool _isRequired = false;
  bool _isInFormula = false;
  List<String> _selectOptions = [];
  
  bool get _isEditing => widget.attribute != null;
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _variableController.dispose();
    _defaultValueController.dispose();
    _unitController.dispose();
    super.dispose();
  }
  
  void _initializeForm() {
    if (_isEditing) {
      final attr = widget.attribute!;
      _nameController.text = attr.name;
      _variableController.text = attr.variable;
      _defaultValueController.text = attr.defaultValue ?? '';
      _unitController.text = attr.unit ?? '';
      _selectedType = attr.type;
      _isRequired = attr.isRequired;
      _isInFormula = attr.isInFormula;
      _selectOptions = List.from(attr.selectOptions ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Редактировать характеристику' : 'Новая характеристика',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Название
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название *',
                    hintText: 'Длина, Ширина, Цвет и т.д.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Название обязательно';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_variableController.text.isEmpty || 
                        !widget.existingVariables.contains(_variableController.text)) {
                      _variableController.text = _generateVariable(value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Переменная
                TextFormField(
                  controller: _variableController,
                  decoration: const InputDecoration(
                    labelText: 'Переменная для формул *',
                    hintText: 'length, width, color и т.д.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Переменная обязательна';
                    }
                    if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(value)) {
                      return 'Некорректная переменная (только латинские буквы, цифры, _)';
                    }
                    if (widget.existingVariables.contains(value) && 
                        value != widget.attribute?.variable) {
                      return 'Переменная уже используется';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Тип
                DropdownButtonFormField<AttributeType>(
        dropdownColor: Colors.white,
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Тип данных',
                    border: OutlineInputBorder(),
                  ),
                  items: AttributeType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  )).toList(),
                  onChanged: (type) {
                    setState(() {
                      _selectedType = type!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Единица измерения (для числовых)
                if (_selectedType == AttributeType.number) ...[
                  TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Единица измерения',
                      hintText: 'мм, см, кг, л и т.д.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Значение по умолчанию
                TextFormField(
                  controller: _defaultValueController,
                  decoration: const InputDecoration(
                    labelText: 'Значение по умолчанию',
                    hintText: 'Заполняется автоматически при создании товара',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Опции для select
                if (_selectedType == AttributeType.select) ...[
                  Row(
                    children: [
                      Text(
                        'Варианты выбора (${_selectOptions.length})',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addSelectOption,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Добавить'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_selectOptions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Нет вариантов выбора',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...(_selectOptions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).inputDecorationTheme.fillColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(option),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeSelectOption(index),
                              icon: const Icon(Icons.close, size: 18),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      );
                    })),
                  const SizedBox(height: 16),
                ],
                
                // Параметры
                CheckboxListTile(
                  title: const Text('Обязательное поле'),
                  subtitle: const Text('Поле должно быть заполнено при создании товара'),
                  value: _isRequired,
                  onChanged: (value) {
                    setState(() {
                      _isRequired = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                
                if (_selectedType == AttributeType.number) ...[
                  CheckboxListTile(
                    title: const Text('Использовать в формулах'),
                    subtitle: const Text('Переменная доступна для математических расчетов'),
                    value: _isInFormula,
                    onChanged: (value) {
                      setState(() {
                        _isInFormula = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Кнопки
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveAttribute,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isEditing ? 'Сохранить' : 'Добавить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _generateVariable(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9а-яёА-ЯЁ]'), '_')
        .replaceAll('а', 'a').replaceAll('б', 'b').replaceAll('в', 'v')
        .replaceAll('г', 'g').replaceAll('д', 'd').replaceAll('е', 'e')
        .replaceAll('ё', 'e').replaceAll('ж', 'zh').replaceAll('з', 'z')
        .replaceAll('и', 'i').replaceAll('й', 'y').replaceAll('к', 'k')
        .replaceAll('л', 'l').replaceAll('м', 'm').replaceAll('н', 'n')
        .replaceAll('о', 'o').replaceAll('п', 'p').replaceAll('р', 'r')
        .replaceAll('с', 's').replaceAll('т', 't').replaceAll('у', 'u')
        .replaceAll('ф', 'f').replaceAll('х', 'h').replaceAll('ц', 'ts')
        .replaceAll('ч', 'ch').replaceAll('ш', 'sh').replaceAll('щ', 'sch')
        .replaceAll('ъ', '').replaceAll('ы', 'y').replaceAll('ь', '')
        .replaceAll('э', 'e').replaceAll('ю', 'yu').replaceAll('я', 'ya')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
  
  void _addSelectOption() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Добавить вариант'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Значение',
              hintText: 'Вариант выбора',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _selectOptions.add(controller.text.trim());
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }
  
  void _removeSelectOption(int index) {
    setState(() {
      _selectOptions.removeAt(index);
    });
  }
  
  void _saveAttribute() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedType == AttributeType.select && _selectOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один вариант выбора')),
      );
      return;
    }
    
    final attribute = TemplateAttributeEntity(
      id: widget.attribute?.id ?? DateTime.now().millisecondsSinceEpoch,
      productTemplateId: widget.attribute?.productTemplateId ?? 0,
      name: _nameController.text.trim(),
      variable: _variableController.text.trim(),
      type: _selectedType,
      defaultValue: _defaultValueController.text.trim().isEmpty 
          ? null 
          : _defaultValueController.text.trim(),
      unit: _unitController.text.trim().isEmpty 
          ? null 
          : _unitController.text.trim(),
      isRequired: _isRequired,
      isInFormula: _isInFormula,
      sortOrder: widget.attribute?.sortOrder ?? 0,
      selectOptions: _selectedType == AttributeType.select ? _selectOptions : null,
    );
    
    widget.onSave(attribute);
    Navigator.of(context).pop();
  }
}
