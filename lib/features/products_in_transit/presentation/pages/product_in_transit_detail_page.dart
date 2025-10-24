import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/products_in_transit/data/models/product_in_transit_model.dart';
import 'package:sum_warehouse/features/products_in_transit/presentation/pages/product_in_transit_form_page.dart';
import 'package:sum_warehouse/features/products_in_transit/data/datasources/products_in_transit_remote_datasource.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';

/// Страница детального просмотра товара в пути
class ProductInTransitDetailPage extends ConsumerStatefulWidget {
  final ProductInTransitModel product;

  const ProductInTransitDetailPage({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductInTransitDetailPage> createState() => _ProductInTransitDetailPageState();
}

class _ProductInTransitDetailPageState extends ConsumerState<ProductInTransitDetailPage> {
  Map<String, String>? _attributeNames; // Кэш названий атрибутов
  bool _isLoadingAttributes = false;
  ProductInTransitModel? _currentProduct; // Актуальные данные товара

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _loadProductTemplate();
  }

  ProductInTransitModel get _product => _currentProduct ?? widget.product;

  Future<void> _refreshProductData() async {
    if (_currentProduct == null) return;

    try {
      
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('/products/${_currentProduct!.id}', queryParameters: {
        'include': 'template,warehouse,creator,producer'
      });
      
      
      if (response.data is Map<String, dynamic>) {
        final updatedProduct = ProductInTransitModel.fromJson(response.data);
        
        if (mounted) {
          setState(() {
            _currentProduct = updatedProduct;
          });
        }
      }
    } catch (e) {
    }
  }

  Future<void> _loadProductTemplate() async {
    if (_product.productTemplateId == null) return;
    
    setState(() {
      _isLoadingAttributes = true;
    });

    try {
      
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('/product-templates/${_product.productTemplateId}');
      
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data;
        
        // Проверяем структуру ответа - может быть вложен в data
        Map<String, dynamic> templateData;
        if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          templateData = data['data'] as Map<String, dynamic>;
        } else {
          templateData = data;
        }
        
        if (templateData.containsKey('attributes') && templateData['attributes'] is List) {
          final attributes = templateData['attributes'] as List;
          
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
          
          
          if (mounted) {
            setState(() {
              _attributeNames = attributeNames;
            });
          }
        }
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAttributes = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_product.name ?? 'Без названия'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProductInTransitFormPage(product: _currentProduct ?? widget.product),
                ),
              );
              
