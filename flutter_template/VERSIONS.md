# Проверенные версии для Flutter Android разработки

> Эти версии работают вместе без конфликтов.
> Проверено: февраль 2025.

## Быстрый старт (новый проект за ~10 минут)

```bash
chmod +x create_app.sh
./create_app.sh myapp com.example.myapp
cd myapp
flutter pub get
flutter run
```

---

## Версии

| Компонент | Версия | Где задаётся |
|-----------|--------|--------------|
| **Flutter** | 3.24.0 (stable) | `.github/workflows/main.yml` → `flutter-version` |
| **JDK** | 17 (Temurin) | `.github/workflows/main.yml` → `java-version` |
| **Gradle** | 8.7 | `android/gradle/wrapper/gradle-wrapper.properties` |
| **AGP** (Android Gradle Plugin) | 8.5.2 | `android/settings.gradle` |
| **Kotlin** | 2.1.0 | `android/settings.gradle` |
| **Java compile target** | 1.8 | `android/app/build.gradle` → `sourceCompatibility` |
| **desugar_jdk_libs** | 2.0.4 | `android/app/build.gradle` → `dependencies` |
| **Dart SDK** | >=3.0.0 <4.0.0 | `pubspec.yaml` → `environment.sdk` |

---

## Критичные настройки

### android/app/build.gradle — обязательные секции
```groovy
compileOptions {
    coreLibraryDesugaringEnabled true   // ВАЖНО: нужно для многих плагинов
    sourceCompatibility JavaVersion.VERSION_1_8
    targetCompatibility JavaVersion.VERSION_1_8
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}
```

### android/settings.gradle — версии AGP и Kotlin
```groovy
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.5.2" apply false
    id "org.jetbrains.kotlin.android" version "2.1.0" apply false
}
```

---

## Популярные плагины (проверенные версии)

Добавлять в `pubspec.yaml` по необходимости:

```yaml
dependencies:
  shared_preferences: ^2.2.2        # локальное хранилище
  flutter_local_notifications: ^17.0.0  # уведомления (требует coreLibraryDesugaring!)
  http: ^1.2.0                      # HTTP запросы
  provider: ^6.1.2                  # управление состоянием
  go_router: ^14.0.0                # навигация
  sqflite: ^2.3.3                   # SQLite база данных
  path_provider: ^2.1.3             # пути к файлам
```

---

## Структура проекта

```
myapp/
├── lib/
│   └── main.dart              # точка входа
├── android/
│   ├── app/
│   │   └── build.gradle       # compileSdk, minSdk, зависимости
│   ├── gradle/wrapper/
│   │   └── gradle-wrapper.properties  # версия Gradle
│   ├── settings.gradle        # AGP + Kotlin версии
│   ├── build.gradle           # репозитории
│   └── gradle.properties      # JVM настройки
├── .github/workflows/
│   └── main.yml               # CI: Flutter + JDK версии
└── pubspec.yaml               # Dart SDK + зависимости
```

---

## Типичные ошибки и решения

| Ошибка | Причина | Решение |
|--------|---------|---------|
| `Could not find com.android.tools:desugar_jdk_libs` | Не включён coreLibraryDesugaring | Добавить в `build.gradle` |
| `Kotlin daemon JVM args` warning | Версии Kotlin/JDK конфликтуют | Использовать JDK 17 + Kotlin 2.1.0 |
| `Gradle sync failed` | Несовместимые версии Gradle/AGP | Gradle 8.7 + AGP 8.5.2 |
| `minSdk too low` для плагина | Плагин требует новый Android | Поднять `minSdk` в `build.gradle` |
| `flutter.sdk not set` | Не задан путь к Flutter SDK | Задаётся в `local.properties` локально или через `FLUTTER_ROOT` |
