# 🚀 Быстрый старт: Архивирование компании

## 1️⃣ Запуск приложения (30 секунд)

```bash
cd /Users/ruslansiraev/sum_mobile
flutter pub get
flutter run
```

## 2️⃣ Авторизация

Используйте токен:
```
10|JjDIZTEyAcIGRqXUbXlAook1oHMtQkPbSPxHV0dTe657fb6d
```

## 3️⃣ Архивирование компании (3 клика)

1. Раздел "Компания"
2. Выбрать компанию
3. Нажать **"Архивировать"** (оранжевая кнопка)
4. Подтвердить в диалоге

## 4️⃣ Просмотр архивированных

1. На списке включить **"Показать архивированные"**
2. Компании с меткой "Архив" — это архивированные

## 5️⃣ Восстановление компании

1. Включить фильтр архивированных
2. Выбрать компанию
3. Нажать **"Восстановить"** (зелёная кнопка)
4. Подтвердить

## 🔍 Просмотр логов

```bash
flutter logs | grep -i archive
```

Ищите:
```
PUT /companies/1/archive - Status 200
```

## 📝 Что изменилось

✅ 5 файлов обновлено  
✅ Нет ошибок  
✅ Готово к использованию  

## 📚 Подробнее

- **Реализация:** `ARCHIVE_COMPANY_IMPLEMENTATION.md`
- **Тестирование:** `TESTING_GUIDE.md`
- **Отладка:** `LOGS_DEBUGGING.md`

## ⚡ Команды

| Команда | Что делает |
|---------|-----------|
| `flutter run` | Запустить приложение |
| `flutter logs` | Показать логи |
| `flutter analyze` | Проверить ошибки |
| `flutter clean` | Очистить кеш |
| `dart format .` | Форматировать код |

## 🎯 Тестовые URL

```bash
# Архивировать компанию 1
curl -X PUT "https://api.example.com/api/companies/1/archive" \
  -H "Authorization: Bearer 10|JjDIZTEyAcIGRqXUbXlAook1oHMtQkPbSPxHV0dTe657fb6d"

# Восстановить компанию 1
curl -X PUT "https://api.example.com/api/companies/1/restore" \
  -H "Authorization: Bearer 10|JjDIZTEyAcIGRqXUbXlAook1oHMtQkPbSPxHV0dTe657fb6d"

# Показать архивированные
curl -X GET "https://api.example.com/api/companies?showArchived=true" \
  -H "Authorization: Bearer 10|JjDIZTEyAcIGRqXUbXlAook1oHMtQkPbSPxHV0dTe657fb6d"
```

## ✅ Успешно, если:

- ✅ Приложение запускается
- ✅ Компании загружаются
- ✅ Кнопка "Архивировать" есть
- ✅ Архивирование работает
- ✅ Нет ошибок в консоли

**Готово! 🎉**

