## Сравнение создания имён товаров: "Поступление товара" vs "Товары в пути"

### 📋 КРАТКОЕ РЕЗЮМЕ

Оба раздела используют **один и тот же алгоритм** создания имён товаров, но с некоторыми важными **организационными различиями**:

| Аспект | Поступление товара | Товары в пути |
|--------|------------------|-----------------|
| **Функция создания имени** | `_generateProductName()` в форме | `_generateProductName(index)` в форме |
| **Множественные товары** | ❌ НЕ поддерживаются | ✅ Поддерживаются |
| **Состояние формы** | Простое (1 товар) | Сложное (массив товаров в `_products`) |
| **Формирование имени** | Синхронно при изменении атрибутов | Синхронно при изменении атрибутов |

---

## 🔍 ДЕТАЛЬНЫЙ АНАЛИЗ

### 1. АЛГОРИТМ СОЗДАНИЯ ИМЕНИ

#### Оба раздела используют одинаковый алгоритм:

```dart
// Структура имени:
// [Название шаблона]: [Атрибуты формулы (x разделитель)], [Остальные атрибуты]

Пример: "Доска: 20 x 30, Сосна"
         ^^^^^^^^  ^^   ^^  ^^^^^
         шаблон   формула  остальные
```

#### Шаги алгоритма (одинаковы в обоих местах):

```dart
1. Получить атрибуты из шаблона товара
2. Разделить на две категории:
   - formulaAttributes (те, у которых isInFormula = true)
   - regularAttributes (type == 'number' || type == 'select')
3. Собрать части:
   - nameParts[0] = шаблон.name
   - Если есть formulaAttributes → nameParts.add(join(' x '))
   - Если есть regularAttributes → nameParts.add(join(', '))
4. Объединить: nameParts.join(': ')
```

---

## 📌 ОТЛИЧИЕ #1: АРХИТЕКТУРА ХРАНЕНИЯ ДАННЫХ

### Поступление товара (product_inflow_form_page.dart)

```dart
// Линейная структура - один товар
class _ProductInflowFormPageState {
  final _quantityController = TextEditingController();
  final _nameController = TextEditingController();
  Map<String, TextEditingController> _attributeControllers = {};
  ProductTemplateModel? _selectedTemplate;
  
  // Создание имени для ОДНОГО товара
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
}
```

**Вызов функции:**
```dart
// При изменении количества
void _onQuantityChanged() {
  _calculateNameAndVolume();  // ← вызывает _generateProductName()
}

// При изменении атрибута
void _onAttributeChanged() {
  _calculateNameAndVolume();  // ← вызывает _generateProductName()
}
```

### Товары в пути (product_in_transit_form_page.dart)

```dart
// Массивная структура - множество товаров
class _ProductInTransitFormPageState {
  List<ProductFormData> _products = [];  // ← Массив!
  
  // Каждый товар имеет свои данные
  class ProductFormData {
    final Map<String, TextEditingController> attributeControllers;
    final TextEditingController quantityController;
    final ProductTemplateModel? template;
    final String name;
    final String calculatedVolume;
    // ...
  }
  
  // Создание имени для КОНКРЕТНОГО товара по индексу
  String _generateProductName(int index) {
    final product = _products[index];  // ← Получаем конкретный товар
    if (product.template == null) return '';
    
    final formulaAttributes = <String>[];
    final regularAttributes = <String>[];
    
    for (final attribute in product.template!.attributes) {
      // Используем контроллеры из product
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
}
```

**Вызов функции:**
```dart
// При изменении количества товара
void _onProductQuantityChanged(int index, String quantity) {
  // ... обновляем _products[index]
  _calculateProductNameAndVolume(index);  // ← Передаём индекс
}

// При изменении атрибута
void _onProductAttributeChanged(TextEditingController controller) {
  for (int i = 0; i < _products.length; i++) {
    if (_products[i].attributeControllers.containsValue(controller)) {
      _calculateProductNameAndVolume(i);  // ← Находим индекс и вызываем
      break;
    }
  }
}
```

