# Загрузка архива в App Store - Ручная инструкция

## Архив создан! ✅
Расположение: `build/ios/archive/Runner.xcarchive`

## Как загрузить в App Store Connect:

### Вариант 1: Через Xcode Organizer (РЕКОМЕНДУЕТСЯ)

1. Откройте Xcode
2. Window → Organizer (или Cmd+Shift+9)
3. Найдите архив "Runner" от сегодняшней даты
4. Нажмите "Distribute App"
5. Выберите "App Store Connect"
6. Выберите "Upload"
7. Дождитесь завершения загрузки

### Вариант 2: Через командную строку
```bash
# Экспортируйте IPA из архива
xcrun altool --validate-app \
  -f build/ios/archive/Runner.xcarchive \
  -t ios \
  -u ваш-email@example.com \
  -p app-specific-password
```

### После загрузки:
1. Откройте https://appstoreconnect.apple.com
2. Перейдите в "Мои приложения" → "Wood Warehouse"
3. Дождитесь обработки билда (10-30 минут)
4. Нажмите "+ Version"
5. Выберите загруженный билд
6. Заполните описание, скриншоты и т.д.
7. Отправьте на ревью

## Важно: Добавьте иконки через Xcode

В Xcode:
1. Откройте `ios/Runner.xcworkspace`
2. Выберите проект Runner
3. Откройте Assets.xcassets → AppIcon
4. Добавьте все необходимые иконки
5. Пересоберите архив

## Архив готов к загрузке!
