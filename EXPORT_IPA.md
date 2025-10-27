# Экспорт .ipa файла из архива

## Быстрое решение

### Шаг 1: Откройте Xcode Organizer
- Window → Organizer (Cmd+Shift+9)

### Шаг 2: Экспортируйте архив
1. Выберите архив "Runner" от сегодня
2. Нажмите "Distribute App"
3. Выберите **"Export"** (НЕ Upload!)
4. Выберите "App Store Connect"
5. Выберите команду разработки
6. Нажмите "Export"
7. Выберите место для сохранения
8. Сохраните .ipa файл

### Шаг 3: Используйте Transporter
1. Откройте приложение **Transporter** (найдите в Applications)
2. Войдите с Apple ID
3. Перетащите .ipa файл в окно Transporter
4. Нажмите "Deliver"
5. Дождитесь завершения загрузки

## Альтернатива через командную строку

```bash
# Проверьте что архив существует
ls -la build/ios/archive/Runner.xcarchive

# Экспортируйте в .ipa (выполните через Xcode UI)
```

## После загрузки через Transporter:
1. Дождитесь уведомления "Complete"
2. Откройте https://appstoreconnect.apple.com
3. Мои приложения → Wood Warehouse
4. Дождитесь обработки билда
