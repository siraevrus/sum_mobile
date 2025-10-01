import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/products/data/datasources/products_api_datasource.dart';
import 'package:sum_warehouse/features/products/data/datasources/product_template_remote_datasource.dart';
import 'package:sum_warehouse/features/products/data/models/product_template_model.dart';
import 'package:sum_warehouse/features/products/domain/entities/product_template_entity.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';
import 'package:sum_warehouse/shared/models/product_model.dart';
import 'package:sum_warehouse/features/producers/presentation/providers/producers_provider.dart';

/// Форма для создания нового остатка (товара на складе)
class CreateStockFormPage extends ConsumerStatefulWidget {
  const CreateStockFormPage({super.key});

  @override
  ConsumerState<CreateStockFormPage> createState() => _CreateStockFormPageState();
}

class _CreateStockFormPageState extends ConsumerState<CreateStockFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _transportNumberController = TextEditingController();
  
  bool _isLoading = false;
  bool _isActive = true;
  int? _selectedWarehouseId;
  int? _selectedTemplateId;
  int? _selectedProducerId;
  DateTime? _arrivalDate;
  
  // Данные из API
  List<WarehouseModel> _warehouses = [];
  List<ProductTemplateModel> _productTemplates = [];
  List<TemplateAttributeModel> _templateAttributes = [];
  
  // Динамические контроллеры для атрибутов
  Map<String, TextEditingController> _attributeControllers = {};
  Map<String, String?> _attributeValues = {};

  @override
  void initState() {
    super.initState();
    // Загружаем производителей
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(producersProvider.notifier).loadProducers();
    });
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _transportNumberController.dispose();
    _attributeControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Загружаем склады
      final warehousesDataSource = ref.read(warehousesRemoteDataSourceProvider);
      final warehousesResponse = await warehousesDataSource.getWarehouses(perPage: 100);
      _warehouses = warehousesResponse.data;
      
      // Загружаем шаблоны товаров
      final templatesDataSource = ref.read(productTemplateRemoteDataSourceProvider);
      final templatesResponse = await templatesDataSource.getProductTemplates(perPage: 100);
      _productTemplates = templatesResponse.data;
      
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTemplateAttributes(int templateId) async {
    try {
      final templatesDataSource = ref.read(productTemplateRemoteDataSourceProvider);
      _templateAttributes = await templatesDataSource.getTemplateAttributes(templateId);
      
      // Создаем контроллеры для каждого атрибута
      _attributeControllers.clear();
      _attributeValues.clear();
      
      for (final attribute in _templateAttributes) {
        _attributeControllers[attribute.variable] = TextEditingController();
        _attributeValues[attribute.variable] = attribute.defaultValue;
        if (attribute.defaultValue != null) {
          _attributeControllers[attribute.variable]!.text = attribute.defaultValue!;
        }
      }
      
      setState(() {});
    } catch (e) {
      print('Ошибка загрузки атрибутов шаблона: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Создать Остаток'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Склад
                    DropdownButtonFormField<int>(
        dropdownColor: Colors.white,
                      value: _selectedWarehouseId,
                      decoration: const InputDecoration(
                        labelText: 'Склад*',
                        border: OutlineInputBorder(),
                      ),
                      items: _warehouses.map((warehouse) {
                        return DropdownMenuItem(
                          value: warehouse.id,
                          child: Text(warehouse.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedWarehouseId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Выберите склад';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Производитель
                    _buildProducerDropdown(),
                    const SizedBox(height: 16),

                    // Дата поступления
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _arrivalDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() {
                            _arrivalDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Дата поступления*',
                          border: const OutlineInputBorder(),
                          errorText: _arrivalDate == null ? 'Выберите дату поступления' : null,
                        ),
                        child: Text(
                          _arrivalDate != null
                              ? '${_arrivalDate!.day.toString().padLeft(2, '0')}.${_arrivalDate!.month.toString().padLeft(2, '0')}.${_arrivalDate!.year}'
                              : 'Выберите дату',
                          style: TextStyle(
                            color: _arrivalDate != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Номер транспорта
                    TextFormField(
                      controller: _transportNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Номер транспорта',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Шаблон товара
                    DropdownButtonFormField<int>(
        dropdownColor: Colors.white,
                      value: _selectedTemplateId,
                      decoration: const InputDecoration(
                        labelText: 'Шаблон товара*',
                        border: OutlineInputBorder(),
                      ),
                      items: _productTemplates.map((template) {
                        return DropdownMenuItem(
                          value: template.id,
                          child: Text(template.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTemplateId = value;
                        });
                        if (value != null) {
                          _loadTemplateAttributes(value);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Выберите шаблон товара';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Наименование
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Наименование*',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите наименование';
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
                        labelText: 'Количество*',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
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

                    // Характеристики товара
                    if (_templateAttributes.isNotEmpty) ...[
                      const Text(
                        'Характеристики товара',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._templateAttributes.map((attribute) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildAttributeField(attribute),
                      )),
                    ],

                    // Переключатель активности
                    SwitchListTile(
                      title: const Text('Активен'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Заметки (описание) - перенесено в самый низ
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Заметки',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Кнопки
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Отменить'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProduct,
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

  Widget _buildAttributeField(TemplateAttributeModel attribute) {
    switch (attribute.attributeType) {
      case AttributeType.text:
      case AttributeType.number:
        return TextFormField(
          controller: _attributeControllers[attribute.variable]!,
          keyboardType: attribute.attributeType == AttributeType.number 
            ? TextInputType.number 
            : TextInputType.text,
          decoration: InputDecoration(
            labelText: '${attribute.name}${attribute.unit != null ? ' (${attribute.unit})' : ''}${attribute.isRequired ? '*' : ''}',
            border: const OutlineInputBorder(),
          ),
          validator: attribute.isRequired ? (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Введите ${attribute.name.toLowerCase()}';
            }
            return null;
          } : null,
        );
      case AttributeType.select:
        return _buildSelectField(attribute);
      case AttributeType.boolean:
        return _buildBooleanField(attribute);
      default:
        return TextFormField(
          controller: _attributeControllers[attribute.variable]!,
          decoration: InputDecoration(
            labelText: '${attribute.name}${attribute.isRequired ? '*' : ''}',
            border: const OutlineInputBorder(),
          ),
          validator: attribute.isRequired ? (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Введите ${attribute.name.toLowerCase()}';
            }
            return null;
          } : null,
        );
    }
  }

  Widget _buildSelectField(TemplateAttributeModel attribute) {
    List<String> options = [];
    
    if (attribute.selectOptions != null && attribute.selectOptions!.isNotEmpty) {
      options = attribute.selectOptions!;
    } else if (attribute.options != null) {
      if (attribute.options is List) {
        options = (attribute.options as List).map((e) => e.toString()).toList();
      } else if (attribute.options is String) {
        options = (attribute.options as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }
    
    if (options.isEmpty) {
      options = ['Опция 1', 'Опция 2', 'Опция 3'];
    }

    return DropdownButtonFormField<String>(
        dropdownColor: Colors.white,
      value: _attributeValues[attribute.variable],
      decoration: InputDecoration(
        labelText: '${attribute.name}${attribute.isRequired ? '*' : ''}',
        border: const OutlineInputBorder(),
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _attributeValues[attribute.variable] = value;
        });
      },
      validator: attribute.isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return 'Выберите ${attribute.name.toLowerCase()}';
        }
        return null;
      } : null,
    );
  }

  Widget _buildBooleanField(TemplateAttributeModel attribute) {
    final currentValue = _attributeValues[attribute.variable] == 'true';
    
    return SwitchListTile(
      title: Text('${attribute.name}${attribute.isRequired ? '*' : ''}'),
      value: currentValue,
      onChanged: (value) {
        setState(() {
          _attributeValues[attribute.variable] = value.toString();
        });
      },
    );
  }
  
  Widget _buildProducerDropdown() {
    return Consumer(
      builder: (context, ref, child) {
        final producersAsync = ref.watch(producersProvider);
        
        return producersAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Ошибка загрузки производителей: $error'),
          data: (producers) {
            return DropdownButtonFormField<int>(
              value: _selectedProducerId,
              decoration: const InputDecoration(
                labelText: 'Производитель',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Не выбран'),
                ),
                ...producers.map((producer) {
                  return DropdownMenuItem<int>(
                    value: producer.id,
                    child: Text(producer.name),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedProducerId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Выберите производителя';
                }
                return null;
              },
            );
          },
        );
      },
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_arrivalDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите дату поступления'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final dataSource = ref.read(productsApiDataSourceProvider);
      
      // Собираем значения атрибутов
      final attributes = <String, dynamic>{};
      for (final entry in _attributeControllers.entries) {
        final value = entry.value.text.trim();
        if (value.isNotEmpty) {
          attributes[entry.key] = value;
        }
      }
      for (final entry in _attributeValues.entries) {
        if (entry.value != null && entry.value!.isNotEmpty) {
          attributes[entry.key] = entry.value;
        }
      }
      
      final createRequest = CreateProductRequest(
        productTemplateId: _selectedTemplateId!,
        warehouseId: _selectedWarehouseId!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        quantity: double.parse(_quantityController.text),
        producerId: _selectedProducerId,
        transportNumber: _transportNumberController.text.trim().isEmpty ? null : _transportNumberController.text.trim(),
        arrivalDate: _arrivalDate!,
        isActive: _isActive,
        attributes: attributes,
      );
      
      await dataSource.createProduct(createRequest);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Остаток создан успешно'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Ошибка создания остатка: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания остатка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
