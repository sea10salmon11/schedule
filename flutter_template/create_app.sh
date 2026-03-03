#!/bin/bash
# =============================================================================
# Flutter Android App Creator
# Версии проверены и работают вместе (февраль 2025)
# Использование: ./create_app.sh <имя_приложения> [com.yourcompany.appname]
# Пример:        ./create_app.sh myapp com.example.myapp
# =============================================================================

set -e

APP_NAME="${1}"
PACKAGE="${2:-com.example.${APP_NAME}}"

if [ -z "$APP_NAME" ]; then
    echo "Использование: $0 <имя_приложения> [package.name]"
    echo "Пример: $0 myapp com.mycompany.myapp"
    exit 1
fi

echo ">>> Создаём Flutter приложение: $APP_NAME ($PACKAGE)"

# 1. Создать базовый проект
flutter create --org "${PACKAGE%.*}" --project-name "$APP_NAME" "$APP_NAME"
cd "$APP_NAME"

# =============================================================================
# 2. android/gradle/wrapper/gradle-wrapper.properties
#    Gradle 8.7 — проверенная версия
# =============================================================================
cat > android/gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip
EOF

# =============================================================================
# 3. android/settings.gradle
#    AGP 8.5.2 + Kotlin 2.1.0 — проверенные версии
# =============================================================================
cat > android/settings.gradle << 'EOF'
pluginManagement {
    def localProperties = new Properties()
    def localPropertiesFile = new File(rootDir, 'local.properties')
    if (localPropertiesFile.exists()) {
        localPropertiesFile.withInputStream { stream -> localProperties.load(stream) }
    }

    def flutterSdkPath = localProperties.getProperty('flutter.sdk')
    if (flutterSdkPath == null) {
        flutterSdkPath = System.env.FLUTTER_ROOT
    }
    assert flutterSdkPath != null, "flutter.sdk not set in local.properties and FLUTTER_ROOT not set."

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.5.2" apply false
    id "org.jetbrains.kotlin.android" version "2.1.0" apply false
}

include ":app"
EOF

# =============================================================================
# 4. android/app/build.gradle
#    Java 1.8 target + coreLibraryDesugaring (нужно для flutter_local_notifications и др.)
# =============================================================================
cat > android/app/build.gradle << EOF
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "$PACKAGE"
    compileSdk flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId "$PACKAGE"
        minSdk flutter.minSdkVersion
        targetSdk flutter.targetSdkVersion
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source "../.."
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}
EOF

# =============================================================================
# 5. android/gradle.properties
# =============================================================================
cat > android/gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
EOF

# =============================================================================
# 6. android/build.gradle
# =============================================================================
cat > android/build.gradle << 'EOF'
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = "../build"
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
EOF

# =============================================================================
# 7. pubspec.yaml — минимальный рабочий
# =============================================================================
cat > pubspec.yaml << EOF
name: $APP_NAME
description: Flutter Application
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

flutter:
  uses-material-design: true
EOF

# =============================================================================
# 8. GitHub Actions CI
#    Flutter 3.24.0 + JDK 17 — проверенные версии
# =============================================================================
mkdir -p .github/workflows
cat > .github/workflows/main.yml << EOF
name: Android CI

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'

    - name: Set up Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        channel: 'stable'

    - name: Install dependencies
      run: flutter pub get

    - name: Build APK
      run: flutter build apk --release

    - name: Upload APK
      uses: actions/upload-artifact@v4
      with:
        name: ${APP_NAME}-release
        path: build/app/outputs/flutter-apk/app-release.apk
        retention-days: 30
EOF

# =============================================================================
# 9. Минимальный main.dart — чистый стартовый экран
# =============================================================================
cat > lib/main.dart << EOF
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$APP_NAME',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$APP_NAME'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text('Привет! Добавь свои экраны сюда.'),
      ),
    );
  }
}
EOF

# =============================================================================
# 10. Инициализировать git
# =============================================================================
git init
git add .
git commit -m "Initial Flutter app setup with proven version config"

echo ""
echo "============================================="
echo "ГОТОВО! Приложение '$APP_NAME' создано."
echo "============================================="
echo ""
echo "Следующие шаги:"
echo "  cd $APP_NAME"
echo "  flutter pub get"
echo "  flutter run          # запуск на телефоне/эмуляторе"
echo "  flutter build apk --release  # сборка APK"
echo ""
echo "Версии конфигурации:"
echo "  Flutter:  3.24.0 (stable)"
echo "  JDK:      17 (Temurin)"
echo "  Gradle:   8.7"
echo "  AGP:      8.5.2"
echo "  Kotlin:   2.1.0"
echo "============================================="