---

## 📌 ОТЛИЧИЕ #2: ОБНОВЛЕНИЕ СОСТОЯНИЯ

### Поступление товара

```dart
void _calculateNameAndVolume() {
  if (_selectedTemplate == null || _quantityController.text.isEmpty) {
    _nameController.text = '';
    _calculatedVolumeController.text = '';
    return;
  }

  // Прямое обновление контроллеров
  _nameController.text = _generateProductName();
  _calculatedVolumeController.text = _calculateVolume();
  
  // setState() вызывается автоматически слушателями
}
```

### Товары в пути

```dart
void _calculateProductNameAndVolume(int index) {
  final product = _products[index];
  if (product.template == null || product.quantity.isEmpty) {
    // Создаём новый объект ProductFormData с пустым именем
    setState(() {
      _products[index] = ProductFormData(
        productTemplateId: product.productTemplateId,
        quantity: product.quantity,
        name: '',  // ← Очищаем
        calculatedVolume: '',  // ← Очищаем
        attributes: product.attributes,
        template: product.template,
        attributeControllers: product.attributeControllers,
        quantityController: product.quantityController,
      );
    });
    return;
  }
  
  // Формируем новое имя
  final name = _generateProductName(index);
  final volume = _calculateProductVolume(index);

  // Создаём НОВЫЙ объект со всеми данными
  setState(() {
    _products[index] = ProductFormData(
      productTemplateId: product.productTemplateId,
      quantity: product.quantity,
      name: name,  // ← Новое имя
      calculatedVolume: volume,  // ← Новый объём
      attributes: product.attributes,
      template: product.template,
      attributeControllers: product.attributeControllers,
      quantityController: product.quantityController,
    );
  });
}
```

---

## 📌 ОТЛИЧИЕ #3: ОТОБРАЖЕНИЕ ИМЕНИ НА КАРТОЧКЕ ТОВАРА

### Поступление товара (product_inflow_list_page.dart)

```dart
Widget _buildProductHeader(String fullName) {
  // Разбиваем по двоеточию
  if (fullName.contains(':')) {
    final parts = fullName.split(':');
    final productName = parts[0].trim();
    final characteristics = parts.sublist(1).join(':').trim();
    
    // Отображаем на две строки
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$productName:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(characteristics, style: TextStyle(fontSize: 14, color: Colors.grey.shade700))
      ],
    );
  }
  
  // Если нет двоеточия, показываем как есть
  return Text(fullName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
}
```

**Результат на экране:**
```
┌─────────────────────────────┐
│ Доска:                      │  ← Название товара
│ 20 x 30, Сосна              │  ← Характеристики (серый)
│                             │
│ Количество: 100 шт          │
│ Объем: 0.600 м³             │
└─────────────────────────────┘
```

### Товары в пути (product_in_transit_list_page.dart)

```dart
Widget _buildProductHeader(String fullName) {
  // Разбиваем по двоеточию - ИДЕНТИЧНЫЙ КОД
  if (fullName.contains(':')) {
    final parts = fullName.split(':');
    final productName = parts[0].trim();
    final characteristics = parts.sublist(1).join(':').trim();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$productName:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(characteristics, style: TextStyle(fontSize: 14, color: Colors.grey.shade700))
      ],
    );
  }
  
  return Text(fullName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
}
```

**Результат на экране - ИДЕНТИЧНЫЙ**
```
┌─────────────────────────────┐
│ Доска:                      │  ← Название товара
│ 20 x 30, Сосна              │  ← Характеристики (серый)
│                             │
│ Количество: 100 шт          │
│ Объем: 0.600 м³             │
│ Дата отгрузки: 2024-01-15   │
└─────────────────────────────┘
```

---

## 🎯 ТАБЛИЦА РАЗЛИЧИЙ

