# Функционал поиска в разделе "Остатки на складе"

## Описание
Добавлен функционал поиска по названию товара во всех вкладках раздела "Остатки на складе":
- **По производителю** - поиск товаров конкретного производителя
- **По складу** - поиск товаров на конкретном складе  
- **По компании** - поиск товаров компании

## Технические изменения

### 1. Data Layer - Remote Data Source
**Файл:** `lib/features/inventory/data/datasources/inventory_stocks_remote_datasource.dart`

Добавлен параметр `search` в методы:
- `getProducerDetails(int producerId, {int page = 1, int perPage = 15, String? search})`
- `getWarehouseDetails(int warehouseId, {int page = 1, int perPage = 15, String? search})`
- `getCompanyDetails(int companyId, {int page = 1, int perPage = 15, String? search})`

Параметр передается в query параметры API запроса:
```dart
if (search != null && search.isNotEmpty) {
  queryParams['search'] = search;
}
```

### 2. Presentation Layer - Providers
**Файл:** `lib/features/inventory/presentation/providers/inventory_stocks_provider.dart`

Создан класс `DetailsParams` для передачи параметров в провайдеры:
```dart
class DetailsParams {
  final int id;
  final String? search;
  final int page;
  final int perPage;
}
```

Обновлены провайдеры для принятия объекта `DetailsParams`:
- `producerDetailsProvider(DetailsParams params)`
- `warehouseDetailsProvider(DetailsParams params)`
- `companyDetailsProvider(DetailsParams params)`

### 3. Presentation Layer - UI
**Файл:** `lib/features/inventory/presentation/pages/inventory_tabs_page.dart`

В страницу `_InventoryStocksListPage` добавлено:

**Поле поиска:**
- `TextEditingController _searchController` для управления текстом поиска
- `String _searchQuery` для хранения поискового запроса
- UI элемент - красивое поле поиска с иконками и кнопкой очистки

**Интеграция с провайдерами:**
```dart
final params = DetailsParams(
  id: widget.filterId,
  search: _searchQuery.isEmpty ? null : _searchQuery,
);

final detailsAsync = switch (widget.filterType) {
  _FilterType.producer => ref.watch(producerDetailsProvider(params)),
  _FilterType.warehouse => ref.watch(warehouseDetailsProvider(params)),
  _FilterType.company => ref.watch(companyDetailsProvider(params)),
};
```

## API Endpoints

### Поиск по производителю
```
GET /api/stocks/by-producer/{producerId}?search={query}&per_page=50
```

### Поиск по складу  
```
GET /api/stocks/by-warehouse/{warehouseId}?search={query}&per_page=50
```

### Поиск по компании
```
GET /api/stocks/by-company/{companyId}?search={query}&per_page=50
```

## Пользовательский интерфейс

### Поле поиска
- Расположено вверху страницы под AppBar
- Placeholder: "Поиск по названию товара..."
- Иконка поиска слева
- Кнопка очистки справа (появляется при вводе текста)
- Обновление результатов происходит автоматически при изменении текста

### Особенности
- Поиск чувствителен к регистру (зависит от реализации на бэкенде)
- Результаты обновляются в реальном времени
- Пустой поисковый запрос показывает все остатки
- Работает со всеми тремя типами фильтрации (производитель, склад, компания)

## Тестирование

Для тестирования функционала:
1. Откройте раздел "Остатки на складе"
2. Выберите любую вкладку (Производитель/Склад/Компания)
3. Нажмите на карточку для просмотра деталей
4. Введите текст в поле поиска
5. Результаты обновятся автоматически

## Примеры использования

### Поиск деревянных изделий у производителя
1. Перейдите на вкладку "Производитель"
2. Выберите производителя
3. Введите "деревянная" в поле поиска

### Поиск профиля на складе
1. Перейдите на вкладку "Склад"
2. Выберите склад
3. Введите "профиль" в поле поиска

### Поиск краски в компании
1. Перейдите на вкладку "Компания"
2. Выберите компанию
3. Введите "краска" в поле поиска

## Совместимость
- Требует поддержку параметра `search` на бэкенде для эндпоинтов:
  - `/api/stocks/by-producer/{id}`
  - `/api/stocks/by-warehouse/{id}`
  - `/api/stocks/by-company/{id}`

## Дата реализации
23 октября 2025

