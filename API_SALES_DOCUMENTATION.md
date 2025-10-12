# API Документация: Реализация (Продажи)

## Обзор

API для управления продажами товаров со склада с полной поддержкой учета остатков, расчета НДС, статистики и экспорта данных.

**Base URL:** `http://93.189.230.65/api`

**Аутентификация:** Bearer Token (Sanctum)

**Prefix:** `/sales`

---

## 📚 Содержание

1. [Список продаж](#1-список-продаж)
2. [Просмотр продажи](#2-просмотр-продажи)
3. [Создание продажи](#3-создание-продажи)
4. [Обновление продажи](#4-обновление-продажи)
5. [Удаление продажи](#5-удаление-продажи)
6. [Обработка продажи](#6-обработка-продажи)
7. [Отмена продажи](#7-отмена-продажи)
8. [Статистика продаж](#8-статистика-продаж)
9. [Экспорт продаж](#9-экспорт-продаж)
10. [Коды ответов и ошибки](#коды-ответов-и-ошибки)

---

## 1. Список продаж

### Получить список всех продаж с фильтрацией и пагинацией

**Endpoint:** `GET /api/sales`

**Описание:** Возвращает список продаж с поддержкой поиска, фильтрации и пагинации. Пользователи (не администраторы) видят только продажи своего склада.

**Query параметры:**

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `search` | string | Нет | Поиск по номеру продажи, имени клиента или телефону |
| `warehouse_id` | integer | Нет | Фильтр по складу |
| `payment_status` | string | Нет | Фильтр по статусу оплаты: `pending`, `paid`, `partially_paid`, `cancelled` |
| `payment_method` | string | Нет | Фильтр по методу оплаты: `cash`, `card`, `bank_transfer`, `other` |
| `date_from` | date | Нет | Фильтр по дате начала (формат: YYYY-MM-DD) |
| `date_to` | date | Нет | Фильтр по дате окончания (формат: YYYY-MM-DD) |
| `active` | boolean | Нет | Фильтр только активных продаж |
| `per_page` | integer | Нет | Количество записей на странице (по умолчанию: 15) |

**Пример запроса:**
```bash
curl -X GET "http://93.189.230.65/api/sales?payment_status=paid&per_page=20&date_from=2025-10-01" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

**Пример ответа (200 OK):**
```json
{
  "data": [
    {
      "id": 102,
      "product_id": 389,
      "composite_product_key": null,
      "warehouse_id": 13,
      "user_id": 1,
      "sale_number": "SALE-202510-0002",
      "customer_name": "Тестовый Клиент ООО",
      "customer_phone": "+998901234567",
      "customer_email": "test@example.com",
      "customer_address": "Ташкент, ул. Тестовая, д. 123",
      "quantity": 5,
      "unit_price": "150000.00",
      "total_price": "862500.00",
      "cash_amount": "0.00",
      "nocash_amount": "862500.00",
      "vat_rate": "15.00",
      "vat_amount": "112500.00",
      "price_without_vat": "750000.00",
      "currency": "UZS",
      "exchange_rate": "1.0000",
      "payment_status": "paid",
      "reason_cancellation": null,
      "delivery_status": "pending",
      "notes": "Тестовая продажа через API",
      "invoice_number": null,
      "sale_date": "2025-10-12T00:00:00.000000Z",
      "delivery_date": null,
      "is_active": true,
      "created_at": "2025-10-12T20:39:18.000000Z",
      "updated_at": "2025-10-12T20:39:38.000000Z",
      "product": {
        "id": 389,
        "name": "Пиломатериалы: 3 x 33 x 3",
        "calculated_volume": "3.8610",
        "quantity": "13.000",
        "sold_quantity": 5
      },
      "warehouse": {
        "id": 13,
        "name": "Компания 1 Склад 2",
        "address": "Москва, складская улица №1"
      },
      "user": {
        "id": 1,
        "name": "Администратор",
        "email": "admin@sklad.ru"
      }
    }
  ],
  "links": {
    "first": "http://93.189.230.65/api/sales?page=1",
    "last": "http://93.189.230.65/api/sales?page=1",
    "prev": null,
    "next": null
  },
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 2
  }
}
```

**Связанные данные (Eager Loading):**
- `product` - Информация о товаре
- `warehouse` - Информация о складе
- `user` - Информация о пользователе, создавшем продажу

---

## 2. Просмотр продажи

### Получить детальную информацию о конкретной продаже

**Endpoint:** `GET /api/sales/{id}`

**Описание:** Возвращает полную информацию о продаже по её ID.

**URL параметры:**

| Параметр | Тип | Описание |
|----------|-----|----------|
| `id` | integer | ID продажи |

**Пример запроса:**
```bash
curl -X GET "http://93.189.230.65/api/sales/102" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

**Пример ответа (200 OK):**
```json
{
  "id": 102,
  "product_id": 389,
  "warehouse_id": 13,
  "user_id": 1,
  "sale_number": "SALE-202510-0002",
  "customer_name": "Тестовый Клиент ООО",
  "customer_phone": "+998901234567",
  "customer_email": "test@example.com",
  "customer_address": "Ташкент, ул. Тестовая, д. 123",
  "quantity": 5,
  "unit_price": "150000.00",
  "total_price": "862500.00",
  "cash_amount": "0.00",
  "nocash_amount": "862500.00",
  "vat_rate": "15.00",
  "vat_amount": "112500.00",
  "price_without_vat": "750000.00",
  "currency": "UZS",
  "exchange_rate": "1.0000",
  "payment_status": "paid",
  "notes": "Тестовая продажа через API",
  "sale_date": "2025-10-12T00:00:00.000000Z",
  "is_active": true,
  "created_at": "2025-10-12T20:39:18.000000Z",
  "updated_at": "2025-10-12T20:39:38.000000Z",
  "product": { ... },
  "warehouse": { ... },
  "user": { ... }
}
```

**Возможные ошибки:**
- `404 Not Found` - Продажа не найдена
- `403 Forbidden` - Доступ запрещен (не ваш склад)

---

## 3. Создание продажи

### Создать новую продажу товара

**Endpoint:** `POST /api/sales`

**Описание:** Создает новую продажу с автоматическим расчетом НДС и итоговой суммы. Автоматически генерируется уникальный номер продажи.

**Body параметры (JSON):**

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `product_id` | integer | **Да** | ID товара для продажи |
| `warehouse_id` | integer | **Да** | ID склада |
| `customer_name` | string | **Да** | Имя клиента (макс. 255 символов) |
| `customer_phone` | string | Нет | Телефон клиента (макс. 255 символов) |
| `customer_email` | string | Нет | Email клиента (валидный email, макс. 255) |
| `customer_address` | string | Нет | Адрес клиента |
| `quantity` | integer | **Да** | Количество товара (минимум: 1) |
| `unit_price` | numeric | **Да** | Цена за единицу (минимум: 0) |
| `vat_rate` | numeric | Нет | Ставка НДС в % (0-100, по умолчанию: 20) |
| `payment_method` | string | **Да** | Метод оплаты: `cash`, `card`, `bank_transfer`, `other` |
| `payment_status` | string | Нет | Статус оплаты: `pending`, `paid`, `partially_paid`, `cancelled` (по умолчанию: `pending`) |
| `currency` | string | Нет | Код валюты (3 символа, по умолчанию: `RUB`) |
| `exchange_rate` | numeric | Нет | Курс обмена (по умолчанию: 1.0000) |
| `cash_amount` | numeric | Нет | Сумма наличными (по умолчанию: 0.00) |
| `nocash_amount` | numeric | Нет | Сумма безналичными (по умолчанию: 0.00) |
| `invoice_number` | string | Нет | Номер счета/инвойса (макс. 255 символов) |
| `reason_cancellation` | string | Нет | Причина отмены (макс. 500 символов) |
| `notes` | string | Нет | Примечания |
| `sale_date` | date | **Да** | Дата продажи (формат: YYYY-MM-DD) |
| `is_active` | boolean | Нет | Активна ли продажа (по умолчанию: true) |

**Автоматические расчеты:**
- `sale_number` - Генерируется автоматически в формате `SALE-YYYYMM-XXXX`
- `price_without_vat` = `unit_price` × `quantity`
- `vat_amount` = `price_without_vat` × (`vat_rate` / 100)
- `total_price` = `price_without_vat` + `vat_amount`

**Пример запроса:**
```bash
curl -X POST "http://93.189.230.65/api/sales" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 389,
    "warehouse_id": 13,
    "customer_name": "ООО Строй-Сервис",
    "customer_phone": "+998901234567",
    "customer_email": "info@stroy-service.uz",
    "customer_address": "Ташкент, ул. Лесная, д. 45",
    "quantity": 10,
    "unit_price": 200000,
    "vat_rate": 15,
    "payment_method": "bank_transfer",
    "payment_status": "pending",
    "currency": "UZS",
    "exchange_rate": 1.0,
    "cash_amount": 0,
    "nocash_amount": 2300000,
    "notes": "Срочный заказ, доставка до 15.10.2025",
    "sale_date": "2025-10-12"
  }'
```

**Пример ответа (201 Created):**
```json
{
  "message": "Продажа создана",
  "sale": {
    "id": 103,
    "sale_number": "SALE-202510-0003",
    "product_id": 389,
    "warehouse_id": 13,
    "user_id": 1,
    "customer_name": "ООО Строй-Сервис",
    "customer_phone": "+998901234567",
    "customer_email": "info@stroy-service.uz",
    "customer_address": "Ташкент, ул. Лесная, д. 45",
    "quantity": 10,
    "unit_price": "200000.00",
    "price_without_vat": "2000000.00",
    "vat_rate": "15.00",
    "vat_amount": "300000.00",
    "total_price": "2300000.00",
    "currency": "UZS",
    "payment_status": "pending",
    "sale_date": "2025-10-12T00:00:00.000000Z",
    "created_at": "2025-10-12T21:00:00.000000Z",
    "updated_at": "2025-10-12T21:00:00.000000Z",
    "product": { ... },
    "warehouse": { ... },
    "user": { ... }
  }
}
```

**Валидация:**
- Проверяется наличие достаточного количества товара на складе
- Проверяются права доступа к указанному складу (для не-администраторов)
- Проверяется существование товара и склада в базе данных

**Возможные ошибки:**
- `400 Bad Request` - Недостаточно товара на складе
- `403 Forbidden` - Доступ к складу запрещен
- `409 Conflict` - Ошибка генерации уникального номера продажи (попробуйте еще раз)
- `422 Unprocessable Entity` - Ошибки валидации данных

---

## 4. Обновление продажи

### Обновить существующую продажу

**Endpoint:** `PUT /api/sales/{id}`

**Описание:** Обновляет данные продажи. При изменении количества, цены или ставки НДС автоматически пересчитываются все суммы.

**URL параметры:**

| Параметр | Тип | Описание |
|----------|-----|----------|
| `id` | integer | ID продажи |

**Body параметры (JSON):**

Все параметры опциональны. Обновляются только переданные поля.

| Параметр | Тип | Описание |
|----------|-----|----------|
| `customer_name` | string | Имя клиента |
| `customer_phone` | string | Телефон клиента |
| `customer_email` | string | Email клиента |
| `customer_address` | string | Адрес клиента |
| `quantity` | integer | Количество товара |
| `unit_price` | numeric | Цена за единицу |
| `vat_rate` | numeric | Ставка НДС в % |
| `currency` | string | Код валюты |
| `exchange_rate` | numeric | Курс обмена |
| `cash_amount` | numeric | Сумма наличными |
| `nocash_amount` | numeric | Сумма безналичными |
| `payment_method` | string | Метод оплаты |
| `payment_status` | string | Статус оплаты |
| `invoice_number` | string | Номер счета |
| `reason_cancellation` | string | Причина отмены |
| `notes` | string | Примечания |
| `sale_date` | date | Дата продажи |
| `is_active` | boolean | Активна ли продажа |

**Пример запроса:**
```bash
curl -X PUT "http://93.189.230.65/api/sales/102" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "payment_status": "paid",
    "invoice_number": "INV-2025-1234",
    "notes": "Оплата получена полностью"
  }'
```

**Пример ответа (200 OK):**
```json
{
  "message": "Продажа обновлена",
  "sale": {
    "id": 102,
    "sale_number": "SALE-202510-0002",
    "payment_status": "paid",
    "invoice_number": "INV-2025-1234",
    "notes": "Оплата получена полностью",
    "updated_at": "2025-10-12T21:15:00.000000Z",
    "product": { ... },
    "warehouse": { ... },
    "user": { ... }
  }
}
```

**Особенности:**
- При изменении `quantity`, `unit_price` или `vat_rate` автоматически пересчитываются:
  - `price_without_vat`
  - `vat_amount`
  - `total_price`

**Возможные ошибки:**
- `403 Forbidden` - Доступ запрещен
- `404 Not Found` - Продажа не найдена
- `422 Unprocessable Entity` - Ошибки валидации

---

## 5. Удаление продажи

### Удалить продажу

**Endpoint:** `DELETE /api/sales/{id}`

**Описание:** Удаляет продажу из базы данных (soft delete).

**URL параметры:**

| Параметр | Тип | Описание |
|----------|-----|----------|
| `id` | integer | ID продажи |

**Пример запроса:**
```bash
curl -X DELETE "http://93.189.230.65/api/sales/102" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

**Пример ответа (200 OK):**
```json
{
  "message": "Продажа удалена"
}
```

**Права доступа:**
- Администраторы могут удалять любые продажи
- Обычные пользователи могут удалять только продажи своей компании

**Возможные ошибки:**
- `403 Forbidden` - Доступ запрещен
- `404 Not Found` - Продажа не найдена

---

## 6. Обработка продажи

### Оформить продажу (списать товар со склада)

**Endpoint:** `POST /api/sales/{id}/process`

**Описание:** Завершает продажу, списывая товар со склада. Обновляет статус оплаты на `paid` и увеличивает `sold_quantity` товара.

**URL параметры:**

| Параметр | Тип | Описание |
|----------|-----|----------|
| `id` | integer | ID продажи |

**Что происходит при обработке:**
1. Проверяется наличие достаточного количества товара на складе
2. Увеличивается поле `sold_quantity` в таблице products
3. Статус оплаты меняется на `paid`
4. Обновляется timestamp продажи

**Пример запроса:**
```bash
curl -X POST "http://93.189.230.65/api/sales/102/process" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

**Пример ответа (200 OK):**
```json
{
  "message": "Продажа оформлена",
  "sale": {
    "id": 102,
    "sale_number": "SALE-202510-0002",
    "payment_status": "paid",
    "updated_at": "2025-10-12T21:30:00.000000Z",
    "product": {
      "id": 389,
      "quantity": "13.000",
      "sold_quantity": 5,
      "available_quantity": 8.0
    },
    "warehouse": { ... },
    "user": { ... }
  }
}
```

**Важно:**
- ⚠️ После обработки товар списывается со склада
- ⚠️ Операция необратима (для отмены используйте endpoint отмены продажи)
- ✅ Автоматически обновляется `sold_quantity` товара

**Возможные ошибки:**
- `400 Bad Request` - Недостаточно товара на складе
- `403 Forbidden` - Доступ запрещен
- `404 Not Found` - Товар или продажа не найдены
- `500 Internal Server Error` - Ошибка при оформлении продажи

---

## 7. Отмена продажи

### Отменить продажу (вернуть товар на склад)

**Endpoint:** `POST /api/sales/{id}/cancel`

**Описание:** Отменяет продажу, возвращая товар обратно на склад. Уменьшает `sold_quantity` товара.

**URL параметры:**

| Параметр | Тип | Описание |
|----------|-----|----------|
| `id` | integer | ID продажи |

**Что происходит при отмене:**
1. Уменьшается поле `sold_quantity` в таблице products
2. Статус оплаты меняется на `cancelled`
3. Обновляется timestamp продажи

**Пример запроса:**
```bash
curl -X POST "http://93.189.230.65/api/sales/102/cancel" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

**Пример ответа (200 OK):**
```json
{
  "message": "Продажа отменена",
  "sale": {
    "id": 102,
    "sale_number": "SALE-202510-0002",
    "payment_status": "cancelled",
    "updated_at": "2025-10-12T21:45:00.000000Z",
    "product": {
      "id": 389,
      "quantity": "13.000",
      "sold_quantity": 0,
      "available_quantity": 13.0
    },
    "warehouse": { ... },
    "user": { ... }
  }
}
```

**Важно:**
- ✅ Товар возвращается обратно на склад
- ✅ Уменьшается `sold_quantity` товара
- ⚠️ Можно отменить только обработанную продажу

**Возможные ошибки:**
- `403 Forbidden` - Доступ запрещен
- `404 Not Found` - Продажа не найдена
- `500 Internal Server Error` - Ошибка при отмене продажи

---

## 8. Статистика продаж

### Получить статистику по продажам

**Endpoint:** `GET /api/sales/stats`

**Описание:** Возвращает агрегированную статистику по продажам с возможностью фильтрации по датам и статусу оплаты.

**Query параметры:**

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `date_from` | date | Нет | Начальная дата для фильтрации |
| `date_to` | date | Нет | Конечная дата для фильтрации |
| `payment_status` | string | Нет | Фильтр по статусу оплаты |

**Пример запроса:**
```bash
curl -X GET "http://93.189.230.65/api/sales/stats?date_from=2025-10-01&date_to=2025-10-31" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

**Пример ответа (200 OK):**
```json
{
  "total_sales": 156,
  "paid_sales": 142,
  "pending_payments": 14,
  "today_sales": 8,
  "month_revenue": 45678900.50,
  "total_revenue": 123456789.00,
  "total_quantity": 3456,
  "average_sale": 321234.56
}
```

**Поля ответа:**

| Поле | Тип | Описание |
|------|-----|----------|
| `total_sales` | integer | Общее количество продаж |
| `paid_sales` | integer | Количество оплаченных продаж |
| `pending_payments` | integer | Количество продаж с ожидающей оплатой |
| `today_sales` | integer | Количество продаж за сегодня |
| `month_revenue` | numeric | Выручка за текущий месяц (только оплаченные) |
| `total_revenue` | numeric | Общая выручка (только оплаченные) |
| `total_quantity` | integer | Общее количество проданных товаров |
| `average_sale` | numeric | Средний чек (только оплаченные) |

**Права доступа:**
- Администраторы видят статистику по всем складам
- Обычные пользователи видят только статистику своего склада

---

## 9. Экспорт продаж

### Экспортировать данные о продажах

**Endpoint:** `GET /api/sales/export`

**Описание:** Экспортирует все продажи с фильтрацией в формате JSON для дальнейшей обработки (Excel, CSV и т.д.).

**Query параметры:**

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `search` | string | Нет | Поиск по номеру, имени клиента, телефону |
| `warehouse_id` | integer | Нет | Фильтр по складу |
| `payment_status` | string | Нет | Фильтр по статусу оплаты |
| `payment_method` | string | Нет | Фильтр по методу оплаты |
| `date_from` | date | Нет | Начальная дата |
| `date_to` | date | Нет | Конечная дата |
| `active` | boolean | Нет | Только активные продажи |

**Пример запроса:**
```bash
curl -X GET "http://93.189.230.65/api/sales/export?payment_status=paid&date_from=2025-10-01" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

**Пример ответа (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 102,
      "sale_number": "SALE-202510-0002",
      "customer_name": "Тестовый Клиент ООО",
      "customer_phone": "+998901234567",
      "customer_email": "test@example.com",
      "product_name": "Пиломатериалы: 3 x 33 x 3",
      "warehouse": "Компания 1 Склад 2",
      "quantity": 5,
      "unit_price": "150000.00",
      "total_price": "862500.00",
      "payment_status": "paid",
      "payment_method": "bank_transfer",
      "sale_date": "2025-10-12T00:00:00.000000Z",
      "created_by": "Администратор",
      "created_at": "2025-10-12 20:39:18"
    },
    {
      "id": 103,
      "sale_number": "SALE-202510-0003",
      "customer_name": "ООО Строй-Сервис",
      "customer_phone": "+998901234567",
      "customer_email": "info@stroy-service.uz",
      "product_name": "Пиломатериалы: 3 x 33 x 3",
      "warehouse": "Компания 1 Склад 2",
      "quantity": 10,
      "unit_price": "200000.00",
      "total_price": "2300000.00",
      "payment_status": "paid",
      "payment_method": "bank_transfer",
      "sale_date": "2025-10-12T00:00:00.000000Z",
      "created_by": "Администратор",
      "created_at": "2025-10-12 21:00:00"
    }
  ],
  "total": 2
}
```

**Формат данных для экспорта:**

Каждая запись содержит:
- `id` - ID продажи
- `sale_number` - Номер продажи
- `customer_name` - Имя клиента
- `customer_phone` - Телефон клиента
- `customer_email` - Email клиента
- `product_name` - Название товара
- `warehouse` - Название склада
- `quantity` - Количество
- `unit_price` - Цена за единицу
- `total_price` - Общая сумма
- `payment_status` - Статус оплаты
- `payment_method` - Метод оплаты
- `sale_date` - Дата продажи
- `created_by` - Кто создал
- `created_at` - Дата создания

**Использование:**
Данные можно конвертировать в Excel, CSV или другие форматы для дальнейшей обработки.

---

## Коды ответов и ошибки

### HTTP коды ответов

| Код | Описание |
|-----|----------|
| `200 OK` | Успешный запрос |
| `201 Created` | Ресурс успешно создан |
| `400 Bad Request` | Некорректный запрос (например, недостаточно товара) |
| `401 Unauthorized` | Требуется аутентификация |
| `403 Forbidden` | Доступ запрещен |
| `404 Not Found` | Ресурс не найден |
| `409 Conflict` | Конфликт (например, дубликат номера продажи) |
| `422 Unprocessable Entity` | Ошибки валидации |
| `500 Internal Server Error` | Внутренняя ошибка сервера |

### Формат ошибок

**Ошибка валидации (422):**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "product_id": ["The product id field is required."],
    "quantity": ["The quantity must be at least 1."],
    "unit_price": ["The unit price must be a number."]
  }
}
```

**Ошибка доступа (403):**
```json
{
  "message": "Доступ к складу запрещен"
}
```

**Ошибка недостатка товара (400):**
```json
{
  "message": "Недостаточно товара на складе"
}
```

**Ошибка не найдено (404):**
```json
{
  "message": "Продажа не найдена"
}
```

---

## Справочники

### Статусы оплаты (payment_status)

| Значение | Описание |
|----------|----------|
| `pending` | Ожидает оплаты |
| `paid` | Оплачено |
| `partially_paid` | Частично оплачено |
| `cancelled` | Отменено |

### Методы оплаты (payment_method)

| Значение | Описание |
|----------|----------|
| `cash` | Наличные |
| `card` | Банковская карта |
| `bank_transfer` | Банковский перевод |
| `other` | Другое |

### Поддерживаемые валюты

- `RUB` - Российский рубль (по умолчанию)
- `UZS` - Узбекский сум
- `USD` - Доллар США
- `EUR` - Евро
- Другие 3-буквенные коды валют по стандарту ISO 4217

---

## Примеры использования

### Пример 1: Создание простой продажи

```bash
curl -X POST "http://93.189.230.65/api/sales" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 389,
    "warehouse_id": 13,
    "customer_name": "Иванов Иван Иванович",
    "customer_phone": "+79161234567",
    "quantity": 5,
    "unit_price": 1500,
    "payment_method": "cash",
    "sale_date": "2025-10-12"
  }'
```

### Пример 2: Поиск продаж клиента

```bash
curl -X GET "http://93.189.230.65/api/sales?search=Иванов" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Пример 3: Получение оплаченных продаж за месяц

```bash
curl -X GET "http://93.189.230.65/api/sales?payment_status=paid&date_from=2025-10-01&date_to=2025-10-31" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Пример 4: Обработка продажи

```bash
# 1. Создать продажу
SALE_ID=$(curl -X POST "http://93.189.230.65/api/sales" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "product_id": 389, "warehouse_id": 13, ... }' | jq -r '.sale.id')

# 2. Обработать продажу
curl -X POST "http://93.189.230.65/api/sales/$SALE_ID/process" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Пример 5: Экспорт продаж за период

```bash
curl -X GET "http://93.189.230.65/api/sales/export?date_from=2025-10-01&date_to=2025-10-31" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  > sales_export.json
```

---

## Права доступа

### Администраторы
- ✅ Полный доступ ко всем продажам всех складов
- ✅ Создание, просмотр, обновление, удаление любых продаж
- ✅ Обработка и отмена любых продаж
- ✅ Статистика по всем складам

### Обычные пользователи
- ✅ Доступ только к продажам своего склада
- ✅ Создание продаж только на своем складе
- ✅ Просмотр и обновление продаж своего склада
- ❌ Удаление продаж других компаний
- ✅ Статистика только своего склада

---

## Логика работы с остатками

### При создании продажи:
1. Создается запись о продаже со статусом `pending`
2. Товар **НЕ списывается** со склада автоматически
3. Остатки товара остаются неизменными

### При обработке продажи (process):
1. Проверяется наличие достаточного количества товара
2. Увеличивается `sold_quantity` товара
3. Доступное количество = `quantity` - `sold_quantity`
4. Статус меняется на `paid`

### При отмене продажи (cancel):
1. Уменьшается `sold_quantity` товара
2. Товар возвращается в доступные остатки
3. Статус меняется на `cancelled`

### Расчет доступного количества:
```
available_quantity = quantity - sold_quantity
```

Где:
- `quantity` - общее количество товара на складе
- `sold_quantity` - количество проданного товара
- `available_quantity` - доступно для продажи

---

## Лучшие практики

### 1. Проверка остатков перед продажей
```bash
# Проверить остатки товара
curl -X GET "http://93.189.230.65/api/products/389" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Убедиться, что available_quantity >= quantity для продажи
```

### 2. Использование пагинации
```bash
# Запрашивайте данные порциями для больших списков
curl -X GET "http://93.189.230.65/api/sales?per_page=50&page=1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Фильтрация по датам
```bash
# Используйте фильтры для оптимизации запросов
curl -X GET "http://93.189.230.65/api/sales?date_from=2025-10-01&payment_status=paid" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. Обработка ошибок
```javascript
try {
  const response = await fetch('http://93.189.230.65/api/sales', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(saleData)
  });
  
  if (!response.ok) {
    const error = await response.json();
    if (response.status === 400) {
      console.error('Недостаточно товара:', error.message);
    } else if (response.status === 422) {
      console.error('Ошибки валидации:', error.errors);
    }
  }
} catch (error) {
  console.error('Ошибка сети:', error);
}
```

### 5. Автоматический расчет сумм
Не нужно вручную рассчитывать `price_without_vat`, `vat_amount` и `total_price` - они вычисляются автоматически на основе `quantity`, `unit_price` и `vat_rate`.

---

## Changelog

### Версия 1.0 (октябрь 2025)
- ✅ Базовый CRUD для продаж
- ✅ Автоматический расчет НДС
- ✅ Обработка и отмена продаж
- ✅ Статистика продаж
- ✅ Экспорт данных
- ✅ Фильтрация и поиск
- ✅ Пагинация
- ✅ Права доступа по складам

---

## Поддержка

По вопросам работы API обращайтесь к документации проекта или администратору системы.

**Дата создания документации:** 12 октября 2025

