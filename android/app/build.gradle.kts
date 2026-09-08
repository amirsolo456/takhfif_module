import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

fun signingProperty(name: String, envName: String): String? =
    keystoreProperties.getProperty(name)?.takeIf { it.isNotBlank() }
        ?: System.getenv(envName)?.takeIf { it.isNotBlank() }

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.takhfif_module"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "30.0.15729638"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.takhfif_module"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyAliasValue = signingProperty("keyAlias", "KEY_ALIAS")
            val keyPasswordValue = signingProperty("keyPassword", "KEY_PASSWORD")
            val storePasswordValue = signingProperty("storePassword", "KEYSTORE_PASSWORD")
            val storeFileValue = signingProperty("storeFile", "KEYSTORE_FILE")

            require(!keyAliasValue.isNullOrBlank()) {
                "Missing release signing keyAlias. Configure android/key.properties or KEY_ALIAS."
            }
            require(!keyPasswordValue.isNullOrBlank()) {
                "Missing release signing keyPassword. Configure android/key.properties or KEY_PASSWORD."
            }
            require(!storePasswordValue.isNullOrBlank()) {
                "Missing release signing storePassword. Configure android/key.properties or KEYSTORE_PASSWORD."
            }
            require(!storeFileValue.isNullOrBlank()) {
                "Missing release signing storeFile. Configure android/key.properties or KEYSTORE_FILE."
            }

            keyAlias = keyAliasValue
            keyPassword = keyPasswordValue
            storePassword = storePasswordValue
            storeFile = file(storeFileValue)
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
