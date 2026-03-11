# Инструкция по сборке Logger Flutter Client для Windows

Полное руководство по установке всех компонентов, подготовке окружения и сборке приложения для Windows с нуля.

## Содержание

- [Требования к системе](#требования-к-системе)
- [Установка компонентов](#установка-компонентов)
- [Подготовка проекта](#подготовка-проекта)
- [Процесс сборки](#процесс-сборки)
- [Создание инсталлера](#создание-инсталлера)
- [Использование build_all.bat](#использование-build_allbat)
- [Трубулшутинг](#трубулшутинг)

## Требования к системе

### Минимальные требования

- **ОС**: Windows 10 или выше (x64)
- **Место на диске**: 5-10 GB свободного места для всех компонентов
- **RAM**: 8 GB минимум
- **Интернет**: Стабильное подключение для загрузки компонентов

### Рекомендуемые требования

- **ОС**: Windows 11 (x64)
- **Место на диске**: 15 GB свободного места
- **RAM**: 16 GB
- **Сборка**: SSD для более быстрой сборки

## Установка компонентов

### Шаг 1: Установка Git

1. Перейдите на [git-scm.com](https://git-scm.com/download/win)
2. Загрузите инсталлер для Windows (x64)
3. Запустите инсталлер и используйте настройки по умолчанию
4. После установки проверьте в PowerShell:
   ```powershell
   git --version
   ```

### Шаг 2: Установка Visual Studio Build Tools

Требуется для компиляции C++ части приложения.

1. Перейдите на [visualstudio.microsoft.com](https://visualstudio.microsoft.com/downloads/)
2. Найдите "Visual Studio Build Tools" и скачайте
3. Запустите инсталлер
4. Выберите: **Desktop development with C++**
5. Установите компоненты:
   - MSVC v143 или новее
   - Windows 10/11 SDK
   - CMake tools for Windows

Или установите Visual Studio Community (более удобно):

1. Скачайте [Visual Studio Community](https://visualstudio.microsoft.com/vs/community/)
2. При установке выберите **Desktop development with C++**
3. Убедитесь, что установлены необходимые компоненты

### Шаг 3: Установка Flutter SDK

1. Перейдите на [flutter.dev/docs/get-started/install/windows](https://flutter.dev/docs/get-started/install/windows)

2. Скачайте последнюю версию Flutter SDK:
   ```powershell
   # Или скачайте вручную и распакуйте в C:\flutter
   ```

3. Распакуйте архив в `C:\flutter` (или в другую папку без пробелов)

4. Добавьте Flutter в переменную окружения `PATH`:
   - Откройте "Переменные окружения" (Environment Variables)
   - Добавьте `C:\flutter\bin` в PATH
   - Перезагрузитесь

5. Проверьте установку в PowerShell:
   ```powershell
   flutter --version
   dart --version
   ```

### Шаг 4: Установка Inno Setup (для создания инсталлера)

1. Перейдите на [jrsoftware.org/isdl.php](https://jrsoftware.org/isdl.php)
2. Скачайте Inno Setup 6.x
3. Запустите инсталлер и установите в `C:\Program Files (x86)\Inno Setup 6`
4. Проверьте, что путь совпадает с путем в `build_all.bat`:
   ```batch
   set INNO_PATH="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
   ```

### Шаг 5: Проверка установки Flutter

```powershell
flutter doctor
```

Убедитесь, что нет критических ошибок:

```
[✓] Flutter (Channel stable, X.X.X)
[✓] Windows Version (Windows 10/11)
[✓] Visual Studio - develop for Windows
[✓] Android toolchain
[✓] Chrome - develop for the web
[!] Android Studio
[✓] VS Code
[✓] Connected device (Windows)
```

## Подготовка проекта

### Шаг 1: Клонирование репозитория

```powershell
# Откройте PowerShell как администратор
cd C:\

# Клонируйте репозиторий
git clone https://github.com/yourusername/logger_flutter.git
cd logger_flutter
```

### Шаг 2: Установка зависимостей

```powershell
# Загрузите зависимости
flutter pub get

# Получите коды ошибок (опционально)
flutter pub global activate intl_utils
```

### Шаг 3: Конфигурация окружения

1. Создайте файл `.env` в корне проекта (если его нет):

```bash
cp .env.example .env
```

2. Отредактируйте `.env` с вашими параметрами:

```env
API_BASE_URL=https://your-api-server.com
WS_URL=wss://your-websocket-server.com
DOCS_URL=https://your-docs.com
APP_ENVIRONMENT=production
```

**Важно**: Убедитесь, что используются HTTPS и WSS для production среды.

### Шаг 4: Проверка конфигурации

```powershell
# Проверьте что все зависимости установлены
flutter pub get

# Проверьте анализ кода
flutter analyze
```

## Процесс сборки

### Debug сборка (Для разработки)

Используется для тестирования на локальной машине:

```powershell
# Очистите предыдущую сборку
flutter clean

# Установите зависимости
flutter pub get

# Запустите в debug режиме
flutter run -d windows

# Или только создайте сборку
flutter build windows
```

Результат: `build/windows/x64/runner/Debug/logger_flutter.exe`

### Release сборка (Для распространения)

Оптимизированная версия без debug информации:

```powershell
# Очистите предыдущую сборку
flutter clean

# Установите зависимости
flutter pub get

# Создайте release сборку
flutter build windows --release
```

Результат: `build/windows/x64/runner/Release/logger_flutter.exe`

### Release сборка с verbose выводом

Для отладки проблем при сборке:

```powershell
flutter build windows --release --verbose
```

## Создание инсталлера

### Вручную (Рекомендуется для начала)

1. Убедитесь, что Release сборка завершена:
```powershell
flutter build windows --release
```

2. Откройте Inno Setup
3. Выберите **File > Open**
4. Откройте файл `installer.iss`
5. Нажмите **Build > Compile** (или Ctrl+F9)
6. Инсталлер будет создан в папке `installer/`

### Автоматически через build_all.bat

Скрипт автоматически выполняет все шаги.

## Использование build_all.bat

### Что делает build_all.bat

Скрипт `build_all.bat` автоматизирует создание инсталлера:

```batch
@echo off

set INNO_PATH="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist %INNO_PATH% (
    echo Creating installer...
    %INNO_PATH% installer.iss
    echo Installer created in installer\ folder
) else (
    echo Inno Setup not found at %INNO_PATH%
    echo Please check your installation path
)

echo Build complete!
pause
```

**Важно**: Скрипт предполагает, что Release сборка уже создана!

### Запуск build_all.bat

1. **Откройте PowerShell** в папке проекта:
   ```powershell
   cd C:\path\to\logger_flutter
   ```

2. **Убедитесь, что Release сборка готова**:
   ```powershell
   flutter build windows --release
   ```

3. **Запустите скрипт**:
   ```powershell
   .\build_all.bat
   ```

   Или **двойной клик** на `build_all.bat` в проводнике

4. **Ждите завершения**. Скрипт создаст инсталлер в папке `installer/`

5. **Результат**: `installer/Logger_Flutter_Client_Setup.exe`

### Если Inno Setup не найден

Ошибка:
```
Inno Setup not found at C:\Program Files (x86)\Inno Setup 6\ISCC.exe
Please check your installation path
```

**Решение**: Отредактируйте `build_all.bat`:

```batch
# Проверьте где установлен Inno Setup
dir "C:\Program Files*" /s /b | find "ISCC.exe"

# Обновите путь в build_all.bat:
set INNO_PATH="C:\ваш\правильный\путь\ISCC.exe"
```

## Полный цикл сборки

Для полной сборки с нуля выполните:

```powershell
# 1. Очистите проект
flutter clean

# 2. Загрузите зависимости
flutter pub get

# 3. Проверьте код
flutter analyze

# 4. Создайте Release сборку
flutter build windows --release

# 5. Создайте инсталлер
.\build_all.bat

# Инсталлер готов: installer/Logger_Flutter_Client_Setup.exe
```

**Время выполнения**: ~10-20 минут в зависимости от машины

## Структура сборки

После успешной сборки получите:

```
build/
├── windows/
│   └── x64/
│       └── runner/
│           ├── Debug/
│           │   ├── logger_flutter.exe      (Debug версия)
│           │   └── (зависимости)
│           └── Release/
│               ├── logger_flutter.exe      (Release версия)
│               └── (зависимости)

installer/
└── Logger_Flutter_Client_Setup.exe         (Инсталлер)
```

## Конфигурация инсталлера

Инсталлер настраивается в файле `installer.iss`:

```ini
[Setup]
AppName=Logger Flutter Client          # Имя приложения
AppVersion=1.0.0                       # Версия
DefaultDirName={autopf}\LoggerFlutterClient  # Директория установки
OutputDir=installer                   # Папка для инсталлера
OutputBaseFilename=Logger_Flutter_Client_Setup  # Имя файла
```

### Изменение версии

Обновите версию в трех местах:

1. **pubspec.yaml**:
   ```yaml
   version: "1.1.0+2"
   ```

2. **installer.iss**:
   ```ini
   AppVersion=1.1.0
   ```

3. **Пересоберите**:
   ```powershell
   flutter build windows --release
   ```

## Трубулшутинг

### Ошибка: "Flutter not recognized"

**Проблема**: Flutter не в переменной PATH

**Решение**:
1. Откройте "Переменные окружения"
2. Добавьте `C:\flutter\bin` в PATH
3. Перезагрузитесь

Проверка:
```powershell
flutter --version
```

### Ошибка: "Visual Studio Build Tools not found"

**Проблема**: Не установлены инструменты C++

**Решение**:
1. Установите Visual Studio Build Tools
2. Выберите "Desktop development with C++"
3. Установите компоненты для C++

### Ошибка: "Gradle daemon not available"

**Решение** (если происходит):
```powershell
flutter clean
flutter pub get
flutter build windows --release
```

### Ошибка при сборке: "certificate_verify_failed"

**Проблема**: Проблемы с SSL сертификатами

**Решение**:
1. Проверьте файл `.env` - убедитесь что используется правильный URL
2. Проверьте файл `assets/certificates/isrgrootx1.pem`
3. Переоборите:
```powershell
flutter clean
flutter pub get
flutter build windows --release
```

### Ошибка: "Inno Setup setup wizard not found"

**Проблема**: Неправильный путь к Inno Setup

**Решение**:
1. Проверьте путь установки:
   ```powershell
   dir "C:\Program Files (x86)" | find "Inno"
   ```

2. Обновите `build_all.bat`:
   ```batch
   set INNO_PATH="C:\ваш\путь\ISCC.exe"
   ```

### Инсталлер не создается

**Проблема**: Release сборка не завершена

**Решение**:
```powershell
# 1. Пересоберите
flutter build windows --release

# 2. Проверьте что exe существует
dir "build\windows\x64\runner\Release\logger_flutter.exe"

# 3. Запустите build_all.bat снова
.\build_all.bat
```

### Медленная сборка

**Оптимизация**:

1. **Отключите Microsoft Defender** для папки проекта:
   - Параметры > Приватность и безопасность > Исключения защитника Windows
   - Добавьте папку проекта

2. **Используйте SSD** для хранения проекта

3. **Увеличьте RAM** для Dart VM:
   ```powershell
   flutter build windows --release --dart-vm-flags="--old_gen_heap_size=2048"
   ```

## Распространение

### Готовый инсталлер

- **Файл**: `installer/Logger_Flutter_Client_Setup.exe`
- **Размер**: ~100-150 MB
- **Требования**: Windows 10+

### Интеграция в CI/CD

Пример GitHub Actions для автоматической сборки:

```yaml
name: Build Windows Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.0.0'
      - run: flutter pub get
      - run: flutter build windows --release
      - name: Create installer
        run: |
          C:\Program Files (x86)\Inno Setup 6\ISCC.exe installer.iss
      - uses: softprops/action-gh-release@v1
        with:
          files: installer/Logger_Flutter_Client_Setup.exe
```

## Полезные команды

```powershell
# Информация о системе
flutter doctor -v

# Доступные устройства
flutter devices

# Анализ кода
flutter analyze

# Форматирование кода
dart format lib/

# Тесты
flutter test

# Удалить все созданные файлы
flutter clean

# Очистить кэш pub
flutter pub cache clean
```

## Дополнительные ресурсы

- [Flutter для Windows](https://flutter.dev/docs/development/platform-integration/windows/building)
- [Inno Setup документация](https://jrsoftware.org/ishelp/index.php)
- [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/)
- [Git для Windows](https://git-scm.com/download/win)

## FAQ

**Q: Я изменил код, как быстро пересобрать?**

A: Используйте `flutter run -d windows` для dev версии, затем `flutter build windows --release` для release.

**Q: Где хранятся логи приложения?**

A: В папке `%APPDATA%\LoggerFlutterClient` (после установки через инсталлер)

**Q: Как подписать инсталлер?**

A: Используйте Microsoft Authenticode для подписи exe файлов перед распространением:

```powershell
# Требуется сертификат кода
signtool sign /f mycert.pfx /p password /t http://timestamp.server.com build\windows\x64\runner\Release\logger_flutter.exe
```

**Q: Сколько весит итоговое приложение?**

A: ~100-150 MB (зависит от версии Flutter и включенных зависимостей)

## Поддержка

При возникновении проблем:

1. Проверьте `flutter doctor -v`
2. Очистите проект: `flutter clean`
3. Переустановите зависимости: `flutter pub get`
4. Пересоберите: `flutter build windows --release --verbose`

Подробные ошибки будут в консоли с флагом `--verbose`.
