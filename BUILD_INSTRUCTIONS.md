# Инструкции по сборке APK файла для Android

## 1. Установка Flutter SDK

### Способ 1: Через Snap (рекомендуется для Ubuntu)
```bash
sudo snap install flutter --classic
```

### Способ 2: Скачивание с официального сайта
1. Скачайте Flutter SDK с https://flutter.dev/docs/get-started/install/linux
2. Распакуйте архив:
```bash
cd ~/development
tar xf flutter_linux_3.16.0-stable.tar.xz
```
3. Добавьте в PATH:
```bash
export PATH="$PATH:~/development/flutter/bin"
echo 'export PATH="$PATH:~/development/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

## 2. Проверка установки
```bash
flutter doctor
```

Установите недостающие компоненты по рекомендациям flutter doctor.

## 3. Настройка Android SDK

### Установка через Android Studio
1. Скачайте и установите Android Studio
2. Установите Android SDK через SDK Manager
3. Создайте виртуальное устройство или подключите реальное устройство

### Установка через командную строку
```bash
sudo apt update
sudo apt install android-sdk
```

## 4. Настройка проекта для сборки

### 4.1. Создание keystore для подписи APK
```bash
cd /home/ander/CascadeProjects/ceiling_calculator
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 4.2. Настройка подписи в проекте
Создайте файл `android/key.properties`:
```properties
storePassword=your_password
keyPassword=your_key_password
keyAlias=upload
storeFile=/home/your_username/upload-keystore.jks
```

### 4.3. Обновите android/app/build.gradle
Добавьте конфигурацию подписи перед блоком android:

```gradle
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
keystoreProperties.load(new FileInputStream(keystorePropertiesFile))

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

## 5. Сборка APK

### 5.1. Установка зависимостей
```bash
cd /home/ander/CascadeProjects/ceiling_calculator
flutter pub get
```

### 5.2. Сборка release APK
```bash
flutter build apk --release
```

APK файл будет создан в: `build/app/outputs/flutter-apk/app-release.apk`

### 5.3. Сборка App Bundle (для Google Play)
```bash
flutter build appbundle --release
```

App Bundle будет создан в: `build/app/outputs/bundle/release/app-release.aab`

## 6. Установка APK на устройство

### Через USB:
```bash
flutter install
```

### Через ADB:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## 7. Решение常见 проблем

### Проблема: "Android licenses not accepted"
```bash
flutter doctor --android-licenses
```

### Проблема: "Unable to locate adb"
Добавьте Android SDK в PATH:
```bash
export PATH="$PATH:$ANDROID_HOME/platform-tools"
```

### Проблема: "Gradle build failed"
Очистите кэш:
```bash
flutter clean
flutter pub get
```

## 8. Альтернативный способ - GitHub Actions

Если нет возможности настроить локально, можно использовать GitHub Actions для автоматической сборки:

1. Создайте репозиторий на GitHub
2. Добавьте файл `.github/workflows/build.yml`
3. Настройте автоматическую сборку APK

## 9. Минимальные требования

- Android 5.0 (API level 21) и выше
- 2GB RAM
- 100MB свободного места

## 10. Тестирование

Перед установкой на устройство рекомендуется протестировать:
```bash
flutter test
```

## Готовые команды для быстрой сборки

После полной настройки:
```bash
cd /home/ander/CascadeProjects/ceiling_calculator
flutter clean
flutter pub get
flutter build apk --release
```

Готовый APK файл будет доступен по пути:
`build/app/outputs/flutter-apk/app-release.apk`