| Параметр | Поступление товара | Товары в пути |
|----------|------------------|-----------------|
| **Количество товаров** | 1 (фиксированное) | N (динамическое) |
| **Тип данных** | Отдельные переменные | Массив `List<ProductFormData>` |
| **Сохранение имени** | В `_nameController` | В объекте `ProductFormData.name` |
| **Пересчёт имени** | `_generateProductName()` | `_generateProductName(index)` |
| **Функция для пересчёта** | `_calculateNameAndVolume()` | `_calculateProductNameAndVolume(index)` |
| **setState() вызовы** | Неявные (через слушатели) | Явные в `_calculateProductNameAndVolume` |
| **Отображение** | Идентичное разбору по `:` | Идентичное разбору по `:` |
| **Дополнительные даты** | Только дата поступления | Дата отгрузки + ожидаемая дата прибытия |
| **Место отгрузки** | ❌ Нет | ✅ Есть |

---

## ✅ ВЫВОДЫё

### Сходства:
1. ✅ **Алгоритм создания имени идентичен** - одна и та же логика разделения атрибутов
2. ✅ **Формат имени одинаков** - `[Шаблон]: [Атрибуты формулы x], [Остальные]`
3. ✅ **Отображение на карточке идентично** - разбор по двоеточию и форматирование
4. ✅ **Триггеры пересчёта одинаковы** - при изменении количества и атрибутов

### Отличия:
1. ❌ **Архитектура данных** - Поступление использует простые переменные, Товары в пути используют массив
2. ❌ **Обновление состояния** - Поступление = прямое обновление контроллеров, Товары в пути = пересоздание объекта
3. ❌ **Методы пересчёта** - Поступление = без параметров, Товары в пути = с параметром index
4. ❌ **Количество товаров** - Поступление = 1, Товары в пути = много

### Рекомендации:
- 🔄 **Рефакторинг**: Можно создать общую утилиту `generateProductName()` для избежания дублирования кода
- 📦 **Класс-помощник**: Можно создать `ProductNameGenerator` для инкапсуляции логики
- 🧪 **Тестирование**: Оба алгоритма можно протестировать с одним набором тестов

---

## 📊 ВИЗУАЛЬНЫЕ ДИАГРАММЫ ПОТОКА

### Поступление товара - ПРОСТОЙ ПОТОК

```
┌─────────────────────────────────────────────────────────────┐
│         ФОРМА ПОСТУПЛЕНИЯ ТОВАРА                            │
└─────────────────────────────────────────────────────────────┘
                            │
                   Пользователь вводит:
        ┌─────────────────┬──────────────┬──────────────┐
        ▼                 ▼              ▼              ▼
    Склад          Производитель   Шаблон товара   Дата
        │                 │              │              │
        └─────────────────┴──────────────┴──────────────┘
                            │
                     ▼      ▼     ▼
                  При изменении шаблона:
                  _onTemplateChanged()
                        │
                        ▼
                _loadTemplateAttributes()
                  (загружаем атрибуты)
                        │
         ┌──────────────┴──────────────┐
         ▼                             ▼
    При вводе           При выборе атрибутов
    количества          (number/select)
    _onQuantityChanged() _onAttributeChanged()
         │                             │
         └──────────────┬──────────────┘
                        │
                        ▼
            _calculateNameAndVolume()
                        │
         ┌──────────────┴──────────────┐
         ▼                             ▼
    _generateProductName()      _calculateVolume()
         │                             │
         │  Собираем атрибуты         │
         │  1. Разделяем по типам     │
         │  2. Формируем nameParts[]  │
         │  3. Объединяем с ': '      │
         │                             │
    "Доска: 20 x 30, Сосна"    "0.600"
         │                             │
         └──────────────┬──────────────┘
                        │
                        ▼
        Обновляем контроллеры:
        _nameController.text = ...
        _calculatedVolumeController.text = ...
                        │
                        ▼
        На экране отображается
        (поле "Наименование" readonly)
```

