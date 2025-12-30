#!/bin/bash

# Скрипт для быстрой сборки APK
# Убедитесь что Flutter SDK установлен в /home/ander/flutter

echo "🔧 Очистка кэша Gradle..."
rm -rf ~/.gradle/caches

echo "📱 Установка переменных окружения..."
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH="/usr/lib/jvm/java-11-openjdk/bin:$PATH:/home/ander/flutter/bin"

echo "📦 Установка зависимостей Flutter..."
cd /home/ander/CascadeProjects/ceiling_calculator
flutter pub get

echo "🏗️ Сборка APK..."
flutter build apk --release --no-shrink

if [ $? -eq 0 ]; then
    echo "✅ APK успешно собран!"
    echo "📍 Путь к файлу: build/app/outputs/flutter-apk/app-release.apk"
    echo "📲 Для установки на устройство:"
    echo "   adb install build/app/outputs/flutter-apk/app-release.apk"
else
    echo "❌ Ошибка сборки APK"
    exit 1
fi
