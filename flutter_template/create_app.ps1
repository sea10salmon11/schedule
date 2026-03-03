# =============================================================================
# Flutter Android App Creator (Windows PowerShell)
# Versii provereny i rabotayut vmeste (fevral' 2025)
# Ispol'zovanie: .\create_app.ps1 -AppName myapp -Package com.example.myapp
# Primer:        .\create_app.ps1 -AppName myapp -Package com.example.myapp
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$AppName,

    [string]$Package = "com.example.$AppName"
)

$ErrorActionPreference = "Stop"

Write-Host ">>> Sozdayom Flutter prilozhenie: $AppName ($Package)" -ForegroundColor Green

# 1. Sozdat' bazovyy proekt
$OrgParts = $Package.Split('.')
$Org = ($OrgParts[0..($OrgParts.Count-2)]) -join '.'
flutter create --org $Org --project-name $AppName $AppName
Set-Location $AppName

# =============================================================================
# 2. gradle-wrapper.properties -- Gradle 8.7
# =============================================================================
@'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip
'@ | Set-Content android\gradle\wrapper\gradle-wrapper.properties -Encoding UTF8

# =============================================================================
# 3. settings.gradle -- AGP 8.5.2 + Kotlin 2.1.0
# =============================================================================
@'
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
'@ | Set-Content android\settings.gradle -Encoding UTF8

# =============================================================================
# 4. android/app/build.gradle -- zamena __PACKAGE__ na real'noe imya
# =============================================================================
@'
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "__PACKAGE__"
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
        applicationId "__PACKAGE__"
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
'@.Replace('__PACKAGE__', $Package) | Set-Content android\app\build.gradle -Encoding UTF8

# =============================================================================
# 5. gradle.properties
# =============================================================================
@'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
'@ | Set-Content android\gradle.properties -Encoding UTF8

# =============================================================================
# 6. android/build.gradle
# =============================================================================
@'
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
'@ | Set-Content android\build.gradle -Encoding UTF8

# =============================================================================
# 7. pubspec.yaml -- zamena __APPNAME__
# =============================================================================
@'
name: __APPNAME__
description: Flutter Application
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

flutter:
  uses-material-design: true
'@.Replace('__APPNAME__', $AppName) | Set-Content pubspec.yaml -Encoding UTF8

# =============================================================================
# 8. GitHub Actions CI -- zamena __APPNAME__
# =============================================================================
New-Item -ItemType Directory -Force -Path .github\workflows | Out-Null
@'
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
        name: __APPNAME__-release
        path: build/app/outputs/flutter-apk/app-release.apk
        retention-days: 30
'@.Replace('__APPNAME__', $AppName) | Set-Content .github\workflows\main.yml -Encoding UTF8

# =============================================================================
# 9. lib/main.dart -- zamena __APPNAME__
# =============================================================================
@'
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '__APPNAME__',
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
        title: const Text('__APPNAME__'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text('Hello! Add your screens here.'),
      ),
    );
  }
}
'@.Replace('__APPNAME__', $AppName) | Set-Content lib\main.dart -Encoding UTF8

# =============================================================================
# 10. Git init
# =============================================================================
git init
git add .
git commit -m "Initial Flutter app setup with proven version config"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "DONE! App '$AppName' created." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  flutter pub get"
Write-Host "  flutter run                    # run on phone"
Write-Host "  flutter build apk --release    # build APK"
Write-Host ""
Write-Host "Config versions:" -ForegroundColor Cyan
Write-Host "  Flutter:  3.24.0 (stable)"
Write-Host "  JDK:      17 (Temurin)"
Write-Host "  Gradle:   8.7"
Write-Host "  AGP:      8.5.2"
Write-Host "  Kotlin:   2.1.0"
Write-Host "=============================================" -ForegroundColor Green