### Товары в пути - СЛОЖНЫЙ ПОТОК

```
┌─────────────────────────────────────────────────────────────┐
│         ФОРМА ТОВАРОВ В ПУТИ (МНОЖЕСТВЕННЫЕ)                │
└─────────────────────────────────────────────────────────────┘
                            │
                   Пользователь вводит:
        ┌─────────────────┬──────────────┐
        ▼                 ▼              ▼
      Общие данные      Товары 1      Товары 2 ...
    (Склад, Дата)    (шаблон,       (шаблон,
      отгрузки       кол-во,атр)    кол-во,атр)
                        │               │
        ┌───────────────┴───────────────┤
        ▼                               ▼
    _products[0]                    _products[1]
    ProductFormData                 ProductFormData
      ├─ template                     ├─ template
      ├─ quantity                     ├─ quantity
      ├─ name                         ├─ name
      ├─ calculatedVolume             ├─ calculatedVolume
      └─ attributeControllers[]       └─ attributeControllers[]


Поток для каждого товара при изменении:
  
  При выборе шаблона (товар 0):
  _onProductTemplateChanged(0, templateId)
          │
          ├─ setState({ _products[0] = ... })
          │
          ├─ _loadProductTemplateAttributes(0, templateId)
          │     └─ Загружаем атрибуты для товара 0
          │
          └─ _calculateProductNameAndVolume(0)


  При вводе количества (товар 0):
  _onProductQuantityChanged(0, quantity)
          │
          ├─ setState({ _products[0].quantity = quantity })
          │
          └─ _calculateProductNameAndVolume(0)


  При изменении атрибута (товар 0):
  _onProductAttributeChanged(controller)
          │
          ├─ Ищем какой товар содержит этот controller
          │  for (int i = 0; i < _products.length; i++)
          │    if (_products[i].attributeControllers.containsValue(controller))
          │
          ├─ Нашли: индекс = 0
          │
          └─ _calculateProductNameAndVolume(0)


  Функция пересчёта:
  _calculateProductNameAndVolume(0)
          │
          ▼
    final product = _products[0]
          │
    if (product.template == null || product.quantity.isEmpty)
          ├─ true  → setState({ _products[0].name = '' })
          │
          └─ false → Пересчитываем
                    name = _generateProductName(0)
                    volume = _calculateProductVolume(0)
                    │
                    setState({
                      _products[0] = ProductFormData(
                        name: name,
                        calculatedVolume: volume,
                        ... остальные поля
                      )
                    })
```

---

## 🔄 СРАВНЕНИЕ ВЫЗОВОВ

### Поступление товара: Простой случай

```dart
// 1️⃣  Выбираем шаблон
_selectedProductTemplateId = 5;
_onTemplateChanged();
  ↓
_loadTemplateAttributes();  // Загружаем атрибуты шаблона 5
_calculateNameAndVolume();
  ├─ _nameController.text = _generateProductName()
  └─ _calculatedVolumeController.text = _calculateVolume()

// 2️⃣  Вводим количество
_quantityController.text = "100";
_onQuantityChanged();
  ↓
_calculateNameAndVolume();
  ├─ _nameController.text = _generateProductName()
  └─ _calculatedVolumeController.text = _calculateVolume()

// 3️⃣  Выбираем значение атрибута "Длина"
_attributeControllers['length'].text = "20";
_onAttributeChanged();
  ↓
_calculateNameAndVolume();
  ├─ _nameController.text = _generateProductName()
  └─ _calculatedVolumeController.text = _calculateVolume()
```

### Товары в пути: Сложный случай с несколькими товарами