              // Обновляем данные только при успешном сохранении
              if (result == true) {
                await _refreshProductData();
              }
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
                _buildInfoRow('Название', _product.name ?? 'Без названия'),
                if (_product.description != null && _product.description!.isNotEmpty)
                  _buildInfoRow('Описание', _product.description!),
                _buildInfoRow('Количество', _product.quantity),
                _buildInfoRow('Объем', '${_formatVolume(_product.calculatedVolume)} ${_product.template?.unit ?? ''}'),
                _buildInfoRow('Склад', _product.warehouse?.name ?? 'Не указан'),
                _buildInfoRow('Производитель', _product.producer?.name ?? 'Не указан'),
                _buildInfoRow('Создатель', _product.creator?.name ?? 'Не указан'),
                _buildInfoRow('Шаблон товара', _product.template?.name ?? 'Не указан'),
                _buildInfoRow('Номер транспорта', _product.transportNumber ?? 'Не указан'),
                _buildInfoRow('Место отгрузки', _product.shippingLocation ?? 'Не указано'),
                _buildInfoRow('Дата отгрузки', _product.shippingDate != null 
                    ? _formatDate(_product.shippingDate!) 
                    : 'Не указана'),
                _buildInfoRow('Ожидаемая дата прибытия', _product.expectedArrivalDate != null
                    ? _formatDate(_product.expectedArrivalDate!)
                    : 'Не указана'),
              ],
            ),

            const SizedBox(height: 24),

            // Характеристики товара
            if (_product.attributes != null && _product.attributes is Map && (_product.attributes as Map).isNotEmpty)
              _buildSection(
                title: 'Характеристики товара',
                children: _isLoadingAttributes 
                    ? [const Center(child: CircularProgressIndicator())]
                    : (_product.attributes as Map).entries
                        .map((entry) => _buildInfoRow(
                            _getAttributeDisplayName(entry.key.toString()), 
                            entry.value.toString()))
                        .toList(),
              ),

            const SizedBox(height: 24),

            // Документы
            if (_product.documentPath != null && _product.documentPath.isNotEmpty)
              _buildSection(
                title: 'Документы',
                children: [
                  ..._product.documentPath.map((path) => _buildDocumentItem(context, path)),
                ],
              ),

            const SizedBox(height: 24),

            // Заметки
            if (_product.notes != null && _product.notes!.isNotEmpty)
              _buildSection(
                title: 'Заметки',
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      _product.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D3748),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Коррекции
            if (_product.correction != null || _product.revisedAt != null)
              _buildSection(
                title: 'Коррекции',
                children: [
                  if (_product.correction != null)
                    _buildInfoRow('Коррекция', _product.correction!),
                  if (_product.revisedAt != null)
                    _buildInfoRow('Дата пересмотра', _formatDateTime(_product.revisedAt!)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
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
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text('Ошибка отображения секции: $e'),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
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
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: Text('Ошибка отображения: $e'),
      );
    }
  }

  String _getAttributeDisplayName(String variable) {
    // Если есть названия атрибутов, используем их, иначе переменную
    if (_attributeNames != null && _attributeNames!.containsKey(variable)) {
      return _attributeNames![variable]!;
    }
    return variable; // Fallback на переменную
  }

  List<Widget> _buildAttributesList() {
    if (_isLoadingAttributes) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }

    if (_product.attributes == null) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Характеристики не указаны',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ];
    }

    final attributes = _product.attributes as Map<String, dynamic>?;
    if (attributes == null || attributes.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Характеристики не указаны',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ];
    }

    return attributes.entries.map((entry) {
      final key = entry.key;
      final value = entry.value?.toString() ?? '';
      
      // Получаем название атрибута из шаблона или используем ключ
      final attributeName = _attributeNames?[key] ?? key;
      
      return _buildInfoRow(attributeName, value);
    }).toList();
  }

  Widget _buildDocumentItem(BuildContext context, String path) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDocument(path),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  String _formatVolume(String? volumeString) {
    if (volumeString == null || volumeString.isEmpty || volumeString == '0') {
      return '0';
    }

    try {
      final volume = double.parse(volumeString);
      return volume.toStringAsFixed(3);
    } catch (e) {
      return volumeString; // Возвращаем исходное значение если не удалось распарсить
    }
  }

  Future<void> _openDocument(String path) async {
    try {

      // Формируем полную ссылку на документ
      String documentUrl;
      if (path.startsWith('http')) {
        // Если путь уже полный URL
        documentUrl = path;
      } else {
        // Формируем URL относительно базового адреса API
        // Проверяем, начинается ли путь со слэша и добавляем /storage/
        String normalizedPath = path.startsWith('/') ? path : '/$path';
        if (!normalizedPath.startsWith('/storage/')) {
          normalizedPath = '/storage$normalizedPath';
        }
        documentUrl = 'https://warehouse.expwood.ru$normalizedPath';
      }


      // Показываем диалог загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Скачиваем документ...'),
            ],
          ),
        ),
      );

      // Для Android 10+ используем scoped storage - разрешения не нужны
      // Файлы сохраняются в приложение-специфическую директорию

      // Скачиваем файл
      final dio = ref.read(dioClientProvider);
      final response = await dio.get(
        documentUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );

      // Получаем директорию для загрузок
      Directory? directory;
      Directory downloadsDir;
      
      try {
        // Пробуем получить внешнюю директорию (для старых версий Android)
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          downloadsDir = Directory('${directory.path}/Downloads');
        } else {
          throw Exception('External storage not available');
        }
      } catch (e) {
        // Если внешнее хранилище недоступно, используем внутреннее
        directory = await getApplicationDocumentsDirectory();
        downloadsDir = Directory('${directory.path}/Downloads');
      }
      
      // Создаем директорию Downloads если её нет
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Получаем имя файла из пути
      final fileName = path.split('/').last;
      final file = File('${downloadsDir.path}/$fileName');

      // Сохраняем файл
      await file.writeAsBytes(response.data);

      Navigator.of(context).pop(); // Закрываем диалог загрузки

      // Показываем диалог успеха
      if (mounted) {
        String locationText;
        if (directory!.path.contains('Android/data')) {
          locationText = 'Документ сохранен в папку приложения:\n${file.path}\n\nФайл можно найти через файловый менеджер в папке приложения.';
        } else {
          locationText = 'Документ сохранен в папку Downloads:\n${file.path}';
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Успешно'),
            content: Text(locationText),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ОК'),
              ),
            ],
          ),
        );
      }


    } catch (e) {

      // Закрываем диалог загрузки если он открыт
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _showErrorDialog('Не удалось скачать документ: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  void _editProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductInTransitFormPage(product: _product),
      ),
    ).then((_) {
      // Обновляем данные после редактирования
      _refreshProductData();
    });
  }
}
