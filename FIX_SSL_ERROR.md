# Решение проблемы SSL ошибки при загрузке в App Store

## Проблема
Ошибка: "There was a network error: An SSL error has occurred"

## Решения:

### Вариант 1: Используйте Transporter App
1. Откройте Transporter (в Applications или скачайте из App Store)
2. Войдите с Apple ID
3. Перетащите .ipa файл в окно Transporter
4. Нажмите "Deliver"

### Вариант 2: Через командную строку
```bash
# Установите altool если еще не установлен
xcode-select --install

# Загрузите через altool
xcrun altool --upload-app \
  --type ios \
  --file путь/к/вашему/app.ipa \
  --apiKey KEY_ID \
  --apiIssuer ISSUER_ID \
```

### Вариант 3: Проверьте настройки SSL в Xcode
1. Xcode → Preferences → Accounts
2. Выберите ваш Apple ID
3. Внизу нажмите "Manage Certificates"
4. Убедитесь что сертификаты актуальны
5. Попробуйте удалить и добавить аккаунт снова

### Вариант 4: Отключите VPN/Proxy
Если используете VPN или прокси - отключите временно

### Вариант 5: Создайте новый API ключ
1. https://appstoreconnect.apple.com/access/api
2. Keys → Generate API Key
3. Используйте его в Variant 2

### Вариант 6: Через Xcode другим способом
1. Product → Archive (если еще не сделано)
2. Window → Organizer
3. Выберите архив
4. Distribute App → Export
5. Выберите "App Store Connect"
6. Сохраните .ipa
7. Откройте Transporter и загрузите

## РЕКОМЕНДУЕМЫЙ СПОСОБ
Используйте **Transporter App** - это самый надежный способ!
