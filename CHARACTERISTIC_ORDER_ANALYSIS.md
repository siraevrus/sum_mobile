# Анализ порядка характеристик товара в разделе "Поступление товара"

## 🔍 Проблема
При создании товара и при просмотре превью карточки порядок характеристик отличается.

---

## 📊 Сравнение логики

### 1️⃣ При СОЗДАНИИ товара (Form Page)
**Файл:** `lib/features/products_inflow/presentation/pages/product_inflow_form_page.dart`

**Метод:** `_buildAttributeFields()` (строка 585-598)

```dart
List<Widget> _buildAttributeFields() {
  if (_selectedTemplate == null) return [];
  
  final List<Widget> fields = [];
  
  // ✅ ПОРЯДОК СООТВЕТСТВУЕТ ШАБЛОНУ
  for (final attribute in _selectedTemplate!.attributes) {
    final controller = _attributeControllers[attribute.variable];
    if (controller == null) continue;
    
    fields.add(_buildAttributeField(attribute, controller));
  }
  
  return fields;
}
```

**Логика:**
- Берет атрибуты из `_selectedTemplate!.attributes`
- Проходит по ним в порядке, определенном шаблоном
- Порядок совпадает с `sortOrder` из базы данных
- ✅ **НАДЕЖНЫЙ ПОРЯДОК**

---

### 2️⃣ При ПРОСМОТРЕ превью (Detail Page)
**Файл:** `lib/features/products_inflow/presentation/pages/product_inflow_detail_page.dart`

**Метод:** `build()` (строка 193-197)

```dart
(_product.attributes as Map).entries
    .map((entry) => _buildInfoRow(
        _getAttributeDisplayName(entry.key.toString()), 
        entry.value.toString()))
    .toList()
```

**Логика:**
- Берет атрибуты из `_product.attributes` (это Map<String, dynamic>)
- Проходит по `.entries` этого Map
- ❌ **ПОРЯДОК НЕОПРЕДЕЛЕН!** 

**Почему порядок неопределен?**
```
Map в Dart не гарантирует порядок итерации!
- Порядок может быть random
- Может отличаться между запусками
- Зависит от реализации HashMap/LinkedHashMap в Dart
```

---

## 🔧 Как это связано с API и БД?

### При создании:
```
Шаблон товара (API) 
  ↓
template.attributes[] (отсортировано по sortOrder)
  ↓
Form Page
  ↓
Правильный порядок характеристик
```

### При просмотре:
```
Товар (API/БД)
  ↓
product.attributes = { "height": "10", "width": "5", ... }
  ↓
Map.entries (неопределенный порядок!)
  ↓
Случайный порядок характеристик
```

---

## ✅ Решение

Нужно отсортировать характеристики в Detail Page так же, как они отсортированы в Form Page.

### Вариант 1: Использовать шаблон (рекомендуется)
```dart
if (_attributeNames != null && _product.attributes != null) {
  // Используем порядок из шаблона
  final attributes = _selectedTemplate!.attributes;
  
  return attributes
      .where((attr) => _product.attributes.containsKey(attr.variable))
      .map((attr) => _buildInfoRow(
          attr.name, 
          _product.attributes[attr.variable].toString()))
      .toList();
}
```

### Вариант 2: Отсортировать Map перед использованием
```dart
final sortedEntries = (_product.attributes as Map).entries
    .toList()
    ..sort((a, b) => a.key.compareTo(b.key));  // Алфавитный порядок
```

---

## 📝 Выводы

| Аспект | При создании | При просмотре |
|--------|-------------|--------------|
| Источник данных | `template.attributes[]` | `product.attributes{}` (Map) |
| Тип данных | List (упорядоченный) | Map (неупорядоченный) |
| Порядок | Четкий (sortOrder) | Случайный |
| Проблема | Нет | ❌ Порядок отличается |

