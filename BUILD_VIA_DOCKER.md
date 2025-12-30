# 🐳 Сборка APK через Docker

Если локальная сборка не работает, можно использовать Docker.

## 📋 Требования
- Docker или Podman
- 约 2GB свободного места

## 🚀 Быстрая сборка

```bash
# Создаем Dockerfile
cat > Dockerfile << 'EOF'
FROM ubuntu:22.04

# Устанавливаем зависимости
RUN apt-get update && apt-get install -y \\
    curl \\
    git \\
    unzip \\
    openjdk-11-jdk \\
    python3

# Устанавливаем Flutter
RUN curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz | tar -xJ -C /opt/
ENV PATH="/opt/flutter/bin:$PATH"

# Копируем проект
WORKDIR /app
COPY . .

# Создаем keystore
RUN echo "password123" | keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass password123 -keypass password123 -dname "CN=Calculator, OU=Dev, O=Company, L=City, ST=State, C=RU"

# Создаем настройки
RUN echo "storePassword=password123" > android/key.properties
RUN echo "keyPassword=password123" >> android/key.properties  
RUN echo "keyAlias=upload" >> android/key.properties
RUN echo "storeFile=upload-keystore.jks" >> android/key.properties

# Собираем APK
RUN flutter pub get && flutter build apk --release

EOF

# Собираем и запускаем контейнер
docker build -t ceiling-calculator-builder .
docker run --rm -v "$(pwd)/build:/app/build" ceiling-calculator-builder
```

## 📦 Результат

APK файл будет в директории `build/app/outputs/flutter-apk/app-release.apk`

## 🔄 Альтернатива: GitHub Actions

Загрузите код на GitHub и включите Actions в файле `.github/workflows/build-apk.yml`

APK будет автоматически собираться при каждом коммите.
