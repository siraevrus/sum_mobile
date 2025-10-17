# 📝 КРАТКОЕ РЕЗЮМЕ: Создание имён товаров

## ❓ ВОПРОС
Как происходит создание имени (name) в разделе Поступление товара и Товары в пути? В чем отличия?

---

## ✅ ОТВЕТ

### 🎯 ГЛАВНЫЙ ВЫВОД
**Алгоритм создания имён ИДЕНТИЧЕН в обоих разделах, но отличается АРХИТЕКТУРА хранения и управления данными.**

---

## 📊 СРАВНЕНИЕ В 5 ПУНКТАХ

### 1️⃣ АЛГОРИТМ СОЗДАНИЯ (ОДИНАКОВЫЙ)

```
Формула имени: [Название шаблона]: [Атрибуты формулы x], [Остальные атрибуты]

Пример: "Доска: 20 x 30, Сосна"
```

**Шаги:**
1. Получить все атрибуты товара из шаблона
2. Разделить на две группы:
   - `isInFormula = true` → атрибуты размеров (20, 30) → соединяются с ` x `
   - остальное (material) → соединяются с `, `
3. Собрать: `[Название]: [размеры], [материал]`

### 2️⃣ ХРАНЕНИЕ ДАННЫХ (ОТЛИЧИЕ №1)

| Параметр | Поступление товара | Товары в пути |
|----------|------------------|-----------------|
| Количество товаров | 1 товар | N товаров |
| Тип данных | Отдельные переменные | `List<ProductFormData>` |
| Откуда берём имя | `_nameController.text` | `_products[index].name` |

**Поступление товара:**
```dart
class _ProductInflowFormPageState {
  ProductTemplateModel? _selectedTemplate;  // 1 шаблон
  Map<String, TextEditingController> _attributeControllers = {};  // Для 1 товара
  TextEditingController _nameController;  // Сохраняем имя в контроллер
}
```

**Товары в пути:**
```dart
class _ProductInTransitFormPageState {
  List<ProductFormData> _products = [];  // Массив товаров!
  
  class ProductFormData {
    ProductTemplateModel? template;  // Шаблон для THIS товара
    Map<String, TextEditingController> attributeControllers;  // Атрибуты THIS товара
    String name;  // Имя THIS товара
  }
}
```

### 3️⃣ ВЫЗОВ ФУНКЦИИ ПЕРЕСЧЁТА (ОТЛИЧИЕ №2)

**Поступление товара:**
```dart
// При любом изменении
void _onAttributeChanged() {
  _calculateNameAndVolume();  // Без параметров
}

void _generateProductName() {
  // Использует _attributeControllers (один набор для одного товара)
  for (final attribute in _selectedTemplate!.attributes) {
    final value = _attributeControllers[attribute.variable]?.text ?? '';
  }
}
```

**Товары в пути:**
```dart
// При изменении товара N
void _onProductAttributeChanged(TextEditingController controller) {
  // Ищём какой товар изменился
  for (int i = 0; i < _products.length; i++) {
    if (_products[i].attributeControllers.containsValue(controller)) {
      _calculateProductNameAndVolume(i);  // С параметром index!
      break;
    }
  }
}

void _generateProductName(int index) {
  // Использует _products[index].attributeControllers
  final product = _products[index];
  for (final attribute in product.template!.attributes) {
    final value = product.attributeControllers[attribute.variable]?.text ?? '';
  }
}
```

### 4️⃣ ОБНОВЛЕНИЕ ЭКРАНА (ОТЛИЧИЕ №3)

**Поступление товара:**
```dart
void _calculateNameAndVolume() {
  // Прямое обновление контроллеров
  _nameController.text = _generateProductName();
  _calculatedVolumeController.text = _calculateVolume();
  // setState() вызывается слушателями контроллеров
}
```

**Товары в пути:**
```dart
void _calculateProductNameAndVolume(int index) {
  final product = _products[index];
  
  // Создаём НОВЫЙ объект ProductFormData
  setState(() {
    _products[index] = ProductFormData(
      // ... копируем все поля ...
      name: _generateProductName(index),  // Новое имя
      calculatedVolume: _calculateProductVolume(index),  // Новый объём
    );
  });
}
```

### 5️⃣ ОТОБРАЖЕНИЕ (ОДИНАКОВОЕ)

**Оба используют одинаковую функцию разбора:**

```dart
Widget _buildProductHeader(String fullName) {
  if (fullName.contains(':')) {
    final parts = fullName.split(':');
    final productName = parts[0].trim();  // "Доска"
    final characteristics = parts.sublist(1).join(':').trim();  // "20 x 30, Сосна"
    
    // Отображаем на две строки
    return Column(
      children: [
        Text('$productName:'),  // "Доска:" - жирный
        Text(characteristics),   // "20 x 30, Сосна" - серый
      ],
    );
  }
}
```

---

## 🔍 ТАБЛИЦА ОТЛИЧИЙ

