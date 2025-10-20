import 'dart:io';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:sum_warehouse/features/acceptance/data/models/acceptance_model.dart';
import 'package:sum_warehouse/features/acceptance/data/datasources/acceptance_remote_datasource.dart';
import 'package:sum_warehouse/features/acceptance/presentation/providers/acceptance_provider.dart';
import 'package:sum_warehouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';

/// Страница детального просмотра товара приемки
class AcceptanceDetailPage extends ConsumerStatefulWidget {
  final AcceptanceModel product;

  const AcceptanceDetailPage({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<AcceptanceDetailPage> createState() => _AcceptanceDetailPageState();
}

class _AcceptanceDetailPageState extends ConsumerState<AcceptanceDetailPage> {
  Map<String, String>? _attributeNames; // Кэш названий атрибутов
  bool _isLoadingAttributes = false;
  AcceptanceModel? _currentProduct; // Актуальные данные товара
  final TextEditingController _correctionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _loadProductTemplate();
  }

  @override
  void dispose() {
    _correctionController.dispose();
    super.dispose();
  }

  AcceptanceModel get _product => _currentProduct ?? widget.product;

  /// Проверка доступа к приему товара
  bool _canReceiveProduct() {
    // Проверяем статус товара
    final allowedStatuses = ['in_transit', 'for_receipt'];
    if (!allowedStatuses.contains(_product.status)) {
      return false;
    }

    // Проверяем роль пользователя
    final currentUserRole = ref.watch(currentUserRoleProvider);

    // Разрешения по ролям:
    // - admin: полный доступ
    // - operator: доступ к приему и корректировке товара
    // - warehouse_worker: доступ к приему и корректировке товара
    // - sales_manager: только просмотр (без действий)
    final allowedRoles = {UserRole.admin, UserRole.operator, UserRole.warehouseWorker};

    if (currentUserRole != null && allowedRoles.contains(currentUserRole)) {
      return true;
    }

    return false;
  }

  /// Проверка доступа к корректировке товара
  bool _canCorrectProduct() {
    // Проверяем статус товара
    final allowedStatuses = ['in_transit', 'for_receipt'];
    if (!allowedStatuses.contains(_product.status)) {
      return false;
    }

    // Проверяем роль пользователя
    final currentUserRole = ref.watch(currentUserRoleProvider);

    // Разрешения по ролям для корректировки:
    // - admin: полный доступ
    // - operator: доступ к корректировке
    // - warehouse_worker: доступ к корректировке
    final allowedRoles = {UserRole.admin, UserRole.operator, UserRole.warehouseWorker};

    if (currentUserRole != null && allowedRoles.contains(currentUserRole)) {
      return true;
    }

    return false;
  }

  Future<void> _refreshProductData() async {
    if (_currentProduct == null) return;

    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get(
        '/products/${_currentProduct!.id}',
        queryParameters: {
          'include': 'template,warehouse,creator,producer'
        }
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        
        // Check if response has success wrapper
        AcceptanceModel? updatedProduct;
        if (data['success'] == true && data['data'] != null) {
          updatedProduct = AcceptanceModel.fromJson(data['data'] as Map<String, dynamic>);
        } else if (data['product'] != null) {
          // Alternative format with 'product' key
          updatedProduct = AcceptanceModel.fromJson(data['product'] as Map<String, dynamic>);
        } else {
          // Direct format without wrapper
          updatedProduct = AcceptanceModel.fromJson(data);
        }
        
        if (mounted) {
          setState(() {
            _currentProduct = updatedProduct;
          });
        }
      }
    } catch (e) {
      // Обработка ошибки обновления данных товара
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
      // Обработка ошибки загрузки шаблона товара
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
                _buildInfoRow('Дата поступления', _product.arrivalDate != null 
                    ? _formatDate(_product.arrivalDate!) 
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
                    : _buildAttributesInOrder(),
              ),

            const SizedBox(height: 24),

            // Кнопки действий
            Row(
              children: [
                // Кнопка корректировки
                if (_canCorrectProduct()) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showCorrectionDialog,
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('Корректировка'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Кнопка приема товара
                if (_canReceiveProduct()) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _receiveProduct,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Принять товар'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
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

      // Запрашиваем разрешения в зависимости от версии Android
      bool hasPermission = false;
      
      if (await Permission.storage.isGranted) {
        hasPermission = true;
      } else {
        // Для Android 13+ (API 33+) запрашиваем новые разрешения
        if (await Permission.photos.isGranted || 
            await Permission.videos.isGranted || 
            await Permission.audio.isGranted) {
          hasPermission = true;
        } else {
          // Запрашиваем разрешения
          final status = await Permission.storage.request();
          if (status == PermissionStatus.granted) {
            hasPermission = true;
          } else {
            // Пробуем запросить новые разрешения для Android 13+
            final photosStatus = await Permission.photos.request();
            final videosStatus = await Permission.videos.request();
            final audioStatus = await Permission.audio.request();
            
            if (photosStatus == PermissionStatus.granted || 
                videosStatus == PermissionStatus.granted || 
                audioStatus == PermissionStatus.granted) {
              hasPermission = true;
            }
          }
        }
      }
      
      if (!hasPermission) {
        Navigator.of(context).pop(); // Закрываем диалог загрузки
        _showErrorDialog('Необходимо разрешение на доступ к хранилищу. Пожалуйста, предоставьте разрешение в настройках приложения.');
        return;
      }

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

      // Документ успешно сохранен
    } catch (e) {
      // Обработка ошибки скачивания документа

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

  /// Прием товара
  Future<void> _receiveProduct() async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post('/receipts/${_product.id}/receive');

      if (response.data['success'] == true) {
        // Обновляем локальные данные
        await _refreshProductData();

        // Обновляем данные в провайдере списка товаров
        ref.read(acceptanceNotifierProvider.notifier).refresh();

        // Закрываем страницу детального просмотра
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception(response.data['message'] ?? 'Ошибка приема товара');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка приема товара: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Показать диалог корректировки
  void _showCorrectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Корректировка товара'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Добавьте уточнение к товару:'),
            const SizedBox(height: 16),
            TextField(
              controller: _correctionController,
              decoration: const InputDecoration(
                hintText: 'Введите уточнение (10-1000 символов)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 1000,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _correctionController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _submitCorrection,
            child: const Text('Добавить уточнение'),
          ),
        ],
      ),
    );
  }

  /// Отправить корректировку
  Future<void> _submitCorrection() async {
    final correction = _correctionController.text.trim();

    if (correction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите текст уточнения'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (correction.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Текст уточнения должен содержать минимум 10 символов'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final dio = ref.read(dioClientProvider);

      // Пробуем альтернативный endpoint для корректировки
      // Возможно на бэкенде роли настроены по-другому
      late Response response;

      try {
        response = await dio.post(
          '/receipts/${_product.id}/correction',
          data: {'correction': correction},
        );
      } catch (e) {
        // Если основной endpoint не работает, пробуем альтернативный
        if (e.toString().contains('403')) {
          response = await dio.post(
            '/products/${_product.id}/correction',
            data: {'correction': correction},
          );
        } else {
          rethrow;
        }
      }

      if (response.data['success'] == true) {
        // Очищаем контроллер
        _correctionController.clear();

        // Закрываем диалог
        Navigator.of(context).pop();

        // Обновляем локальные данные
        await _refreshProductData();

        // Обновляем данные в провайдере списка товаров
        ref.read(acceptanceNotifierProvider.notifier).refresh();

        // Закрываем страницу детального просмотра
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception(response.data['message'] ?? 'Ошибка корректировки товара');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка корректировки товара: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  List<Widget> _buildAttributesInOrder() {
    if (_product.attributes == null) {
      return [];
    }
    
    // Если attributes уже LinkedHashMap (из API с новым конвертером)
    // он сохранит порядок без дополнительной сортировки
    if (_product.attributes is! Map) {
      return [];
    }
    
    final attrs = _product.attributes as Map<String, dynamic>;
    
    // .entries сохранит порядок из LinkedHashMap
    return attrs.entries
        .map((entry) => _buildInfoRow(
            _getAttributeDisplayName(entry.key), 
            entry.value.toString()))
        .toList();
  }
}