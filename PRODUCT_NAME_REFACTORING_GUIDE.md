# Рекомендации по рефакторингу создания имён товаров

## 🎯 Проблема

В настоящий момент логика создания имён товаров **дублируется** в двух местах:
- `lib/features/products_inflow/presentation/pages/product_inflow_form_page.dart` (строки 210-237)
- `lib/features/products_in_transit/presentation/pages/product_in_transit_form_page.dart` (строки 1188-1216)

Это нарушает принцип **DRY** (Don't Repeat Yourself) и усложняет поддержку кода.

---

## ✅ РЕШЕНИЕ 1: Создать класс-генератор имён

### Шаг 1: Создать файл `lib/shared/utils/product_name_generator.dart`

```dart
import 'package:sum_warehouse/shared/models/product_attribute_model.dart';

/// Генератор имён товаров на основе шаблонов и атрибутов
class ProductNameGenerator {
  /// Генерирует имя товара из шаблона и значений атрибутов
  /// 
  /// Формат: [Название шаблона]: [Атрибуты формулы x], [Остальные атрибуты]
  /// 
  /// Пример: "Доска: 20 x 30, Сосна"
  static String generate({
    required String templateName,
    required List<ProductAttributeModel> attributes,
    required Map<String, String> attributeValues,
  }) {
    final formulaAttributes = <String>[];
    final regularAttributes = <String>[];

    // Разделяем атрибуты на две категории
    for (final attribute in attributes) {
      final value = attributeValues[attribute.variable]?.trim() ?? '';
      if (value.isEmpty) continue;

      if (attribute.isInFormula) {
        // Атрибуты, входящие в формулу (размеры, вес и т.д.)
        formulaAttributes.add(value);
      } else if (attribute.type == 'number' || attribute.type == 'select') {
        // Остальные числовые и выборочные атрибуты
        regularAttributes.add(value);
      }
    }

    // Строим имя товара
    final nameParts = [templateName];

    if (formulaAttributes.isNotEmpty) {
      nameParts.add(formulaAttributes.join(' x '));
    }

    if (regularAttributes.isNotEmpty) {
      nameParts.add(regularAttributes.join(', '));
    }

    return nameParts.join(': ');
  }

  /// Парсит имя товара и возвращает отдельные части
  /// 
  /// Возвращает: {
  ///   'name': 'Доска',
  ///   'formula': '20 x 30',
  ///   'properties': 'Сосна'
  /// }
  static Map<String, String> parse(String fullName) {
    if (!fullName.contains(':')) {
      return {'name': fullName};
    }

    final parts = fullName.split(':').map((p) => p.trim()).toList();
    
    return {
      'name': parts[0],
      if (parts.length > 1) ...{
        'characteristics': parts.sublist(1).join(':').trim()
      }
    };
  }

  /// Получает только название товара (часть до первого двоеточия)
  static String getName(String fullName) {
    return fullName.split(':').first.trim();
  }

  /// Получает только характеристики (часть после первого двоеточия)
  static String getCharacteristics(String fullName) {
    if (!fullName.contains(':')) return '';
    return fullName.split(':').sublist(1).join(':').trim();
  }
}
```

---

### Шаг 2: Обновить `product_inflow_form_page.dart`

**БЫЛО:**
```dart
String _generateProductName() {
  if (_selectedTemplate == null) return '';

  final formulaAttributes = <String>[];
  final regularAttributes = <String>[];

  for (final attribute in _selectedTemplate!.attributes) {
    final value = _attributeControllers[attribute.variable]?.text ?? '';
    if (value.isEmpty) continue;

    if (attribute.isInFormula) {
      formulaAttributes.add(value);
    } else if (attribute.type == 'number' || attribute.type == 'select') {
      regularAttributes.add(value);
    }
  }

  final List<String> nameParts = [_selectedTemplate!.name];

  if (formulaAttributes.isNotEmpty) {
    nameParts.add(formulaAttributes.join(' x '));
  }

  if (regularAttributes.isNotEmpty) {
    nameParts.add(regularAttributes.join(', '));
  }

  return nameParts.join(': ');
}
```

**СТАЛО:**
```dart
import 'package:sum_warehouse/shared/utils/product_name_generator.dart';

String _generateProductName() {
  if (_selectedTemplate == null) return '';

  final attributeValues = {
    for (var entry in _attributeControllers.entries)
      entry.key: entry.value.text
  };

  return ProductNameGenerator.generate(
    templateName: _selectedTemplate!.name,
    attributes: _selectedTemplate!.attributes,
    attributeValues: attributeValues,
  );
}
```

---

### Шаг 3: Обновить `product_in_transit_form_page.dart`

**БЫЛО:**
```dart
String _generateProductName(int index) {
  final product = _products[index];
  if (product.template == null) return '';

  final formulaAttributes = <String>[];
  final regularAttributes = <String>[];

  for (final attribute in product.template!.attributes) {
    final value = product.attributeControllers[attribute.variable]?.text ?? '';
    if (value.isEmpty) continue;

    if (attribute.isInFormula) {
      formulaAttributes.add(value);
    } else if (attribute.type == 'number' || attribute.type == 'select') {
      regularAttributes.add(value);
    }
  }

  final List<String> nameParts = [product.template!.name];

  if (formulaAttributes.isNotEmpty) {
    nameParts.add(formulaAttributes.join(' x '));
  }

  if (regularAttributes.isNotEmpty) {
    nameParts.add(regularAttributes.join(', '));
  }

  return nameParts.join(': ');
}
```

**СТАЛО:**
```dart
import 'package:sum_warehouse/shared/utils/product_name_generator.dart';

String _generateProductName(int index) {
  final product = _products[index];
  if (product.template == null) return '';

  final attributeValues = {
    for (var entry in product.attributeControllers.entries)
      entry.key: entry.value.text
  };

  return ProductNameGenerator.generate(
    templateName: product.template!.name,
    attributes: product.template!.attributes,
    attributeValues: attributeValues,
  );
}
```

---

### Шаг 4: Обновить `product_inflow_list_page.dart`

**БЫЛО:**
```dart
Widget _buildProductHeader(String fullName) {
  if (fullName.contains(':')) {
    final parts = fullName.split(':');
    final productName = parts[0].trim();
    final characteristics = parts.sublist(1).join(':').trim();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$productName:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(characteristics, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
      ],
    );
  }
  
  return Text(fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
}
```

**СТАЛО:**
```dart
import 'package:sum_warehouse/shared/utils/product_name_generator.dart';

Widget _buildProductHeader(String fullName) {
  final parsed = ProductNameGenerator.parse(fullName);
  
  if (parsed.containsKey('characteristics')) {
    final productName = parsed['name']!;
    final characteristics = parsed['characteristics']!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$productName:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(characteristics, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
      ],
    );
  }
  
  return Text(fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
}
```

---

### Шаг 5: Обновить `product_in_transit_list_page.dart`

**Аналогично `product_inflow_list_page.dart`:**
```dart
import 'package:sum_warehouse/shared/utils/product_name_generator.dart';

Widget _buildProductHeader(String fullName) {
  final parsed = ProductNameGenerator.parse(fullName);
  
  if (parsed.containsKey('characteristics')) {
    final productName = parsed['name']!;
    final characteristics = parsed['characteristics']!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$productName:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(characteristics, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
      ],
    );
  }
  
  return Text(fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
}
```

---

## ✅ РЕШЕНИЕ 2: Создать утилиту для парсинга имён

### Использование в других местах

```dart
// Где-нибудь в detail_page:
import 'package:sum_warehouse/shared/utils/product_name_generator.dart';

// Получить только название
final productName = ProductNameGenerator.getName(product.name);

// Получить только характеристики
final characteristics = ProductNameGenerator.getCharacteristics(product.name);

// Распарсить полностью
final parsed = ProductNameGenerator.parse(product.name);
final name = parsed['name'];
final characteristics = parsed['characteristics'];
```

---

## 📊 РЕЗУЛЬТАТЫ РЕФАКТОРИНГА

### До:
- 🔴 **3 места** с дублированным кодом создания имён
- 🔴 **2 места** с дублированным кодом парсинга имён
- 🔴 При изменении логики нужно обновлять **5 мест**

### После:
- 🟢 **1 место** (класс `ProductNameGenerator`)
- 🟢 При изменении логики нужно обновлять **1 место**
- 🟢 Легче тестировать - есть единая точка входа
- 🟢 Легче поддерживать и расширять функциональность

---

## 🧪 ТЕСТИРОВАНИЕ

### Создать файл `test/utils/product_name_generator_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sum_warehouse/shared/utils/product_name_generator.dart';
import 'package:sum_warehouse/shared/models/product_attribute_model.dart';

void main() {
  group('ProductNameGenerator', () {
    test('generates name with formula and regular attributes', () {
      const templateName = 'Доска';
      final attributes = [
        ProductAttributeModel(
          id: 1,
          productTemplateId: 1,
          name: 'Длина',
          variable: 'length',
          type: 'number',
          isInFormula: true,
          isRequired: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ProductAttributeModel(
          id: 2,
          productTemplateId: 1,
          name: 'Ширина',
          variable: 'width',
          type: 'number',
          isInFormula: true,
          isRequired: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ProductAttributeModel(
          id: 3,
          productTemplateId: 1,
          name: 'Материал',
          variable: 'material',
          type: 'select',
          isInFormula: false,
          isRequired: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      const attributeValues = {
        'length': '20',
        'width': '30',
        'material': 'Сосна',
      };

      final result = ProductNameGenerator.generate(
        templateName: templateName,
        attributes: attributes,
        attributeValues: attributeValues,
      );

      expect(result, 'Доска: 20 x 30, Сосна');
    });

    test('generates name with only formula attributes', () {
      const templateName = 'Гвозди';
      final attributes = [
        ProductAttributeModel(
          id: 1,
          productTemplateId: 2,
          name: 'Длина',
          variable: 'length',
          type: 'number',
          isInFormula: true,
          isRequired: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      const attributeValues = {'length': '50'};

      final result = ProductNameGenerator.generate(
        templateName: templateName,
        attributes: attributes,
        attributeValues: attributeValues,
      );

      expect(result, 'Гвозди: 50');
    });

    test('generates name with no attributes', () {
      const templateName = 'Краска';
      final attributes = <ProductAttributeModel>[];
      const attributeValues = <String, String>{};

      final result = ProductNameGenerator.generate(
        templateName: templateName,
        attributes: attributes,
        attributeValues: attributeValues,
      );

      expect(result, 'Краска');
    });

    test('parses full name correctly', () {
      const fullName = 'Доска: 20 x 30, Сосна';
      
      final result = ProductNameGenerator.parse(fullName);

      expect(result['name'], 'Доска');
      expect(result['characteristics'], '20 x 30, Сосна');
    });

    test('parses name without characteristics', () {
      const fullName = 'Краска';
      
      final result = ProductNameGenerator.parse(fullName);

      expect(result['name'], 'Краска');
      expect(result.containsKey('characteristics'), false);
    });

    test('gets name from full name', () {
      const fullName = 'Доска: 20 x 30, Сосна';
      
      final result = ProductNameGenerator.getName(fullName);

      expect(result, 'Доска');
    });

    test('gets characteristics from full name', () {
      const fullName = 'Доска: 20 x 30, Сосна';
      
      final result = ProductNameGenerator.getCharacteristics(fullName);

      expect(result, '20 x 30, Сосна');
    });
  });
}
```

---

## 📋 ЧЕК-ЛИСТ ДЛЯ ВНЕДРЕНИЯ

- [ ] Создать файл `lib/shared/utils/product_name_generator.dart`
- [ ] Добавить тесты в `test/utils/product_name_generator_test.dart`
- [ ] Обновить `product_inflow_form_page.dart`
- [ ] Обновить `product_in_transit_form_page.dart`
- [ ] Обновить `product_inflow_list_page.dart`
- [ ] Обновить `product_in_transit_list_page.dart`
- [ ] Запустить все тесты: `flutter test`
- [ ] Проверить работу на iOS
- [ ] Проверить работу на Android
- [ ] Закоммитить изменения

---

## 🚀 ДОПОЛНИТЕЛЬНЫЕ УЛУЧШЕНИЯ

### 1. Кэширование вычисленного имени

```dart
class ProductNameCache {
  static final _cache = <String, String>{};

  static String get({
    required String templateName,
    required List<ProductAttributeModel> attributes,
    required Map<String, String> attributeValues,
  }) {
    final key = _getCacheKey(templateName, attributeValues);
    
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final name = ProductNameGenerator.generate(
      templateName: templateName,
      attributes: attributes,
      attributeValues: attributeValues,
    );

    _cache[key] = name;
    return name;
  }

  static String _getCacheKey(String template, Map<String, String> values) {
    return '$template:${values.entries.map((e) => '${e.key}=${e.value}').join('|')}';
  }

  static void clear() => _cache.clear();
}
```

### 2. Валидация перед созданием имени

```dart
extension ProductNameValidation on ProductNameGenerator {
  static String? validate({
    required String templateName,
    required List<ProductAttributeModel> attributes,
    required Map<String, String> attributeValues,
  }) {
    if (templateName.isEmpty) return 'Название шаблона не может быть пустым';
    
    if (attributes.isEmpty) return null; // OK - нет обязательных атрибутов
    
    for (final attr in attributes.where((a) => a.isRequired)) {
      final value = attributeValues[attr.variable]?.trim() ?? '';
      if (value.isEmpty) return 'Обязательный атрибут "${attr.name}" не заполнен';
    }
    
    return null; // OK - всё корректно
  }
}
```

---

## 📚 ФАЙЛЫ ДЛЯ ИЗМЕНЕНИЯ

1. **Новый файл:**
   - `lib/shared/utils/product_name_generator.dart`

2. **Обновить:**
   - `lib/features/products_inflow/presentation/pages/product_inflow_form_page.dart`
   - `lib/features/products_in_transit/presentation/pages/product_in_transit_form_page.dart`
   - `lib/features/products_inflow/presentation/pages/product_inflow_list_page.dart`
   - `lib/features/products_in_transit/presentation/pages/product_in_transit_list_page.dart`

3. **Новый файл (тесты):**
   - `test/utils/product_name_generator_test.dart`
