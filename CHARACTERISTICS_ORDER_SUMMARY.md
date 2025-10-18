# 📋 Резюме: Порядок характеристик товара

## 🎯 Краткий ответ

**Почему порядок отличается?**

Потому что используются **разные источники данных** и **разные типы данных**:

| | При создании | При просмотре превью |
|---|---|---|
| **Файл** | `product_inflow_form_page.dart` | `product_inflow_detail_page.dart` |
| **Источник данных** | `_selectedTemplate!.attributes` | `_product.attributes` |
| **Тип данных** | `List<ProductAttributeModel>` | `Map<String, dynamic>` |
| **Порядок** | ✅ Упорядочено (sortOrder) | ❌ Неупорядочено (HashMap) |
| **Метод итерации** | `for (final attr in list)` | `.entries` без сортировки |

---

## 🔍 Глубокий анализ

### 📝 Форма создания (правильно)

```dart
// product_inflow_form_page.dart, строка 585-598
List<Widget> _buildAttributeFields() {
  final List<Widget> fields = [];
  
  // Проходит по массиву в ПОРЯДКЕ из шаблона
  for (final attribute in _selectedTemplate!.attributes) {
    fields.add(_buildAttributeField(attribute, controller));
  }
  
  return fields;  // ✅ Порядок как в BD (sortOrder)
}
```

**Шаблон из API содержит:**
```json
{
  "attributes": [
    {"variable": "height", "name": "Высота", "sortOrder": 1},
    {"variable": "width", "name": "Ширина", "sortOrder": 2},
    {"variable": "depth", "name": "Глубина", "sortOrder": 3}
  ]
}
```

---

### 🖼️ Превью карточки (неправильно)

```dart
// product_inflow_detail_page.dart, строка 193-197
(_product.attributes as Map).entries
    .map((entry) => _buildInfoRow(
        _getAttributeDisplayName(entry.key.toString()), 
        entry.value.toString()))
    .toList()
```

**Товар из API содержит:**
```json
{
  "attributes": {
    "height": "10",
    "width": "5",
    "depth": "3"
  }
}
```

**Проблема:** Map в Dart - это неупорядоченная коллекция!
- При каждой итерации порядок может быть разным
- Нет гарантии соблюдения порядка sortOrder
- Результат зависит от хеша ключей

---

## 💡 Решение

### ✅ Рекомендуемое исправление

Использовать шаблон (который содержит правильный порядок) при отображении:

```dart
// product_inflow_detail_page.dart, строка 193-197

// БЫЛО (неправильно):
(_product.attributes as Map).entries.map(...)

// СТАНЕТ (правильно):
if (_selectedTemplate != null && _product.attributes != null) {
  return _selectedTemplate!.attributes
      .where((attr) => _product.attributes.containsKey(attr.variable))
      .map((attr) => _buildInfoRow(
          attr.name,  // Используем name из шаблона
          _product.attributes[attr.variable].toString()))
      .toList();
}
```

**Преимущества:**
- ✅ Гарантированный порядок (из sortOrder)
- ✅ Совпадает с порядком при создании
- ✅ Надежное решение

---

## 📚 Файлы для ознакомления

1. **product_inflow_form_page.dart**
   - Строка 585-598: `_buildAttributeFields()` - как должно быть

2. **product_inflow_detail_page.dart**
   - Строка 193-197: текущая реализация - как нужно изменить
   - Строка 100-112: `_loadProductTemplate()` - загружает шаблон

3. **product_template_model.dart**
   - Строка 35: `sortOrder` - определяет порядок

---

## 🎓 Вывод

Проблема в **несогласованности источников данных**:
- При создании используется **упорядоченный List из шаблона**
- При просмотре используется **неупорядоченный Map из товара**

Решение: **Использовать тот же List (шаблон) при отображении**