```dart
// 1️⃣  Товар 0: Выбираем шаблон
_products[0].productTemplateId = 5;
_onProductTemplateChanged(0, 5);
  ↓
_loadProductTemplateAttributes(0, 5);  // Загружаем для товара 0
_calculateProductNameAndVolume(0);
  ├─ _products[0].name = _generateProductName(0)
  └─ _products[0].calculatedVolume = _calculateProductVolume(0)

// 2️⃣  Добавляем второй товар
_addProduct();  // _products.length == 2

// 3️⃣  Товар 1: Выбираем шаблон
_products[1].productTemplateId = 7;
_onProductTemplateChanged(1, 7);
  ↓
_loadProductTemplateAttributes(1, 7);  // Загружаем для товара 1
_calculateProductNameAndVolume(1);
  ├─ _products[1].name = _generateProductName(1)
  └─ _products[1].calculatedVolume = _calculateProductVolume(1)

// 4️⃣  Товар 0: Вводим количество
_products[0].quantityController.text = "100";
_onProductQuantityChanged(0, "100");
  ↓
_calculateProductNameAndVolume(0);
  ├─ _products[0].name = _generateProductName(0)
  └─ _products[0].calculatedVolume = _calculateProductVolume(0)

// 5️⃣  Товар 1: Вводим количество
_products[1].quantityController.text = "50";
_onProductQuantityChanged(1, "50");
  ↓
_calculateProductNameAndVolume(1);
  ├─ _products[1].name = _generateProductName(1)
  └─ _products[1].calculatedVolume = _calculateProductVolume(1)
```

---

## 📝 КОД: ЯДРО АЛГОРИТМА

Вот точный алгоритм (**идентичный в обоих местах**):

```dart
String _generateProductName(/* optional index */) {
  // Получить шаблон
  final template = /* _selectedTemplate или _products[index].template */;
  if (template == null) return '';

  // Разделить атрибуты на две категории
  final formulaAttributes = <String>[];
  final regularAttributes = <String>[];

  for (final attribute in template.attributes) {
    final value = /* получить значение атрибута */;
    if (value.isEmpty) continue;

    // Категория 1: Атрибуты, входящие в формулу (размеры, вес и т.д.)
    if (attribute.isInFormula) {
      formulaAttributes.add(value);
    }
    // Категория 2: Остальные числовые и выборочные атрибуты
    else if (attribute.type == 'number' || attribute.type == 'select') {
      regularAttributes.add(value);
    }
  }

  // Построить имя
  final List<String> nameParts = [template.name];

  // Добавить атрибуты формулы (соединены с ' x ')
  if (formulaAttributes.isNotEmpty) {
    nameParts.add(formulaAttributes.join(' x '));
  }

  // Добавить остальные атрибуты (соединены с ', ')
  if (regularAttributes.isNotEmpty) {
    nameParts.add(regularAttributes.join(', '));
  }

  // Объединить все части двоеточием
  return nameParts.join(': ');
}
```

### Примеры выходных значений:

```
Входные данные:
  Шаблон: "Доска"
  Атрибуты (isInFormula=true): ["20", "30"]  → размеры
  Атрибуты (остальные): ["Сосна"]            → материал
  
Выход:
  "Доска: 20 x 30, Сосна"

---

Входные данные:
  Шаблон: "Краска"
  Атрибуты (isInFormula=true): []
  Атрибуты (остальные): ["Красный", "Глянцевая"]
  
Выход:
  "Краска: Красный, Глянцевая"

---

Входные данные:
  Шаблон: "Гвозди"
  Атрибуты (isInFormula=true): ["50"]  → длина
  Атрибуты (остальные): []
  
Выход:
  "Гвозди: 50"
```

---

## 🎯 ПРАКТИЧЕСКИЙ ПРИМЕР: ПОШАГОВОЕ СОЗДАНИЕ ИМЕНИ

### Сценарий: Пользователь создаёт товар "Доска"