| Аспект | Поступление | Товары в пути |
|--------|-----------|-----------------|
| **Фаза 1: Выбор шаблона** | `_onTemplateChanged()` | `_onProductTemplateChanged(index)` |
| **Фаза 2: Загрузка атрибутов** | `_loadTemplateAttributes()` | `_loadProductTemplateAttributes(index)` |
| **Фаза 3: Пересчёт имени** | `_calculateNameAndVolume()` | `_calculateProductNameAndVolume(index)` |
| **Фаза 4: Алгоритм** | `_generateProductName()` | `_generateProductName(index)` |
| **Как вызывается** | 1 раз | N раз (по одному на каждый товар) |
| **Результат** | В `_nameController.text` | В `_products[index].name` |

---

## 📁 ГДЕ НАХОДЯТСЯ ФАЙЛЫ

### Создание имени (формы):
- ✅ **Поступление**: `lib/features/products_inflow/presentation/pages/product_inflow_form_page.dart` (строки 210-237)
- ✅ **Товары в пути**: `lib/features/products_in_transit/presentation/pages/product_in_transit_form_page.dart` (строки 1188-1216)

### Отображение имени (списки):
- ✅ **Поступление**: `lib/features/products_inflow/presentation/pages/product_inflow_list_page.dart` (строки 531-574)
- ✅ **Товары в пути**: `lib/features/products_in_transit/presentation/pages/product_in_transit_list_page.dart` (строки 529-573)

---

## 💡 КОД: СУТЬ ОТЛИЧИЯ

### Поступление товара (простой случай)
```dart
// 1 ТОВАР = 1 set контроллеров
String _generateProductName() {
  for (final attribute in _selectedTemplate!.attributes) {
    final value = _attributeControllers[attribute.variable]?.text;
    // ... обработка
  }
}
```

### Товары в пути (сложный случай)
```dart
// N ТОВАРОВ = N sets контроллеров
String _generateProductName(int index) {
  final product = _products[index];  // ← получаем конкретный товар
  
  for (final attribute in product.template!.attributes) {
    final value = product.attributeControllers[attribute.variable]?.text;
    // ... обработка
  }
}
```

---

## 🎯 ПРАКТИЧЕСКИЙ ПРИМЕР

### Сценарий: Пользователь создаёт "Доску: 20 x 30, Сосна"

#### Поступление товара:
```
1. Выбираем шаблон "Доска"
   → _onTemplateChanged()
   → _loadTemplateAttributes()
   
2. Вводим "20" в поле "Длина"
   → слушатель контроллера
   → _onAttributeChanged()
   → _calculateNameAndVolume()
   → _generateProductName()
   → _nameController.text = "Доска: 20..."
   
3. Вводим "30" в поле "Ширина"
   → _onAttributeChanged()
   → _calculateNameAndVolume()
   → _generateProductName()
   → _nameController.text = "Доска: 20 x 30..."
   
4. Выбираем "Сосна" в поле "Материал"
   → _onAttributeChanged()
   → _calculateNameAndVolume()
   → _generateProductName()
   → _nameController.text = "Доска: 20 x 30, Сосна"  ← ГОТОВО
```

#### Товары в пути (товар 0):
```
1. Выбираем шаблон "Доска" для товара 0
   → _onProductTemplateChanged(0, templateId)
   → _loadProductTemplateAttributes(0, templateId)
   
2. Вводим "20" в поле "Длина" товара 0
   → слушатель контроллера
   → _onProductAttributeChanged(controller)
   → находим что это товар 0
   → _calculateProductNameAndVolume(0)
   → _generateProductName(0)
   → setState({ _products[0].name = "Доска: 20..." })
   
3. Вводим "30" в поле "Ширина" товара 0
   → _onProductAttributeChanged(controller)
   → _calculateProductNameAndVolume(0)
   → _generateProductName(0)
   → setState({ _products[0].name = "Доска: 20 x 30..." })
   
4. Выбираем "Сосна" в поле "Материал" товара 0
   → _onProductAttributeChanged(controller)
   → _calculateProductNameAndVolume(0)
   → _generateProductName(0)
   → setState({ _products[0].name = "Доска: 20 x 30, Сосна" })  ← ГОТОВО

5. ОДНОВРЕМЕННО можем работать с товаром 1:
   → Выбираем шаблон "Краска" для товара 1
   → _onProductTemplateChanged(1, templateId)
   → _loadProductTemplateAttributes(1, templateId)
   → ... и так далее...
```

---

## 📚 ДОПОЛНИТЕЛЬНЫЕ МАТЕРИАЛЫ

Для полного понимания см.:
- 📄 `COMPARISON_PRODUCT_NAME_CREATION.md` - Детальное сравнение с диаграммами
- 📄 `PRODUCT_NAME_REFACTORING_GUIDE.md` - Рекомендации по рефакторингу кода

---

## ✨ КЛЮЧЕВЫЕ ВЫВОДЫ

| # | Вывод |
|---|-------|
| 1 | ✅ Алгоритм **идентичен** - один и тот же способ собрать имя |
| 2 | ❌ Архитектура **отличается** - простой случай vs. сложный |
| 3 | 💡 Можно рефакторить - вынести в общий класс `ProductNameGenerator` |
| 4 | 🎯 Результат одинаков - одинаковое отображение на карточке |
| 5 | 🚀 Рекомендуется - создать unit тесты для алгоритма |
