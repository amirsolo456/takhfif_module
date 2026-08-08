@echo off
setlocal
echo ======================================================
echo Applying Android Build Optimizations...
echo ======================================================

:: Writing settings.gradle.kts
echo Creating settings.gradle.kts...
(
echo pluginManagement {
echo     val flutterSdkPath =
echo         run {
echo             val properties = java.util.Properties^(^)
echo             file^("local.properties"^).inputStream^(^).use { properties.load^(it^) }
echo             val flutterSdkPath = properties.getProperty^("flutter.sdk"^)
echo             require^(flutterSdkPath != null^) { "flutter.sdk not set in local.properties" }
echo             flutterSdkPath
echo         }
echo.
echo     includeBuild^("$flutterSdkPath/packages/flutter_tools/gradle"^)
echo.
echo     repositories {
echo         google^(^)
echo         mavenCentral^(^)
echo         gradlePluginPortal^(^)
echo         maven { url = uri^("https://storage.flutter-io.cn/download.flutter.io"^) }
echo         maven { url = uri^("https://maven.aliyun.com/repository/google"^) }
echo         maven { url = uri^("https://maven.aliyun.com/repository/public"^) }
echo     }
echo }
echo.
echo dependencyResolutionManagement {
echo     repositoriesMode.set^(RepositoriesMode.PREFER_SETTINGS^)
echo     repositories {
echo         google^(^)
echo         mavenCentral^(^)
echo         maven { url = uri^("https://storage.flutter-io.cn/download.flutter.io"^) }
echo         maven { url = uri^("https://maven.aliyun.com/repository/google"^) }
echo         maven { url = uri^("https://maven.aliyun.com/repository/public"^) }
echo     }
echo }
echo.
echo plugins {
echo     id^("dev.flutter.flutter-plugin-loader"^) version "1.0.0"
echo     id^("com.android.application"^) version "8.11.1" apply false
echo     id^("org.jetbrains.kotlin.android"^) version "2.2.20" apply false
echo }
echo.
echo include^(":app"^)
) > android\settings.gradle.kts

:: Writing gradle.properties
echo Creating gradle.properties...
(
echo org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
echo kotlin.daemon.jvmargs=-Xmx2g
echo android.useAndroidX=true
echo android.newDsl=false
echo android.builtInKotlin=false
) > android\gradle.properties

:: Writing build.gradle.kts
echo Creating build.gradle.kts...
(
echo buildscript {
echo     repositories {
echo         google^(^)
echo         mavenCentral^(^)
echo         maven { url = uri^("https://storage.flutter-io.cn/download.flutter.io"^) }
echo         maven { url = uri^("https://maven.aliyun.com/repository/public"^) }
echo     }
echo     dependencies {
echo         classpath^("com.android.tools.build:gradle:8.11.1"^)
echo         classpath^("org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20"^)
echo     }
echo }
echo.
echo allprojects {
echo     repositories {
echo         google^(^)
echo         mavenCentral^(^)
echo         maven { url = uri^("https://storage.flutter-io.cn/download.flutter.io"^) }
echo         maven { url = uri^("https://maven.aliyun.com/repository/public"^) }
echo     }
echo }
echo.
echo val newBuildDir: Directory =
echo     rootProject.layout.buildDirectory
echo         .dir^("../../build"^)
echo         .get^(^)
echo rootProject.layout.buildDirectory.value^(newBuildDir^)
echo.
echo subprojects {
echo     val newSubprojectBuildDir: Directory = newBuildDir.dir^(project.name^)
echo     project.layout.buildDirectory.value^(newSubprojectBuildDir^)
echo }
echo subprojects {
echo     project.evaluationDependsOn^(":app"^)
echo }
echo.
echo tasks.register^<Delete^>^("clean"^) {
echo     delete^(rootProject.layout.buildDirectory^)
echo }
) > android\build.gradle.kts

echo.
echo Settings applied successfully!
echo ------------------------------------------------------
echo Please run: flutter clean
pause