**Шаг 1: Выбор шаблона**
- Шаблон: Доска (id=1)
- Атрибуты шаблона загружены:
  ```
  id | name     | variable | type   | isInFormula
  ---|----------|----------|--------|------------
  1  | Длина    | length   | number | true
  2  | Ширина   | width    | number | true
  3  | Материал | material | select | false
  ```

**Шаг 2: Ввод значений**
```
length = 20
width = 30
material = "Сосна"
quantity = 100
```

**Шаг 3: Вычисление имени**

```dart
// 1. Получаем атрибуты
formulaAttributes = [];
regularAttributes = [];

// 2. Проходим по атрибутам
attribute[0]: name="Длина", isInFormula=true, value="20"
  → formulaAttributes.add("20")  // ["20"]

attribute[1]: name="Ширина", isInFormula=true, value="30"
  → formulaAttributes.add("30")  // ["20", "30"]

attribute[2]: name="Материал", isInFormula=false, type="select", value="Сосна"
  → regularAttributes.add("Сосна")  // ["Сосна"]

// 3. Строим nameParts
nameParts = ["Доска"]
nameParts.add(["20", "30"].join(' x '))  // ["Доска", "20 x 30"]
nameParts.add(["Сосна"].join(', '))      // ["Доска", "20 x 30", "Сосна"]

// 4. Объединяем
return ["Доска", "20 x 30", "Сосна"].join(': ')
     = "Доска: 20 x 30, Сосна"
```

**Результат на экране:**
```
┌──────────────────────┐
│ Доска:               │  ← Название (жирный)
│ 20 x 30, Сосна       │  ← Характеристики (серый)
└──────────────────────┘
```

---

## ❓ ЧАСТО ЗАДАВАЕМЫЕ ВОПРОСЫ

### Q1: Почему атрибуты разделены на две категории?
**A:** Потому что:
- Атрибуты в формуле (длина, ширина, вес) → определяют размер/объём → они **существенны** → в начало имени
- Остальные атрибуты (материал, цвет) → описывают свойства → они **вспомогательны** → в конец имени

Это облегчает чтение имени: `[Основное]: [Размеры], [Свойства]`

### Q2: Почему Поступление = 1 товар, а Товары в пути = много?
**A:** Это требования бизнеса:
- **Поступление товара** - это приём одного товара на склад (документ = одна товарная позиция)
- **Товары в пути** - это отправка партии товаров в разные места (документ = много товарных позиций)

### Q3: Можно ли рефакторить, чтобы избежать дублирования?
**A:** Да! Рекомендуется создать класс-помощник:

```dart
class ProductNameGenerator {
  static String generate({
    required String templateName,
    required List<ProductAttributeModel> attributes,
    required Map<String, String> attributeValues,
  }) {
    final formulaAttributes = <String>[];
    final regularAttributes = <String>[];

    for (final attribute in attributes) {
      final value = attributeValues[attribute.variable] ?? '';
      if (value.isEmpty) continue;

      if (attribute.isInFormula) {
        formulaAttributes.add(value);
      } else if (attribute.type == 'number' || attribute.type == 'select') {
        regularAttributes.add(value);
      }
    }

    final nameParts = [templateName];
    if (formulaAttributes.isNotEmpty) {
      nameParts.add(formulaAttributes.join(' x '));
    }
    if (regularAttributes.isNotEmpty) {
      nameParts.add(regularAttributes.join(', '));
    }

    return nameParts.join(': ');
  }
}

// Использование в Поступлении:
_nameController.text = ProductNameGenerator.generate(
  templateName: _selectedTemplate!.name,
  attributes: _selectedTemplate!.attributes,
  attributeValues: {
    for (var entry in _attributeControllers.entries)
      entry.key: entry.value.text
  },
);

// Использование в Товарах в пути:
final name = ProductNameGenerator.generate(
  templateName: _products[index].template!.name,
  attributes: _products[index].template!.attributes,
  attributeValues: {
    for (var entry in _products[index].attributeControllers.entries)
      entry.key: entry.value.text
  },
);
```
