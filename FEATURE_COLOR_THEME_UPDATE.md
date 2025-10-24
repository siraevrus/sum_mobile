# Обновление цветовой схемы приложения

## Описание
Изменена основная цветовая схема приложения с синего на темно-зеленый цвет **#256437**.

## Дата реализации
23 октября 2025

## Изменения

### 1. Основной цвет приложения (Primary Color)
**Файл:** `lib/core/theme/app_colors.dart`

**Было:** `Color(0xFF2C5CCF)` - синий  
**Стало:** `Color(0xFF256437)` - темно-зеленый

Также обновлен градиент:
- **Было:** `[Color(0xFF2C5CCF), Color(0xFF1E4B9C)]`
- **Стало:** `[Color(0xFF256437), Color(0xFF1A4526)]`

### 2. Боковое меню (Sidebar)
**Файл:** `lib/features/dashboard/presentation/widgets/modern_sidebar.dart`

#### Изменения:
- **Основной фон меню:** `Color(0xFF256437)` (темно-зеленый)
- **Разделители:** `Color(0xFF2D7A45)` (светло-зеленый)
- **Аватар пользователя:** `Color(0xFF38A169)` (зеленый)
- **Активные пункты меню:** `Color(0xFF2D7A45)` (светло-зеленый фон)
- **Раскрытые подменю:** `Color(0xFF1E5030)` (темно-зеленый)

### 3. Шапки страниц (AppBar)
Обновлены цвета AppBar во всех внутренних страницах приложения:

#### Обновленные файлы:
1. **Раздел "Остатки на складе":**
   - `lib/features/inventory/presentation/pages/inventory_tabs_page.dart`
   - `lib/features/inventory/presentation/pages/create_stock_form_page.dart`

2. **Раздел "Товары в пути":**
   - `lib/features/products_in_transit/presentation/pages/product_in_transit_form_page.dart`
   - `lib/features/products_in_transit/presentation/pages/product_in_transit_detail_page.dart`

3. **Раздел "Приемка":**
   - `lib/features/acceptance/presentation/pages/acceptance_form_page.dart`
   - `lib/features/acceptance/presentation/pages/acceptance_detail_page.dart`

4. **Раздел "Поступление товаров":**
   - `lib/features/products_inflow/presentation/pages/product_inflow_form_page.dart`
   - `lib/features/products_inflow/presentation/pages/product_inflow_detail_page.dart`

5. **Раздел "Производители":**
   - `lib/features/producers/presentation/pages/producer_form_page.dart`
   - `lib/features/producers/presentation/pages/producers_list_page.dart`

6. **Раздел "Запросы":**
   - `lib/features/requests/presentation/pages/request_form_page.dart`

7. **Раздел "Реализация":**
   - `lib/features/sales/presentation/pages/sale_form_page.dart`

8. **Раздел "Сотрудники":**
   - `lib/features/users/presentation/pages/user_form_page.dart`

9. **Раздел "Компании":**
   - `lib/features/companies/presentation/pages/company_form_page.dart`

10. **Раздел "Склады":**
    - `lib/features/warehouses/presentation/pages/warehouse_form_page.dart`

## Визуальные изменения

### Основной цвет (#256437)
- Используется для всех AppBar (шапок страниц)
- Все кнопки и активные элементы
- Акцентные элементы интерфейса

### Боковое меню
- **Фон:** Темно-зеленый #256437
- **Активный пункт:** Светло-зеленый #2D7A45 с белым текстом
- **Неактивные пункты:** Серый текст #BDC3C7
- **Разделители:** Зеленый #2D7A45
- **Аватар:** Зеленый #38A169

### Особенности
- Все изменения применяются автоматически через `AppColors.primary`
- Единая цветовая схема во всех разделах приложения
- Улучшенная визуальная согласованность интерфейса

## Технические детали

### Использование цветов
```dart
// В AppBar
backgroundColor: AppColors.primary,
foregroundColor: Colors.white,

// В боковом меню
decoration: BoxDecoration(
  color: Color(0xFF256437),
),

// Активные пункты меню
selectedTileColor: Color(0xFF2D7A45),
```

### Добавленные импорты
Во все обновленные файлы добавлен импорт:
```dart
import 'package:sum_warehouse/core/theme/app_colors.dart';
```

## Сборка
APK файл успешно собран с новыми цветами:
- **Размер:** 63.2 MB
- **Путь:** `build/app/outputs/flutter-apk/app-release.apk`

## Проверка
После установки обновленного APK, все следующие элементы будут в темно-зеленой цветовой схеме:
- ✅ Боковое меню приложения
- ✅ Активные ссылки в разделе "Остатки на складе"
- ✅ Шапки всех внутренних страниц всех разделов
- ✅ Все кнопки и активные элементы

## Цветовая палитра

### Основные цвета
- **Primary:** #256437 (темно-зеленый)
- **Primary Dark:** #1A4526 (более темный зеленый для градиента)
- **Active Menu:** #2D7A45 (светло-зеленый для активных элементов)
- **Submenu:** #1E5030 (темный зеленый для подменю)
- **Avatar:** #38A169 (зеленый для аватара)

### Вспомогательные цвета (не изменялись)
- **Success:** #38A169 (зеленый)
- **Error:** #E53E3E (красный)
- **Warning:** #D69E2E (желтый)
- **Info:** #3182CE (синий)

