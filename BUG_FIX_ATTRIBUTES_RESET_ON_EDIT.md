# 🐛 Исправление: При редактировании товара в пути сбрасываются характеристики

## 🔴 ПРОБЛЕМА

При редактировании товара в разделе "Товары в пути":
1. Открываешь карточку товара
2. Видишь заполненные характеристики (например, "Длина: 20")
3. Нажимаешь "Обновить"
4. ❌ Поля характеристик **сбрасываются** (пусто)
5. На сервер отправляются пустые значения вместо исходных

### Симптомы:
```
Было:       Длина: 20, Ширина: 30, Материал: Сосна
Нажали обновить
Стало:      Длина: [пусто], Ширина: [пусто], Материал: [пусто]
```

---

## 🔍 ПРИЧИНА

В функции `_loadProductTemplateAttributes()` при загрузке атрибутов шаблона товара:

```dart
// ❌ НЕПРАВИЛЬНО (было):
final existingValue = _isEditing && widget.product != null
  ? _products[index].attributes[attribute.variable]?.toString() ?? ''
  : '';
```

**Проблема логики:**

1. При инициализации (строка 141-145) атрибуты заполняются из `product.attributes`:
   ```dart
   productAttributes.forEach((key, value) {
     attributeControllers[key] = TextEditingController(text: value?.toString() ?? '');
     attributes[key] = value;  // ← Сохраняем в _products[index].attributes
   });
   ```

2. Потом при загрузке данных (строка 242) вызывается `_loadProductTemplateAttributes()`

3. В этой функции пытаемся получить значение из `_products[index].attributes`:
   ```dart
   ? _products[index].attributes[attribute.variable]?.toString() ?? ''
   ```

4. **НО:** Если шаблон определяет атрибуты в другом порядке или другие атрибуты, то `_products[index].attributes` может быть неполным или пустым!

5. Результат: атрибуты теряются, и в форме появляются пустые поля.

---

## ✅ РЕШЕНИЕ

**Файл:** `lib/features/products_in_transit/presentation/pages/product_in_transit_form_page.dart`

**Было (неправильно):**
```dart
Future<void> _loadProductTemplateAttributes(int index, int templateId) async {
  // ...
  for (final attribute in template.attributes) {
    final existingValue = _isEditing && widget.product != null
      ? _products[index].attributes[attribute.variable]?.toString() ?? ''  // ❌ Ищем в неполных данных
      : '';
    
    newAttributeControllers[attribute.variable] = TextEditingController(text: existingValue);
  }
  
  setState(() {
    _products[index] = ProductFormData(
      // ...
      attributes: _products[index].attributes,  // ❌ Сохраняем неполные данные
      // ...
    );
  });
}
```

**Стало (правильно):**
```dart
Future<void> _loadProductTemplateAttributes(int index, int templateId) async {
  // ...
  final attributes = <String, dynamic>{};  // ← Новая переменная для хранения найденных атрибутов
  
  for (final attribute in template.attributes) {
    String existingValue = '';
    
    if (_isEditing && widget.product != null) {
      // Пытаемся найти значение в ИСХОДНЫХ атрибутах товара
      if (widget.product!.attributes is Map<String, dynamic>) {
        final productAttributes = widget.product!.attributes as Map<String, dynamic>;
        // ✅ Ищем значение по переменной атрибута в исходных данных
        if (productAttributes.containsKey(attribute.variable)) {
          existingValue = productAttributes[attribute.variable]?.toString() ?? '';
        }
      }
    }
    
    newAttributeControllers[attribute.variable] = TextEditingController(text: existingValue);
    if (existingValue.isNotEmpty) {
      attributes[attribute.variable] = existingValue;  // ← Сохраняем найденные значения
    }
  }
  
  setState(() {
    _products[index] = ProductFormData(
      // ...
      attributes: attributes,  // ✅ Сохраняем полные данные
      // ...
    );
  });
}
```

---

## 📊 ЧТО ИЗМЕНИЛОСЬ

### До исправления:
```
widget.product.attributes → _products[index].attributes → пустые значения
          ↓                            ↓
    Исходные данные      Неполные/повреждённые данные
```

### После исправления:
```
widget.product.attributes ← ← ← ← → Новая переменная 'attributes'
          ↓                                    ↓
    Исходные данные                    Полные и корректные данные
                                             ↓
                          _products[index] = ProductFormData(
                            attributes: attributes  // ✅ Используем правильные данные
                          )
```

---

## 🎯 КЛЮЧЕВЫЕ ИЗМЕНЕНИЯ

| Параметр | До | После |
|----------|----|----|
| **Источник данных** | `_products[index].attributes` | `widget.product!.attributes` |
| **Сохранение** | Использовали старые данные | Создаём новый map с найденными значениями |
| **Проверка** | Нет проверки наличия ключа | `containsKey(attribute.variable)` |
| **Результат** | Пустые поля | Заполненные поля |

---

## 🧪 ТЕСТИРОВАНИЕ ИСПРАВЛЕНИЯ

### Шаг 1: Открыть товар в пути
### Шаг 2: Нажать редактировать
### Шаг 3: Видеть заполненные характеристики (например, "Длина: 20")
### Шаг 4: Нажать "Обновить"
### Шаг 5: ✅ Характеристики должны **остаться заполненными**

---

## 📋 ФАЙЛЫ, ЗАТРОНУТЫЕ ИСПРАВЛЕНИЕМ

1. **Изменен:**
   - `lib/features/products_in_transit/presentation/pages/product_in_transit_form_page.dart` (строки 1110-1148)

2. **Логика:**
   - Функция `_loadProductTemplateAttributes()`
   - Теперь корректно сохраняет исходные значения атрибутов

---

## 🔗 ПОДРОБНАЯ ЛОГИКА

### Процесс редактирования товара:

```
1. Открыть товар
   ↓
   _initializeProducts() 
     ↓ Заполняем _products[0].attributes из product.attributes
     ↓ Например: {length: "20", width: "30"}
   
2. Загрузить данные
   ↓
   _loadData() вызывает _loadProductTemplateAttributes()
   
3. Загрузить атрибуты шаблона
   ↓
   ДО ИСПРАВЛЕНИЯ:
     ↓ Ищем в _products[0].attributes
     ↓ Но там может быть неполные данные!
     ↓ Результат: пустые поля ❌
   
   ПОСЛЕ ИСПРАВЛЕНИЯ:
     ↓ Ищем в widget.product!.attributes (исходные данные)
     ↓ Создаём новый map с найденными значениями
     ↓ Результат: заполненные поля ✅

4. Форма готова к редактированию
   ↓
   Пользователь видит все атрибуты
   ↓
   Нажимает "Обновить"
   ↓
   Атрибуты отправляются на сервер
```

---

## ✨ ИТОГИ

| Параметр | До исправления | После исправления |
|----------|----------------|-------------------|
| **Открытие товара** | ✅ Атрибуты видны | ✅ Атрибуты видны |
| **Сохранение шаблона** | ❌ Атрибуты теряются | ✅ Атрибуты сохраняются |
| **Обновление товара** | ❌ Пусто отправляется | ✅ Значения отправляются |
| **Результат на сервере** | ❌ Пустые атрибуты | ✅ Полные атрибуты |

---

## 🚀 РЕКОМЕНДАЦИИ

1. ✅ **Исправление применено** - характеристики теперь сохраняются при редактировании
2. 🧪 **Протестируйте** на разных товарах с разными характеристиками
3. 📝 **Проверьте** аналогичную функцию в `product_inflow_form_page.dart` (если есть)
4. 💡 **Похожая проблема** может быть в других формах редактирования
