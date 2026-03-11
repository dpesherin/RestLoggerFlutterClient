# LoggerFlutterClient

Приложение для просмотра и фильтрации логов в реальном времени. Поддерживает подключение к серверу логирования через WebSocket.

## Особенности

- 🕐 Просмотр логов в реальном времени
- 🔍 Фильтрация по уровню, тегам и содержимому
- 💾 Сохранение сессий и истории
- 🎨 Темная и светлая тема
- 🔐 Безопасное подключение (SSL/TLS)
- 🖥️ Кроссплатформа (macOS, Windows)

## Требования

- Flutter 3.0+
- Dart 3.0+
- macOS 10.11+ или Windows 10+

## Установка и сборка

### macOS

```bash
flutter pub get
flutter run -d macos
```

Сборка release:
```bash
flutter build macos --release
hdiutil create -volname "LoggerFlutterClient" -srcfolder "build/macos/Build/Products/Release/LoggerFlutterClient.app" -ov -format UDZO "build/LoggerFlutterClient.dmg"
```

### Windows

```bash
flutter pub get
flutter run -d windows
```

Сборка release:
```bash
flutter build windows --release
```

## Структура проекта

```
lib/
├── main.dart                    # Точка входа
├── app.dart                     # Конфигурация приложения
├── screens/                     # Экраны
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   └── main_screen.dart
├── providers/                   # State management
│   └── session_provider.dart
├── services/                    # Бизнес логика
│   ├── api_service.dart
│   ├── websocket_service.dart
│   ├── socket_wrapper.dart
│   └── storage_service.dart
├── models/                      # Модели данных
│   ├── user.dart
│   ├── message.dart
│   └── session_model.dart
├── widgets/                     # Переиспользуемые компоненты
│   ├── message_card.dart
│   ├── fullscreen_view.dart
│   └── ...
└── utils/                       # Утилиты
    ├── logger.dart
    ├── constants.dart
    ├── error_handler.dart
    ├── theme.dart
    └── ...
```

## Зависимости

### Core
- `flutter` - фреймворк
- `provider` - управление состоянием
- `http` - HTTP запросы
- `socket_io_client` - WebSocket подключение

### UI
- `google_fonts` - шрифты
- `font_awesome_flutter` - иконки
- `animations` - анимации
- `flutter_highlight` - подсветка синтаксиса

### Storage
- `shared_preferences` - локальное хранилище
- `path_provider` - доступ к файловой системе

### Утилиты
- `intl` - локализация и форматирование
- `url_launcher` - открытие ссылок
- `clipboard` - работа с буфером обмена
- `window_manager` - управление окном (macOS/Windows)
- `json_annotation` - сериализация JSON

## Конфигурация

### Переменные окружения

```bash
# Production сервер
UPDATE_SERVER_URL=https://updates.example.com
API_SERVER_URL=https://api.example.com
WEBSOCKET_URL=wss://ws.example.com
```

### Сертификат SSL

Сертификат включен в `assets/certificates/isrgrootx1.pem` для HTTPS подключений.

## Использование

### Запуск в dev режиме

```bash
flutter run -d macos          # macOS
flutter run -d windows        # Windows
```

### Запуск в debug режиме с логами

```bash
flutter run -d macos --verbose
```

### Очистка и переборка

```bash
flutter clean
flutter pub get
flutter run -d macos
```

## Сборка релиза

### macOS DMG

```bash
./build_release.sh 1.0.5
```

### Windows EXE

```bash
flutter build windows --release
```

## Обновления приложения

Приложение поддерживает автоматическое обновление через Update Server.

Смотрите [UPDATE_SYSTEM.md](UPDATE_SYSTEM.md) для полной информации о системе обновлений.

## Разработка

### Логирование

```dart
import 'utils/logger.dart';

logger.info('Information message');
logger.debug('Debug message');
logger.warning('Warning message');
logger.error('Error message', exception, stackTrace);
```

### Состояние (Provider)

Приложение использует `Provider` для управления состоянием:
- `SessionProvider` - текущая сессия пользователя
- `ThemeProvider` - тема приложения

### API запросы

```dart
final apiService = ApiService(baseUrl: 'https://api.example.com');
final response = await apiService.request('/endpoint');
```

### WebSocket подключение

```dart
final socketService = SocketService(url: 'wss://ws.example.com');
await socketService.connect();
socketService.on('message', (data) {
  // Обработка сообщения
});
```

## Troubleshooting

### Ошибка "Unable to find git"

```bash
which git
xcode-select --install
```

### Ошибка сборки macOS

```bash
flutter clean
rm -rf macos/Pods
flutter pub get
flutter run -d macos
```

### Проблемы с сертификатом SSL

Проверьте наличие файла `assets/certificates/isrgrootx1.pem` и убедитесь, что он добавлен в `pubspec.yaml`.

## Лицензия

MIT License - смотрите [LICENSE.txt](LICENSE.txt)

## Контакты

Для вопросов и предложений создавайте Issues в репозитории.

