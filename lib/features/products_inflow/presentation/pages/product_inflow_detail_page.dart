import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/products_inflow/data/models/product_inflow_model.dart';
import 'package:sum_warehouse/features/products_inflow/presentation/pages/product_inflow_form_page.dart';
import 'package:sum_warehouse/features/products_inflow/data/datasources/products_inflow_remote_datasource.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';

/// Страница детального просмотра товара
class ProductInflowDetailPage extends ConsumerStatefulWidget {
  final ProductInflowModel product;

  const ProductInflowDetailPage({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductInflowDetailPage> createState() => _ProductInflowDetailPageState();
}

class _ProductInflowDetailPageState extends ConsumerState<ProductInflowDetailPage> {
  Map<String, String>? _attributeNames; // Кэш названий атрибутов
  bool _isLoadingAttributes = false;

  @override
  void initState() {
    super.initState();
    _loadProductTemplate();
  }

  Future<void> _loadProductTemplate() async {
    if (widget.product.productTemplateId == null) return;
    
    setState(() => _isLoadingAttributes = true);
    
    try {
      print('🔵 ProductInflowDetailPage: Загружаем шаблон товара ID: ${widget.product.productTemplateId}');
      
      // Отправляем запрос на /product-templates/{id}
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('/product-templates/${widget.product.productTemplateId}');
      
      print('🔵 ProductInflowDetailPage: Ответ API /product-templates: ${response.data}');
      
      final data = response.data;
      print('🔵 ProductInflowDetailPage: Тип ответа: ${data.runtimeType}');
      
      // Проверяем структуру ответа - может быть {success: true, data: {...}} или прямая структура
      Map<String, dynamic>? templateData;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] != null) {
          // Формат {success: true, data: {...}}
          templateData = data['data'] as Map<String, dynamic>;
          print('🔵 ProductInflowDetailPage: Используем data из success/data структуры');
        } else {
          // Прямой формат
          templateData = data;
          print('🔵 ProductInflowDetailPage: Используем прямой формат');
        }
      }
      
      if (templateData != null && templateData['attributes'] != null) {
        final attributes = templateData['attributes'] as List<dynamic>;
        final attributeNames = <String, String>{};
        
        for (final attr in attributes) {
          if (attr is Map<String, dynamic>) {
            final variable = attr['variable'] as String?;
            final name = attr['name'] as String?;
            if (variable != null && name != null) {
              attributeNames[variable] = name;
            }
          }
        }
        
        print('🔵 ProductInflowDetailPage: Загружены названия атрибутов: $attributeNames');
        setState(() {
          _attributeNames = attributeNames;
          _isLoadingAttributes = false;
        });
      } else {
        print('🔵 ProductInflowDetailPage: Атрибуты не найдены в ответе');
        setState(() {
          _attributeNames = {};
          _isLoadingAttributes = false;
        });
      }
    } catch (e) {
      print('🔴 ProductInflowDetailPage: Ошибка загрузки шаблона товара: $e');
      setState(() => _isLoadingAttributes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 ProductInflowDetailPage: build вызван для товара ID: ${widget.product.id}');
    print('🔵 ProductInflowDetailPage: product.name = ${widget.product.name}');
    print('🔵 ProductInflowDetailPage: product.warehouse = ${widget.product.warehouse?.name}');
    print('🔵 ProductInflowDetailPage: product.producer = ${widget.product.producer?.name}');
    print('🔵 ProductInflowDetailPage: product.template = ${widget.product.template?.name}');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name ?? 'Без названия'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProductInflowFormPage(product: widget.product),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Редактировать',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная информация
            _buildSection(
              title: 'Основная информация',
              children: [
                _buildInfoRow('Название', widget.product.name ?? 'Без названия'),
                if (widget.product.description != null && widget.product.description!.isNotEmpty)
                  _buildInfoRow('Описание', widget.product.description!),
                _buildInfoRow('Количество', widget.product.quantity),
                _buildInfoRow('Объем', '${widget.product.calculatedVolume ?? '0'} ${widget.product.template?.unit ?? ''}'),
                _buildInfoRow('Склад', widget.product.warehouse?.name ?? 'Не указан'),
                _buildInfoRow('Производитель', widget.product.producer?.name ?? 'Не указан'),
                _buildInfoRow('Создатель', widget.product.creator?.name ?? 'Не указан'),
                _buildInfoRow('Шаблон товара', widget.product.template?.name ?? 'Не указан'),
                _buildInfoRow('Номер транспорта', widget.product.transportNumber ?? 'Не указан'),
                _buildInfoRow('Место отгрузки', widget.product.shippingLocation ?? 'Не указано'),
                _buildInfoRow('Дата отгрузки', widget.product.shippingDate != null 
                    ? _formatDate(widget.product.shippingDate!) 
                    : 'Не указана'),
                _buildInfoRow('Ожидаемая дата прибытия', widget.product.expectedArrivalDate != null 
                    ? _formatDate(widget.product.expectedArrivalDate!) 
                    : 'Не указана'),
                _buildInfoRow('Дата поступления', widget.product.arrivalDate != null 
                    ? _formatDate(widget.product.arrivalDate!) 
                    : 'Не указана'),
              ],
            ),

            const SizedBox(height: 24),

            // Характеристики товара
            if (widget.product.attributes != null && widget.product.attributes is Map && (widget.product.attributes as Map).isNotEmpty)
              _buildSection(
                title: 'Характеристики товара',
                children: _isLoadingAttributes 
                    ? [const Center(child: CircularProgressIndicator())]
                    : (widget.product.attributes as Map).entries
                        .map((entry) => _buildInfoRow(
                            _getAttributeDisplayName(entry.key.toString()), 
                            entry.value.toString()))
                        .toList(),
              ),

            const SizedBox(height: 24),

            // Документы
            if (widget.product.documentPath != null && widget.product.documentPath.isNotEmpty)
              _buildSection(
                title: 'Документы',
                children: [
                  ...widget.product.documentPath.map((path) => _buildDocumentItem(context, path)),
                ],
              ),

            const SizedBox(height: 24),

            // Заметки
            if (widget.product.notes != null && widget.product.notes!.isNotEmpty)
              _buildSection(
                title: 'Заметки',
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      widget.product.notes!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Коррекции
            if (widget.product.correction != null || widget.product.correctionStatus != null)
              _buildSection(
                title: 'Коррекции',
                children: [
                  if (widget.product.correction != null)
                    _buildInfoRow('Коррекция', widget.product.correction!),
                  if (widget.product.correctionStatus != null)
                    _buildInfoRow('Статус коррекции', widget.product.correctionStatus!),
                  if (widget.product.revisedAt != null)
                    _buildInfoRow('Дата пересмотра', _formatDateTime(widget.product.revisedAt!)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _getAttributeDisplayName(String variable) {
    // Если есть названия атрибутов, используем их, иначе переменную
    if (_attributeNames != null && _attributeNames!.containsKey(variable)) {
      return _attributeNames![variable]!;
    }
    return variable; // Fallback на переменную
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    print('🔵 ProductInflowDetailPage: _buildSection вызван для "$title" с ${children.length} детьми');
    try {
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
    } catch (e) {
      print('🔴 ProductInflowDetailPage: Ошибка в _buildSection "$title": $e');
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text('Ошибка отображения секции: $e'),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    print('🔵 ProductInflowDetailPage: _buildInfoRow вызван для "$label" = "$value"');
    try {
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
    } catch (e) {
      print('🔴 ProductInflowDetailPage: Ошибка в _buildInfoRow "$label": $e');
      return Container(
        padding: const EdgeInsets.all(8),
        child: Text('Ошибка отображения: $e'),
      );
    }
  }

  Widget _buildDocumentItem(BuildContext context, String path) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description,
            size: 20,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              path.split('/').last,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Реализовать открытие документа
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Открытие документа будет реализовано')),
              );
            },
            icon: Icon(
              Icons.open_in_new,
              size: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'in_stock':
        return 'На складе';
      case 'for_receipt':
        return 'На приемке';
      case 'in_transit':
        return 'В пути';
      default:
        return status;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      print('🔵 ProductInflowDetailPage: _formatDateTime вызван для "$dateTimeString"');
      final dateTime = DateTime.parse(dateTimeString);
      final result = '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      print('🔵 ProductInflowDetailPage: _formatDateTime результат: "$result"');
      return result;
    } catch (e) {
      print('🔴 ProductInflowDetailPage: Ошибка в _formatDateTime: $e');
      return dateTimeString;
    }
  }
}
