#!/bin/bash

echo "🔥 Упрощенная сборка APK (без оптимизации)"

# Настройка окружения
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH="/usr/lib/jvm/java-11-openjdk/bin:$PATH:/home/ander/flutter/bin"
cd /home/ander/CascadeProjects/ceiling_calculator

# Очистка
flutter clean

# Установка зависимостей  
flutter pub get

# Сборка без сжатия и оптимизации
echo "🏗️ Сборка APK..."
flutter build apk --release --no-shrink --no-obfuscate

if [ $? -eq 0 ]; then
    echo "✅ APK успешно создан!"
    echo "📍 Путь: build/app/outputs/flutter-apk/app-release.apk"
    echo "📊 Размер: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)"
    
    # Проверяем файл
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        echo "✅ Файл существует и готов к установке"
        ls -la build/app/outputs/flutter-apk/app-release.apk
    else
        echo "❌ Файл не найден"
    fi
else
    echo "❌ Ошибка сборки"
    exit 1
fi
